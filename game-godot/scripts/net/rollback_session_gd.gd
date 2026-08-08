extends RefCounted
class_name RollbackSessionGd

## Frame-level input sync + rollback for private netplay (Godot path).
## Stores per-frame button dictionaries; resims checksum chain on late confirm.

const _RollbackLatencyPolicy = preload("res://scripts/net/rollback_latency_policy.gd")

var policy
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


func advance_frame(local_inputs: Array, confirmed_flags: Array) -> Dictionary:
	## local_inputs: Array of button dicts sized to max_players (may be partial).
	var inputs: Array = []
	var confirmed: Array = []
	for p in range(max_players):
		var key := _key(current_frame, p)
		var provided: Dictionary = local_inputs[p] if p < local_inputs.size() and typeof(local_inputs[p]) == TYPE_DICTIONARY else _default_buttons()
		var is_conf: bool = bool(confirmed_flags[p]) if p < confirmed_flags.size() else false
		if is_conf:
			_confirmed[key] = provided.duplicate(true)
			inputs.append(provided.duplicate(true))
		elif _confirmed.has(key):
			inputs.append(_confirmed[key].duplicate(true))
		else:
			_predicted[key] = provided.duplicate(true)
			inputs.append(provided.duplicate(true))
		confirmed.append(is_conf or _confirmed.has(key))
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
	return {
		"ok": true,
		"frame": current_frame - 1,
		"inputs": inputs,
		"checksum": checksum,
		"rollback_count": rollback_count,
	}


func confirm_remote_input(frame: int, player_id: int, buttons: Dictionary) -> Dictionary:
	var key := _key(frame, player_id)
	var predicted = _predicted.get(key, null)
	_confirmed[key] = buttons.duplicate(true)
	var mismatch := false
	if predicted != null:
		mismatch = str(predicted) != str(buttons)
	if not mismatch:
		return {"ok": true, "rolled_back": false, "frame": frame}
	if not policy.can_rollback(frame, current_frame):
		desync_detected = true
		return {"ok": false, "rolled_back": false, "error": "beyond_rollback", "frame": frame}
	# Resim from frame.
	var start_idx := -1
	for i in range(_history.size()):
		if int(_history[i].get("frame", -1)) == frame:
			start_idx = i
			break
	if start_idx < 0:
		return {"ok": false, "rolled_back": false, "error": "missing_history"}
	rollback_count += 1
	last_rollback_frame = frame
	# Truncate and re-advance with confirmed remote.
	var keep: Array = _history.slice(0, start_idx)
	_history = keep
	current_frame = frame
	for i in range(start_idx, start_idx + policy.max_rollback_frames):
		# Rebuild using confirmed where available else last predicted.
		var rebuilt: Array = []
		var flags: Array = []
		for p in range(max_players):
			var k2 := _key(current_frame, p)
			if _confirmed.has(k2):
				rebuilt.append(_confirmed[k2].duplicate(true))
				flags.append(true)
			elif _predicted.has(k2):
				rebuilt.append(_predicted[k2].duplicate(true))
				flags.append(false)
			else:
				rebuilt.append(_default_buttons())
				flags.append(false)
		advance_frame(rebuilt, flags)
		if current_frame >= frame + (i - start_idx) + 1 and i >= start_idx:
			pass
		# Stop once we've caught original tip.
		if _history.size() > 0 and int(_history[-1].get("frame", -1)) >= frame + (policy.max_rollback_frames):
			break
		if current_frame > frame + policy.max_rollback_frames:
			break
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
	ok = ok and c1 == c2 and before > 0
	return {"ok": ok, "rollback_count": s.rollback_count, "state": s.as_dict()}
