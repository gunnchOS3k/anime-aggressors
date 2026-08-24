extends Node

## Circular flight recorder for Wave015 crash census + BattleScene human-path capture.
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
var _scene_instance_id: int = 0
var _last_snapshot_msec: int = 0


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


func set_scene_instance(scene: Node) -> void:
	if scene == null:
		_scene_instance_id = 0
		return
	_scene_instance_id = int(scene.get_instance_id())
	record("scene_bind", {
		"scene_instance_id": _scene_instance_id,
		"scene_path": str(scene.scene_file_path),
		"scene_name": str(scene.name),
	})


## Full two-fighter BattleScene snapshot (bounded; call at modest rate).
func record_battlescene_snapshot(scene: Node, fighter1: Node, fighter2: Node, extra: Dictionary = {}) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_snapshot_msec < 80 and extra.get("force", false) != true:
		return
	_last_snapshot_msec = now
	if scene != null:
		_scene_instance_id = int(scene.get_instance_id())
	var payload := {
		"timestamp_msec": now,
		"scene_instance_id": _scene_instance_id,
		"scene_path": str(scene.scene_file_path) if scene else "",
		"memory_static": OS.get_static_memory_usage(),
		"fighter1": _fighter_fields(fighter1, fighter2),
		"fighter2": _fighter_fields(fighter2, fighter1),
	}
	for k in extra.keys():
		if k == "force":
			continue
		payload[k] = extra[k]
	record("battlescene_snapshot", payload)


func _fighter_fields(fighter: Node, opponent: Node) -> Dictionary:
	if fighter == null or not is_instance_valid(fighter):
		return {"valid": false}
	var sm = fighter.get("state_machine")
	var prev_state := ""
	var cur_state := ""
	if sm != null:
		cur_state = str(sm.get("current_state"))
		prev_state = str(sm.get("previous_state")) if sm.get("previous_state") != null else ""
	var move: Dictionary = {}
	if fighter.get("_current_move") != null and typeof(fighter.get("_current_move")) == TYPE_DICTIONARY:
		move = fighter.get("_current_move")
	var model = fighter.get("model_3d")
	var skeleton_id := 0
	var controller_id := 0
	var viewport_id := 0
	var resolved_clip := ""
	if model != null and is_instance_valid(model):
		if model.has_method("get_active_clip"):
			resolved_clip = str(model.get_active_clip())
		elif model.get("_last_clip") != null:
			resolved_clip = str(model.get("_last_clip"))
		var sk = model.get("_visible_skeleton")
		if sk != null and is_instance_valid(sk):
			skeleton_id = int(sk.get_instance_id())
		var ctrl = model.get("_animation_controller")
		if ctrl != null and is_instance_valid(ctrl):
			controller_id = int(ctrl.get_instance_id())
		var vp = model.get("_viewport")
		if vp != null and is_instance_valid(vp):
			viewport_id = int(vp.get_instance_id())
	var proj_ids: Array = []
	var proj_count := 0
	var spawner = fighter.get("projectile_spawner")
	if spawner != null and is_instance_valid(spawner):
		if spawner.has_method("get_active_projectile_ids"):
			proj_ids = spawner.get_active_projectile_ids()
			proj_count = proj_ids.size()
		elif spawner.get("active_count") != null:
			proj_count = int(spawner.get("active_count"))
	var hitbox_active := false
	var hb = fighter.get_node_or_null("Hitbox")
	if hb != null:
		hitbox_active = bool(hb.monitoring)
	var grab_owner := ""
	var grab_target := ""
	var grabbed = fighter.get("grabbed_target")
	if grabbed != null and is_instance_valid(grabbed):
		grab_owner = str(fighter.get("fighter_id"))
		grab_target = str(grabbed.get("fighter_id"))
	var throw_dir := ""
	if model != null and model.get("_throw_dir") != null:
		throw_dir = str(model.get("_throw_dir"))
	var input_axis := Vector2.ZERO
	var input_edge := ""
	if fighter.has_method("_read_axis"):
		input_axis = Vector2(float(fighter.call("_read_axis")), 0.0)
	if fighter.has_method("is_aura_input_held") and bool(fighter.call("is_aura_input_held")):
		input_edge = "aura_charge"
	var recovering := false
	if cur_state in ["LEDGE_HANG", "LEDGE_CLIMB", "LEDGE_JUMP", "TUMBLE", "LAUNCHED"]:
		recovering = true
	var ko_or_respawn := int(fighter.get("stocks")) if fighter.get("stocks") != null else -1
	return {
		"valid": true,
		"fighter_id": str(fighter.get("fighter_id")),
		"opponent_id": str(opponent.get("fighter_id")) if opponent and is_instance_valid(opponent) else "",
		"player_or_cpu": "cpu" if bool(fighter.get("is_cpu")) else "player",
		"slot": int(fighter.get("slot")) if fighter.get("slot") != null else 0,
		"input_edge": input_edge,
		"input_axis": [input_axis.x, input_axis.y],
		"state": cur_state,
		"previous_state": prev_state,
		"move_id": str(move.get("move_id", "")),
		"resolved_clip": resolved_clip,
		"grounded": bool(fighter.is_on_floor()) if fighter.has_method("is_on_floor") else false,
		"velocity": [fighter.velocity.x, fighter.velocity.y] if fighter.get("velocity") != null else [0, 0],
		"position": [fighter.global_position.x, fighter.global_position.y],
		"damage": float(fighter.get("damage_percent")),
		"stocks": ko_or_respawn,
		"aura": float(fighter.get("aura")),
		"hitstun": float(fighter.get("hitstun_remaining")),
		"grab_owner": grab_owner,
		"grab_target": grab_target,
		"throw_direction": throw_dir,
		"projectile_ids": proj_ids,
		"projectile_count": proj_count,
		"active_hitboxes": hitbox_active,
		"recovery": recovering,
		"ko_stocks": ko_or_respawn,
		"model_instance_id": int(model.get_instance_id()) if model and is_instance_valid(model) else 0,
		"skeleton_instance_id": skeleton_id,
		"controller_instance_id": controller_id,
		"subviewport_id": viewport_id,
	}


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
		"scene_instance_id": _scene_instance_id,
		"memory_static": OS.get_static_memory_usage(),
		"status": "CLEAN_SHUTDOWN" if clean else "RUNNING",
	}
	var f := FileAccess.open(HEARTBEAT_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()
