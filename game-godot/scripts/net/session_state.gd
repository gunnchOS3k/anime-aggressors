extends RefCounted
class_name OnlineSessionState

## Private lobby / match session state machine (scaffold).
## States: idle → lobby → ready_check → syncing → in_match → spectating → ended

const _OnlineProtocol = preload("res://scripts/net/online_protocol.gd")

const ST_IDLE := "idle"
const ST_LOBBY := "lobby"
const ST_READY_CHECK := "ready_check"
const ST_SYNCING := "syncing"
const ST_IN_MATCH := "in_match"
const ST_SPECTATING := "spectating"
const ST_ENDED := "ended"

var state: String = ST_IDLE
var lobby_id: String = ""
var local_player_id: int = 0
var players: Array = []  # [{id, name, ready, fighter_id}]
var spectators: Array = []
var match_seed: int = 0
var stage_id: String = "skyline-arena"
var frame: int = 0
var last_confirmed_frame: int = -1
var desync_detected: bool = false
var alpha_claim: String = "NOT_PUBLIC_ONLINE — session scaffold only"


func reset() -> void:
	state = ST_IDLE
	lobby_id = ""
	players.clear()
	spectators.clear()
	match_seed = 0
	frame = 0
	last_confirmed_frame = -1
	desync_detected = false


func create_lobby(id: String, host_name: String) -> Dictionary:
	reset()
	lobby_id = id
	state = ST_LOBBY
	players.append({"id": 0, "name": host_name, "ready": false, "fighter_id": "ember-vale"})
	local_player_id = 0
	return _snapshot()


func join_lobby(id: String, guest_name: String) -> Dictionary:
	if state != ST_IDLE and state != ST_LOBBY:
		return {"ok": false, "error": "bad_state", "state": state}
	lobby_id = id
	state = ST_LOBBY
	var pid: int = players.size()
	players.append({"id": pid, "name": guest_name, "ready": false, "fighter_id": "rook-ironside"})
	local_player_id = pid
	return _snapshot()


func set_ready(player_id: int, ready: bool) -> Dictionary:
	if state != ST_LOBBY and state != ST_READY_CHECK:
		return {"ok": false, "error": "bad_state"}
	for p in players:
		if int(p.get("id", -1)) == player_id:
			p["ready"] = ready
	state = ST_READY_CHECK
	if _all_ready() and players.size() >= 2:
		state = ST_SYNCING
	return _snapshot()


func begin_match(seed_value: int, stage: String = "skyline-arena") -> Dictionary:
	if state != ST_SYNCING and state != ST_READY_CHECK:
		return {"ok": false, "error": "not_ready"}
	if players.size() < 2:
		return {"ok": false, "error": "need_two_players"}
	match_seed = seed_value
	stage_id = stage
	frame = 0
	last_confirmed_frame = -1
	desync_detected = false
	state = ST_IN_MATCH
	return _snapshot()


func advance_frame(confirmed: bool = true) -> Dictionary:
	if state != ST_IN_MATCH:
		return {"ok": false, "error": "not_in_match"}
	frame += 1
	if confirmed:
		last_confirmed_frame = frame
	return {"ok": true, "frame": frame, "last_confirmed_frame": last_confirmed_frame}


func mark_desync(expected_hash: String, actual_hash: String) -> Dictionary:
	desync_detected = true
	state = ST_ENDED
	return {
		"ok": false,
		"desync": true,
		"expected": expected_hash,
		"actual": actual_hash,
		"frame": frame,
	}


func add_spectator(name: String) -> Dictionary:
	spectators.append({"name": name})
	if state == ST_IN_MATCH:
		# Spectator join does not leave match for players.
		pass
	elif state == ST_LOBBY:
		pass
	else:
		state = ST_SPECTATING
	return _snapshot()


func end_match() -> Dictionary:
	state = ST_ENDED
	return _snapshot()


func apply_protocol_message(msg: Dictionary) -> Dictionary:
	var v: Dictionary = _OnlineProtocol.validate(msg)
	if not bool(v.get("ok", false)):
		return {"ok": false, "errors": v.get("errors", [])}
	match str(msg.get("type", "")):
		_OnlineProtocol.MSG_JOIN_LOBBY:
			var p: Dictionary = msg.get("payload", {})
			return join_lobby(str(p.get("lobby_id", lobby_id)), str(p.get("name", "guest")))
		_OnlineProtocol.MSG_READY:
			var p2: Dictionary = msg.get("payload", {})
			return set_ready(int(p2.get("player_id", local_player_id)), bool(p2.get("ready", true)))
		_OnlineProtocol.MSG_START_MATCH:
			var p3: Dictionary = msg.get("payload", {})
			if state == ST_LOBBY:
				for p in players:
					p["ready"] = true
				state = ST_SYNCING
			return begin_match(int(p3.get("seed", 0)), str(p3.get("stage", stage_id)))
		_OnlineProtocol.MSG_DESYNC:
			var p4: Dictionary = msg.get("payload", {})
			return mark_desync(str(p4.get("expected", "")), str(p4.get("actual", "")))
		_OnlineProtocol.MSG_SPECTATE:
			return add_spectator(str(msg.get("payload", {}).get("name", "spec")))
		_:
			return {"ok": true, "ignored": true, "type": msg.get("type")}


func _all_ready() -> bool:
	if players.is_empty():
		return false
	for p in players:
		if not bool(p.get("ready", false)):
			return false
	return true


func _snapshot() -> Dictionary:
	return {
		"ok": true,
		"state": state,
		"lobby_id": lobby_id,
		"players": players.duplicate(true),
		"spectators": spectators.duplicate(true),
		"match_seed": match_seed,
		"stage_id": stage_id,
		"frame": frame,
		"last_confirmed_frame": last_confirmed_frame,
		"desync_detected": desync_detected,
		"alpha_claim": alpha_claim,
	}


static func self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/session_state.gd")
	var s = ScriptRef.new()
	s.create_lobby("alpha-private", "Host")
	s.join_lobby("alpha-private", "Guest")
	s.set_ready(0, true)
	s.set_ready(1, true)
	var started: Dictionary = s.begin_match(77, "neon-rooftops")
	var ok := str(started.get("state", "")) == ST_IN_MATCH
	s.advance_frame(true)
	s.advance_frame(true)
	ok = ok and s.frame == 2 and s.last_confirmed_frame == 2
	s.add_spectator("Watcher")
	ok = ok and s.spectators.size() == 1
	s.mark_desync("aaa", "bbb")
	ok = ok and s.desync_detected and s.state == ST_ENDED
	return {
		"ok": ok,
		"final_state": s.state,
		"alpha_claim": s.alpha_claim,
	}
