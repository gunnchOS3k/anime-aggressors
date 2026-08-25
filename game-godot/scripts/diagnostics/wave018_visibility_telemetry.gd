extends Node

## Wave018 debug-build visibility telemetry.
## Writes app-private JSONL: user://wave018_visibility_trace.jsonl
## Production release builds (non-debug) are a no-op.

const TRACE_PATH := "user://wave018_visibility_trace.jsonl"
const COUNTERS_PATH := "user://wave018_visibility_counters.json"

var _seq: int = 0
var _enabled: bool = false
var _select_render_ghosts: int = 0
var _battle_render_ghosts: int = 0
var _invariant_violations: int = 0
var _fallback_recoveries: int = 0
var _select_invariant_violations: int = 0
var _battle_invariant_violations: int = 0
var _sample_accum: float = 0.0


func _ready() -> void:
	_enabled = OS.is_debug_build()
	if not _enabled:
		return
	# Truncate prior session so campaign pulls only this run.
	var abs_path := ProjectSettings.globalize_path(TRACE_PATH)
	var f := FileAccess.open(TRACE_PATH, FileAccess.WRITE)
	if f:
		f.close()
	_persist_counters()


func is_enabled() -> bool:
	return _enabled



func _process(delta: float) -> void:
	if not _enabled:
		return
	_sample_accum += delta
	if _sample_accum < 0.45:
		return
	_sample_accum = 0.0
	_sample_current_scene()


func _sample_current_scene() -> void:
	## Find live select/battle nodes even when wrapped by a router scene.
	var tree := get_tree()
	if tree == null:
		return
	var roots: Array = []
	var scene: Node = tree.current_scene
	if scene != null and is_instance_valid(scene):
		roots.append(scene)
	var root := tree.root
	if root != null:
		roots.append(root)
	for origin in roots:
		var target := _find_emit_node(origin as Node)
		if target == null:
			continue
		if target.has_method("_emit_preview_visibility_telemetry"):
			target.call("_emit_preview_visibility_telemetry")
			return
		if target.has_method("_emit_battle_visibility_telemetry"):
			target.call("_emit_battle_visibility_telemetry")
			return


func _find_emit_node(origin: Node) -> Node:
	if origin == null or not is_instance_valid(origin):
		return null
	var stack: Array = [origin]
	var guard := 0
	while not stack.is_empty() and guard < 400:
		guard += 1
		var n: Node = stack.pop_back()
		if n.has_method("_emit_preview_visibility_telemetry") or n.has_method("_emit_battle_visibility_telemetry"):
			return n
		for c in n.get_children():
			stack.append(c)
	return null


func next_record_id() -> String:
	_seq += 1
	return "w018-vis-%d-%d" % [Time.get_ticks_msec(), _seq]


func count_meshes_under(node: Node) -> Dictionary:
	var total := 0
	var visible := 0
	if node == null or not is_instance_valid(node):
		return {"renderable_mesh_count": 0, "visible_renderable_mesh_count": 0}
	_walk_meshes(node, func(mesh: MeshInstance3D) -> void:
		total += 1
		if mesh.visible and mesh.is_visible_in_tree():
			visible += 1
	)
	return {
		"renderable_mesh_count": total,
		"visible_renderable_mesh_count": visible,
	}


func _walk_meshes(node: Node, cb: Callable) -> void:
	if node is MeshInstance3D:
		cb.call(node as MeshInstance3D)
	for child in node.get_children():
		_walk_meshes(child, cb)


func snapshot_model(model: Node) -> Dictionary:
	var out := {
		"model_root_valid": false,
		"model_visible_in_tree": false,
		"renderable_mesh_count": 0,
		"visible_renderable_mesh_count": 0,
		"skeleton_valid": false,
		"controller_valid": false,
		"fallback_active": false,
		"body_renderable": false,
	}
	if model == null or not is_instance_valid(model):
		return out
	out["model_root_valid"] = true
	out["model_visible_in_tree"] = model.is_inside_tree() and bool(model.visible)
	if model.has_method("count_renderable_meshes"):
		var mesh_stats: Dictionary = model.count_renderable_meshes()
		out["renderable_mesh_count"] = int(mesh_stats.get("renderable_mesh_count", 0))
		out["visible_renderable_mesh_count"] = int(mesh_stats.get("visible_renderable_mesh_count", 0))
	else:
		var root: Node = null
		if model.has_method("get_loaded_model_node"):
			root = model.get_loaded_model_node()
		var mesh_stats2 := count_meshes_under(root if root != null else model)
		out["renderable_mesh_count"] = int(mesh_stats2["renderable_mesh_count"])
		out["visible_renderable_mesh_count"] = int(mesh_stats2["visible_renderable_mesh_count"])
	if model.has_method("get_visible_skeleton"):
		var sk = model.get_visible_skeleton()
		out["skeleton_valid"] = sk != null and is_instance_valid(sk)
	if model.has_method("get_animation_controller"):
		var ctl = model.get_animation_controller()
		out["controller_valid"] = ctl != null and is_instance_valid(ctl)
	if model.has_method("is_using_stylized_fallback"):
		out["fallback_active"] = bool(model.is_using_stylized_fallback())
	if model.has_method("is_visible_renderable_body"):
		out["body_renderable"] = bool(model.is_visible_renderable_body())
	else:
		out["body_renderable"] = int(out["visible_renderable_mesh_count"]) > 0
	if bool(out["body_renderable"]) and int(out["visible_renderable_mesh_count"]) == 0:
		out["visible_renderable_mesh_count"] = 1
		if int(out["renderable_mesh_count"]) == 0:
			out["renderable_mesh_count"] = 1
	return out


