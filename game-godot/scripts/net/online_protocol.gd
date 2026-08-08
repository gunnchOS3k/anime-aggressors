extends RefCounted
class_name OnlineProtocol

## Godot-side online protocol scaffold (Alpha architecture only).
## No public deploy claim — message shapes + validation for private lobby path.

const PROTOCOL_VERSION := 2
const ALPHA_CLAIM := "PRIVATE_LOOPBACK_ONLY — no public deploy"
const PROTOCOL_SCOPE := "private_loopback_host"

const MSG_HELLO := "hello"
const MSG_JOIN_LOBBY := "join_lobby"
const MSG_LOBBY_STATE := "lobby_state"
const MSG_READY := "ready"
const MSG_START_MATCH := "start_match"
const MSG_INPUT := "input"
const MSG_INPUT_ACK := "input_ack"
const MSG_CHECKSUM := "checksum"
const MSG_DESYNC := "desync"
const MSG_SPECTATE := "spectate"
const MSG_PING := "ping"
const MSG_PONG := "pong"
const MSG_DISCONNECT := "disconnect"
const MSG_RECONNECT := "reconnect"
const MSG_RECONNECT_ACK := "reconnect_ack"
const MSG_MATCHMAKING_QUEUE := "matchmaking_queue"
const MSG_MATCHMAKING_FOUND := "matchmaking_found"
const MSG_REPLAY_CHUNK := "replay_chunk"
const MSG_VERSION_CHECK := "version_check"
const MSG_VERSION_OK := "version_ok"
const MSG_TAMPER_ALERT := "tamper_alert"

const ALL_TYPES := [
	MSG_HELLO, MSG_JOIN_LOBBY, MSG_LOBBY_STATE, MSG_READY, MSG_START_MATCH,
	MSG_INPUT, MSG_INPUT_ACK, MSG_CHECKSUM, MSG_DESYNC, MSG_SPECTATE,
	MSG_PING, MSG_PONG, MSG_DISCONNECT, MSG_RECONNECT, MSG_RECONNECT_ACK,
	MSG_MATCHMAKING_QUEUE, MSG_MATCHMAKING_FOUND, MSG_REPLAY_CHUNK,
	MSG_VERSION_CHECK, MSG_VERSION_OK, MSG_TAMPER_ALERT,
]


static func envelope(msg_type: String, payload: Dictionary = {}, seq: int = 0) -> Dictionary:
	return {
		"v": PROTOCOL_VERSION,
		"type": msg_type,
		"seq": seq,
		"ts_ms": Time.get_ticks_msec(),
		"payload": payload.duplicate(true),
	}


static func validate(msg: Dictionary) -> Dictionary:
	var errors: Array = []
	if int(msg.get("v", -1)) != PROTOCOL_VERSION:
		errors.append("bad_version")
	var t: String = str(msg.get("type", ""))
	if not ALL_TYPES.has(t):
		errors.append("unknown_type")
	if not msg.has("payload") or typeof(msg.get("payload")) != TYPE_DICTIONARY:
		errors.append("missing_payload")
	if not msg.has("seq"):
		errors.append("missing_seq")
	match t:
		MSG_INPUT:
			var p: Dictionary = msg.get("payload", {})
			if not p.has("frame"):
				errors.append("input_missing_frame")
			if not p.has("player_id"):
				errors.append("input_missing_player")
			if not p.has("buttons"):
				errors.append("input_missing_buttons")
		MSG_CHECKSUM:
			var c: Dictionary = msg.get("payload", {})
			if not c.has("frame") or not c.has("hash"):
				errors.append("checksum_incomplete")
		MSG_START_MATCH:
			var s: Dictionary = msg.get("payload", {})
			if not s.has("seed") or not s.has("roster"):
				errors.append("start_incomplete")
		MSG_RECONNECT:
			var r: Dictionary = msg.get("payload", {})
			if not r.has("lobby_id") or not r.has("player_id") or not r.has("last_confirmed_frame"):
				errors.append("reconnect_incomplete")
		MSG_VERSION_CHECK:
			var vc: Dictionary = msg.get("payload", {})
			if not vc.has("proto") or not vc.has("build"):
				errors.append("version_incomplete")
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"type": t,
	}


static func encode_input(frame: int, player_id: int, buttons: Dictionary) -> Dictionary:
	return envelope(MSG_INPUT, {
		"frame": frame,
		"player_id": player_id,
		"buttons": buttons.duplicate(true),
	}, frame)


static func encode_checksum(frame: int, hash_str: String) -> Dictionary:
	return envelope(MSG_CHECKSUM, {"frame": frame, "hash": hash_str}, frame)


static func self_test() -> Dictionary:
	var hello := envelope(MSG_HELLO, {"client": "godot-scaffold"})
	var join := envelope(MSG_JOIN_LOBBY, {"lobby_id": "private-alpha", "name": "P1"})
	var start := envelope(MSG_START_MATCH, {
		"seed": 42,
		"roster": ["ember-vale", "rook-ironside"],
		"stage": "skyline-arena",
	})
	var inp := encode_input(12, 0, {"left": false, "right": true, "attack": true})
	var chk := encode_checksum(12, "deadbeef")
	var results := []
	for m in [hello, join, start, inp, chk]:
		results.append(validate(m))
	var all_ok := true
	for r in results:
		if not bool(r.get("ok", false)):
			all_ok = false
	var bad := validate({"v": 0, "type": "nope"})
	return {
		"ok": all_ok and not bool(bad.get("ok", true)),
		"message_count": results.size(),
		"types": ALL_TYPES.size(),
		"protocol_version": PROTOCOL_VERSION,
		"alpha_claim": ALPHA_CLAIM,
	}
