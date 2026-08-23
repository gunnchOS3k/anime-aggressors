extends Node

## Circular flight recorder for Wave015 crash census.
## Writes user://diagnostics/last_action_trace.jsonl + session_heartbeat.json.

const DIAG_DIR := "user://diagnostics/"
const TRACE_PATH := "user://diagnostics/last_action_trace.jsonl"
const HEARTBEAT_PATH := "user://diagnostics/session_heartbeat.json"
const MAX_EVENTS := 512

var _buffer: Array = []
var _seq: int = 0
var _session_id: String = ""
var _dirty: bool = false
var _flush_accum: float = 0.0
var _clean_shutdown: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIAG_DIR))
	_session_id = "%s-%d" % [Time.get_datetime_string_from_system(true).replace(":", ""), Time.get_ticks_msec()]
	_note_previous_session()
	_write_heartbeat(false, "SESSION_START")
	record("session_start", {"session_id": _session_id})


func _process(delta: float) -> void:
	_flush_accum += delta
	if _dirty and _flush_accum >= 0.5:
		_flush_accum = 0.0
		_persist_trace()
		_write_heartbeat(false, "HEARTBEAT")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		mark_clean_shutdown()


func mark_clean_shutdown() -> void:
	if _clean_shutdown:
		return
	_clean_shutdown = true
	record("session_end", {"clean_shutdown": true})
	_persist_trace()
	_write_heartbeat(true, "CLEAN_SHUTDOWN")


func record(kind: String, payload: Dictionary = {}) -> void:
	_seq += 1
	var row := {
		"seq": _seq,
		"t_msec": Time.get_ticks_msec(),
		"kind": kind,
		"payload": payload.duplicate(true),
		"session_id": _session_id,
	}
	_buffer.append(row)
	while _buffer.size() > MAX_EVENTS:
		_buffer.pop_front()
	_dirty = true


func record_action(fighter_id: String, action: String, route: String, extra: Dictionary = {}) -> void:
	var body := extra.duplicate(true)
	body["fighter_id"] = fighter_id
	body["action"] = action
	body["route"] = route
	record("action", body)


func get_recent(limit: int = 64) -> Array:
	if limit <= 0 or limit >= _buffer.size():
		return _buffer.duplicate(true)
	return _buffer.slice(_buffer.size() - limit, _buffer.size())


func get_session_id() -> String:
	return _session_id


func _note_previous_session() -> void:
	if not FileAccess.file_exists(HEARTBEAT_PATH):
		return
	var f := FileAccess.open(HEARTBEAT_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var prev: Dictionary = parsed
	if not bool(prev.get("clean_shutdown", false)):
		record("previous_session", {
			"status": "PREVIOUS_SESSION_UNEXPECTED_TERMINATION",
			"previous_session_id": str(prev.get("session_id", "")),
			"previous_last_kind": str(prev.get("last_kind", "")),
			"previous_seq": int(prev.get("seq", 0)),
		})


func _persist_trace() -> void:
	var f := FileAccess.open(TRACE_PATH, FileAccess.WRITE)
	if f == null:
		return
	for row in _buffer:
		f.store_line(JSON.stringify(row))
	f.close()
	_dirty = false


func _write_heartbeat(clean: bool, last_kind: String) -> void:
	var payload := {
		"schema": "engineering_wave015.session_heartbeat.v1",
		"session_id": _session_id,
		"t_msec": Time.get_ticks_msec(),
		"seq": _seq,
		"clean_shutdown": clean,
		"last_kind": last_kind,
		"buffer_size": _buffer.size(),
		"status": "CLEAN_SHUTDOWN" if clean else "RUNNING",
	}
	var f := FileAccess.open(HEARTBEAT_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()