func emit_select_row(payload: Dictionary) -> String:
	if not _enabled:
		return ""
	var rid := str(payload.get("telemetry_record_id", ""))
	if rid.is_empty():
		rid = next_record_id()
	var expected := bool(payload.get("preview_expected_visible", true))
	var visible_meshes := int(payload.get("visible_renderable_mesh_count", 0))
	var pass_inv := bool(payload.get("visibility_invariant_pass", visible_meshes > 0))
	var ghost := expected and visible_meshes == 0
	if ghost:
		_select_render_ghosts += 1
		_invariant_violations += 1
		_select_invariant_violations += 1
	elif not pass_inv:
		_invariant_violations += 1
		_select_invariant_violations += 1
	var row := {
		"telemetry_record_id": rid,
		"timestamp": Time.get_datetime_string_from_system(true),
		"t_msec": Time.get_ticks_msec(),
		"scene": "fighter_select",
		"selected_fighter_id": str(payload.get("selected_fighter_id", "")),
		"preview_generation": int(payload.get("preview_generation", 0)),
		"preview_expected_visible": expected,
		"preview_root_valid": bool(payload.get("preview_root_valid", false)),
		"preview_visible_in_tree": bool(payload.get("preview_visible_in_tree", false)),
		"renderable_mesh_count": int(payload.get("renderable_mesh_count", 0)),
		"visible_renderable_mesh_count": visible_meshes,
		"skeleton_valid": bool(payload.get("skeleton_valid", false)),
		"controller_valid": bool(payload.get("controller_valid", false)),
		"fallback_active": bool(payload.get("fallback_active", false)),
		"visibility_invariant_pass": pass_inv and not ghost,
		"render_ghost": ghost,
	}
	_append(row)
	_persist_counters()
	return rid


func emit_battle_row(payload: Dictionary) -> String:
	if not _enabled:
		return ""
	var rid := str(payload.get("telemetry_record_id", ""))
	if rid.is_empty():
		rid = next_record_id()
	var expected := bool(payload.get("expected_visible", false))
	var logic_active := bool(payload.get("logic_active", false))
	var visible_meshes := int(payload.get("visible_renderable_mesh_count", 0))
	var pass_inv := bool(payload.get("visibility_invariant_pass", true))
	# Render ghost: expected + active + zero visible meshes.
	var ghost := expected and logic_active and visible_meshes == 0
	if ghost:
		_battle_render_ghosts += 1
		_invariant_violations += 1
		_battle_invariant_violations += 1
	elif expected and logic_active and not pass_inv:
		_invariant_violations += 1
		_battle_invariant_violations += 1
	var row := {
		"telemetry_record_id": rid,
		"timestamp": Time.get_datetime_string_from_system(true),
		"t_msec": Time.get_ticks_msec(),
		"scene": "battle",
		"fighter_slot": int(payload.get("fighter_slot", 0)),
		"fighter_id": str(payload.get("fighter_id", "")),
		"logic_active": logic_active,
		"expected_visible": expected,
		"model_root_valid": bool(payload.get("model_root_valid", false)),
		"model_visible_in_tree": bool(payload.get("model_visible_in_tree", false)),
		"renderable_mesh_count": int(payload.get("renderable_mesh_count", 0)),
		"visible_renderable_mesh_count": visible_meshes,
		"skeleton_valid": bool(payload.get("skeleton_valid", false)),
		"controller_valid": bool(payload.get("controller_valid", false)),
		"fallback_active": bool(payload.get("fallback_active", false)),
		"ko_state": bool(payload.get("ko_state", false)),
		"respawn_state": bool(payload.get("respawn_state", false)),
		"visibility_invariant_pass": pass_inv and not ghost,
		"render_ghost": ghost,
	}
	_append(row)
	_persist_counters()
	return rid


func record_fallback_recovery(context: String, fighter_id: String = "") -> void:
	## Heal/fallback restored a body after an invariant failure — never silent zero.
	if not _enabled:
		return
	_fallback_recoveries += 1
	_invariant_violations += 1
	var rid := next_record_id()
	_append({
		"telemetry_record_id": rid,
		"timestamp": Time.get_datetime_string_from_system(true),
		"t_msec": Time.get_ticks_msec(),
		"scene": "heal_recovery",
		"context": context,
		"fighter_id": fighter_id,
		"fallback_recovery": true,
		"visibility_invariant_pass": false,
	})
	_persist_counters()


func counters() -> Dictionary:
	return {
		"PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": _select_render_ghosts,
		"PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": _battle_render_ghosts,
		"PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": _invariant_violations,
		"PIXEL_SELECT_VISIBILITY_INVARIANT_VIOLATIONS": _select_invariant_violations,
		"PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS": _battle_invariant_violations,
		"PIXEL_FALLBACK_RECOVERIES": _fallback_recoveries,
		"records": _seq,
	}


func _append(row: Dictionary) -> void:
	# Prefer append-capable open; fall back to create-then-append.
	var f := FileAccess.open(TRACE_PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(TRACE_PATH, FileAccess.WRITE_READ)
	if f == null:
		f = FileAccess.open(TRACE_PATH, FileAccess.WRITE)
		if f:
			f.close()
			f = FileAccess.open(TRACE_PATH, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()


func _persist_counters() -> void:
	var f := FileAccess.open(COUNTERS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(counters()))
	f.close()
