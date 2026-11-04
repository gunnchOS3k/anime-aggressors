extends RefCounted
class_name RollbackSessionGd

## Frame-level input sync + rollback for private netplay (Godot path).
## Stores per-frame button dictionaries; resims checksum chain on late confirm.

const _RollbackLatencyPolicy = preload("res://scripts/net/rollback_latency_policy.gd")

var policy
# Declared PartyLink seat counts. These bound input arrays only; neither this
# scaffold nor a passing multi-slot test constitutes 4/6/8-client gameplay.
const SUPPORTED_PLAYER_COUNTS := [2, 4, 6, 8]
var _bound_player_count: int = 0
var current_frame: int = 0
var max_players: int = 2
var _history: Array = []  # [{frame, inputs:Array[Dict], confirmed:Array[bool], checksum:String}]
var _confirmed: Dictionary = {}  # "f:p" -> buttons
var _predicted: Dictionary = {}
var rollback_count: int = 0
var last_rollback_frame: int = -1
var desync_detected: bool = false
var last_checksum: String = ""


func _init() -> void:
	policy = _RollbackLatencyPolicy.new()
	policy.configure(2, 8, 3)


func reset() -> void:
	_bound_player_count = 0
	current_frame = 0
	_history.clear()
	_confirmed.clear()
	_predicted.clear()
	rollback_count = 0
	last_rollback_frame = -1
	desync_detected = false
	last_checksum = ""


func _key(frame: int, player_id: int) -> String:
	return "%d:%d" % [frame, player_id]


func _default_buttons() -> Dictionary:
	return {
		"left": false, "right": false, "up": false, "down": false,
		"jump": false, "attack": false, "special": false,
		"shield": false, "dodge": false, "grab": false,
	}


