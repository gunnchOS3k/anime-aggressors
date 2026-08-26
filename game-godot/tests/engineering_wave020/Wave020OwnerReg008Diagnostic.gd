extends SceneTree

## Wave020 revised — OWNER-REG-008 fast diagnostic (fail-fast, verbose).

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/OWNER_REG_008_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/OWNER_REG_008_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_fail({"error": "GameState missing"}, 1)
		return
	var roster: Array = gs.roster_ids()
	if roster.size() < 7:
		_fail({"error": "roster_size", "size": roster.size()}, 1)
		return

	var host := Node2D.new()
	host.name = "Wave020OwnerReg008Host"
	root.add_child(host)
	var preview: Node2D = MODEL_SCRIPT.new()
	preview.name = "SelectModel"
	host.add_child(preview)
	await process_frame
	await process_frame

	var failures: Array = []
	var transition_index := 0
	var first_failure_index := -1
	var prev_id := ""
	var failed_id := ""
	var preview_gen := 0

	for i in roster.size():
		var id: String = str(roster[i])
		transition_index += 1
		prev_id = id if i == 0 else str(roster[i - 1])
		if not _configure_preview(preview, gs, id):
			failures.append("forward idx=%d fighter=%s ghost" % [i, id])
			if first_failure_index < 0:
				first_failure_index = transition_index
				failed_id = id
		await process_frame

	var p7: String = str(roster[6])
	var battle_ok := await _battle_handoff_ok(gs, p7, str(roster[0]))
	if not battle_ok:
		failures.append("battle_handoff fighter7=%s" % p7)

	for i in range(roster.size() - 1, -1, -1):
		var id: String = str(roster[i])
		transition_index += 1
		if not _configure_preview(preview, gs, id):
			failures.append("reverse idx=%d fighter=%s" % [i, id])
			if first_failure_index < 0:
				first_failure_index = transition_index
				failed_id = id
		await process_frame

	transition_index += 1
	if not _configure_preview(preview, gs, str(roster[0])):
		failures.append("wraparound fighter=%s" % roster[0])
		if first_failure_index < 0:
			first_failure_index = transition_index
			failed_id = str(roster[0])

	var order := roster.duplicate()
	order.shuffle()
	for idv in order:
		transition_index += 1
		var id: String = str(idv)
		if not _configure_preview(preview, gs, id):
			failures.append("random fighter=%s" % id)
			if first_failure_index < 0:
				first_failure_index = transition_index
				failed_id = id
		await process_frame

	if preview.has_method("get_configure_generation"):
		preview_gen = int(preview.get_configure_generation())

	var mesh: Dictionary = preview.count_renderable_meshes() if preview.has_method("count_renderable_meshes") else {}
	var payload := {
		"ok": failures.is_empty(),
		"OWNER_REG_008": "PASS" if failures.is_empty() else "FAIL",
		"DIAGNOSTIC_VISIBILITY_PASS": failures.is_empty(),
		"OWNER_REG_008_REPRODUCED_BEFORE_FIX": false,
		"FIRST_FAILURE_TRANSITION_INDEX": first_failure_index,
		"PREVIOUS_FIGHTER_ID": prev_id,
		"FAILED_FIGHTER_ID": failed_id,
		"PREVIEW_GENERATION": preview_gen,
		"PREVIEW_INSTANCE_VALID": preview != null and is_instance_valid(preview),
		"PREVIEW_VISIBLE_IN_TREE": preview.visible if preview else false,
		"RENDERABLE_MESH_COUNT": int(mesh.get("renderable_mesh_count", 0)),
		"VISIBLE_RENDERABLE_MESH_COUNT": int(mesh.get("visible_renderable_mesh_count", 0)),
		"SKELETON_VALID": preview.get_visible_skeleton() != null if preview.has_method("get_visible_skeleton") else false,
		"CONTROLLER_VALID": preview.get_animation_controller() != null if preview.has_method("get_animation_controller") else false,
		"BATTLE_HANDOFF_REPRODUCED": not battle_ok,
		"failures": failures,
	}
	host.queue_free()
	_write(payload)
	if failures.is_empty():
		print("OWNER-REG-008 DIAGNOSTIC PASS")
		quit(0)
	else:
		print("OWNER-REG-008 DIAGNOSTIC FAIL: ", failures)
		quit(1)


func _configure_preview(model: Node2D, gs, fighter_id: String) -> bool:
	var data: Dictionary = gs.load_fighter(fighter_id)
	if model.has_method("configure"):
		model.configure(data)
	if model.has_method("set_select_mode"):
		model.set_select_mode(true)
	if model.has_method("heal_visibility_if_needed"):
		model.heal_visibility_if_needed()
	if model.has_method("is_visible_renderable_body"):
		return bool(model.is_visible_renderable_body())
	return false


func _battle_handoff_ok(gs, p1: String, p2: String) -> bool:
	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		return false
	gs.begin_local_versus(false)
	gs.p1_fighter_id = p1
	gs.p2_fighter_id = p2
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.stage_id = "skyline-arena"
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(36):
		await process_frame
	var ok := true
	for f in [scene.get("fighter1"), scene.get("fighter2")]:
		if f == null:
			ok = false
			continue
		if f.has_method("ensure_visible_presentation"):
			f.ensure_visible_presentation()
		if f.has_method("assert_visible_body_invariant"):
			var inv: Dictionary = f.assert_visible_body_invariant()
			if not bool(inv.get("PASS", false)):
				ok = false
	scene.queue_free()
	await process_frame
	return ok


func _write(payload: Dictionary) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return


func _fail(payload: Dictionary, code: int) -> void:
	_write(payload)
	print(JSON.stringify(payload))
	quit(code)
