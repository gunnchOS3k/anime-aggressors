extends RefCounted
class_name DisconnectPolicy

## Disconnect / stall / forfeit policy for private netplay.

const GRACE_MS := 3000.0
const HARD_TIMEOUT_MS := 8000.0
const MAX_RECONNECT_ATTEMPTS := 3
const SPECTATOR_DROP_OK := true

const REASON_STALL := "stall"
const REASON_HARD_TIMEOUT := "hard_timeout"
const REASON_DESYNC := "desync"
const REASON_TAMPER := "tamper"
const REASON_QUIT := "quit"
const REASON_VERSION := "version_incompatible"

var grace_ms: float = GRACE_MS
var hard_timeout_ms: float = HARD_TIMEOUT_MS
var max_reconnect_attempts: int = MAX_RECONNECT_ATTEMPTS
var reconnect_attempts: int = 0
var disconnected_at_ms: float = -1.0
var last_reason: String = ""


func note_disconnect(now_ms: float, reason: String) -> void:
	if disconnected_at_ms < 0.0:
		disconnected_at_ms = now_ms
	last_reason = reason


func clear_disconnect() -> void:
	disconnected_at_ms = -1.0
	last_reason = ""


func can_attempt_reconnect() -> bool:
	return reconnect_attempts < max_reconnect_attempts and last_reason in [REASON_STALL, REASON_HARD_TIMEOUT, "network_blip"]


func begin_reconnect() -> bool:
	if not can_attempt_reconnect():
		return false
	reconnect_attempts += 1
	return true


func evaluate(now_ms: float, remote_confirmed_age_ms: float, desync: bool, tamper: bool) -> Dictionary:
	if tamper:
		return {"action": "forfeit", "reason": REASON_TAMPER, "winner_slot": 1}
	if desync:
		return {"action": "end_desync", "reason": REASON_DESYNC, "winner_slot": 0}
	if remote_confirmed_age_ms >= hard_timeout_ms:
		note_disconnect(now_ms, REASON_HARD_TIMEOUT)
		return {"action": "forfeit", "reason": REASON_HARD_TIMEOUT, "winner_slot": 1}
	if remote_confirmed_age_ms >= grace_ms:
		note_disconnect(now_ms, REASON_STALL)
		return {"action": "stall_wait", "reason": REASON_STALL, "winner_slot": 0}
	clear_disconnect()
	return {"action": "continue", "reason": "", "winner_slot": 0}


func forfeit_on_quit(quitting_player_id: int) -> Dictionary:
	var winner := 1 if quitting_player_id == 0 else 0
	# slots are 1-indexed for GameState
	return {"action": "forfeit", "reason": REASON_QUIT, "winner_slot": winner + 1, "quitting_player_id": quitting_player_id}


static func self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/disconnect_policy.gd")
	var p = ScriptRef.new()
	var cont: Dictionary = p.evaluate(1000.0, 100.0, false, false)
	var stall: Dictionary = p.evaluate(1000.0, 3500.0, false, false)
	var hard: Dictionary = p.evaluate(1000.0, 9000.0, false, false)
	var tamp: Dictionary = p.evaluate(1000.0, 10.0, false, true)
	var ok: bool = str(cont.get("action")) == "continue" \
		and str(stall.get("action")) == "stall_wait" \
		and str(hard.get("action")) == "forfeit" \
		and str(tamp.get("action")) == "forfeit"
	ok = ok and p.begin_reconnect() and p.begin_reconnect() and p.begin_reconnect()
	ok = ok and not p.begin_reconnect()
	return {"ok": ok, "attempts": p.reconnect_attempts}