func _checksum_for(frame: int, inputs: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("f=%d" % frame)
	for i in range(inputs.size()):
		var b: Dictionary = inputs[i]
		var keys: Array = b.keys()
		keys.sort()
		for k in keys:
			parts.append("%d.%s=%s" % [i, str(k), str(b[k])])
	return str(hash("|".join(parts)))


func _valid_player_count() -> bool:
	return max_players in SUPPORTED_PLAYER_COUNTS and (_bound_player_count == 0 or _bound_player_count == max_players)


func _normalized_buttons(buttons: Dictionary) -> Dictionary:
	# Call only after strict validation. An omitted button means released,
	# never "unknown", and is semantically equal to its explicit false value.
	var result := _default_buttons()
	for button in buttons:
		result[button] = buttons[button]
	return result


func advance_frame(local_inputs: Array, confirmed_flags: Array) -> Dictionary:
	## Partial arrays are permitted; every supplied value must still be valid.
	## Validate the ENTIRE frame before changing any slot, map or frame counter.
	if not _valid_player_count():
		return {"ok":false, "error":"invalid_player_count", "frame":current_frame}
	if local_inputs.size() > max_players or confirmed_flags.size() > max_players:
		return {"ok":false, "error":"invalid_frame_shape", "frame":current_frame}
	var inputs: Array = []
	var confirmed: Array = []
	for p in range(max_players):
		var key := _key(current_frame, p)
		var raw: Variant = local_inputs[p] if p < local_inputs.size() else {}
		if typeof(raw) != TYPE_DICTIONARY or not _valid_remote_buttons(raw):
			return {"ok":false, "error":"invalid_input", "frame":current_frame}
		if p < confirmed_flags.size() and typeof(confirmed_flags[p]) != TYPE_BOOL:
			return {"ok":false, "error":"invalid_confirmation_flag", "frame":current_frame}
		var provided := _normalized_buttons(raw)
		var is_conf: bool = confirmed_flags[p] if p < confirmed_flags.size() else false
		if _confirmed.has(key):
			# A queued authoritative input cannot be overwritten by the trusted
			# frame caller either. Matching retransmission remains idempotent.
			if is_conf and _confirmed[key] != provided:
				return {"ok":false, "error":"conflicting_confirmation", "frame":current_frame}
			inputs.append(_confirmed[key].duplicate(true))
		else:
			inputs.append(provided)
		confirmed.append(is_conf or _confirmed.has(key))
	# No validation or rejection remains after this point.
	_bound_player_count = max_players
	for p in range(max_players):
		var key := _key(current_frame, p)
		if bool(confirmed[p]):
			_confirmed[key] = inputs[p].duplicate(true)
			_predicted.erase(key)
		else:
			_predicted[key] = inputs[p].duplicate(true)
	var checksum := _checksum_for(current_frame, inputs)
	last_checksum = checksum
	_history.append({
		"frame": current_frame,
		"inputs": inputs,
		"confirmed": confirmed,
		"checksum": checksum,
	})
	while _history.size() > policy.max_rollback_frames + 2:
		_history.pop_front()
	current_frame += 1
	_prune_inputs()
	return {
		"ok": true,
		"frame": current_frame - 1,
		"inputs": inputs.duplicate(true),
		"checksum": checksum,
		"rollback_count": rollback_count,
	}


func _valid_remote_buttons(buttons: Dictionary) -> bool:
	var allowed := _default_buttons()
	for button in buttons:
		if not allowed.has(button) or typeof(buttons[button]) != TYPE_BOOL:
			return false
	return true


func _prune_inputs() -> void:
	if _history.is_empty(): return
	var oldest: int = int(_history[0].frame)
	for records in [_confirmed, _predicted]:
		for key in records.keys():
			if int(str(key).get_slice(":", 0)) < oldest:
				records.erase(key)


func confirm_remote_input(frame: int, player_id: int, buttons: Dictionary) -> Dictionary:
	# Inputs are immutable once confirmed. Validate before changing either the
	# timeline or its pending maps; a rejected packet cannot poison a later step.
	if not _valid_player_count():
		return {"ok":false, "rolled_back":false, "error":"invalid_player_count", "frame":frame}
	if frame < 0 or player_id < 0 or player_id >= max_players or not _valid_remote_buttons(buttons):
		return {"ok": false, "rolled_back": false, "error": "invalid_input", "frame": frame}
	if frame > current_frame + policy.max_rollback_frames:
		return {"ok": false, "rolled_back": false, "error": "future_input_limit", "frame": frame}
	var key := _key(frame, player_id)
	var canonical := _normalized_buttons(buttons)
	if _confirmed.has(key):
		return {"ok": _confirmed[key] == canonical, "rolled_back": false, "error": "" if _confirmed[key] == canonical else "conflicting_confirmation", "frame": frame}
	if frame >= current_frame:
		_bound_player_count = max_players
		_confirmed[key] = canonical.duplicate(true)
		return {"ok": true, "rolled_back": false, "queued": true, "frame": frame}
	if not policy.can_rollback(frame, current_frame):
		desync_detected = true
		return {"ok": false, "rolled_back": false, "error": "beyond_rollback", "frame": frame}
	var start_idx := -1
	for i in range(_history.size()):
		if int(_history[i].get("frame", -1)) == frame:
			start_idx = i
			break
	if start_idx < 0:
		return {"ok": false, "rolled_back": false, "error": "missing_history", "frame": frame}
	var original: Dictionary = _history[start_idx]
	_bound_player_count = max_players
	_confirmed[key] = canonical.duplicate(true)
	_predicted.erase(key)
	if original.inputs[player_id] == canonical:
		original.confirmed[player_id] = true
		return {"ok": true, "rolled_back": false, "frame": frame}
	# This class only rebuilds INPUT CHECKSUMS, not a game-world snapshot.
	# Retain the original tip and every recorded slot's input. Replaying a fixed
	# policy window used to invent unplayed frames and discard local input.
	var target_frame: int = current_frame
	var replay_rows: Array = _history.slice(start_idx).duplicate(true)
	rollback_count += 1
	last_rollback_frame = frame
	_history = _history.slice(0, start_idx)
	current_frame = frame
	for record in replay_rows:
		var rebuilt: Array = record.inputs.duplicate(true)
		var flags: Array = record.confirmed.duplicate()
		for p in range(max_players):
			var confirmed_key := _key(current_frame, p)
			if _confirmed.has(confirmed_key):
				rebuilt[p] = _confirmed[confirmed_key].duplicate(true)
				flags[p] = true
		advance_frame(rebuilt, flags)
	assert(current_frame == target_frame)
	return {
		"ok": true,
		"rolled_back": true,
		"frame": frame,
		"rollback_count": rollback_count,
		"current_frame": current_frame,
	}


func compare_checksum(frame: int, remote_hash: String) -> Dictionary:
	for h in _history:
		if int(h.get("frame", -1)) == frame:
			var local: String = str(h.get("checksum", ""))
			if local != remote_hash:
				desync_detected = true
				return {"ok": false, "desync": true, "frame": frame, "local": local, "remote": remote_hash}
			return {"ok": true, "desync": false, "frame": frame}
	return {"ok": false, "error": "checksum_frame_missing", "frame": frame}


func as_dict() -> Dictionary:
	return {
		"current_frame": current_frame,
		"rollback_count": rollback_count,
		"last_rollback_frame": last_rollback_frame,
		"desync_detected": desync_detected,
		"history_len": _history.size(),
		"configured_players": max_players,
		"bound_players": _bound_player_count,
		"policy": policy.as_dict(),
	}


static func self_test() -> Dictionary:
	var ScriptRef = load("res://scripts/net/rollback_session_gd.gd")
	var s = ScriptRef.new()
	s.reset()
	# Advance with predicted remote empty.
	for f in range(6):
		s.advance_frame([
			{"attack": f % 2 == 0},
			{"attack": false},
		], [true, false])
	var before: int = int(s.current_frame)
	var rb: Dictionary = s.confirm_remote_input(2, 1, {"attack": true})
	var ok: bool = bool(rb.get("rolled_back", false)) and s.rollback_count >= 1
	var c1: String = str(s._checksum_for(0, [{"a": 1}, {"b": 2}]))
	var c2: String = str(s._checksum_for(0, [{"a": 1}, {"b": 2}]))
	ok = ok and c1 == c2 and before > 0 and s.current_frame == before
	return {"ok": ok, "rollback_count": s.rollback_count, "state": s.as_dict()}
