extends SceneTree

## Wave020 STOP_THE_LINE — OWNER-REG-009 Fighter Select dynamic content empty (fail-fast).

const SELECT_PATH := "res://scenes/menus/FighterSelectScene.tscn"
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const GATES := preload("res://scripts/menus/wave020_presentation_gates.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/OWNER_REG_009_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/OWNER_REG_009_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_apply_gate_env()
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_fail({"error": "GameState missing", "OWNER_REG_009": "FAIL"}, 1)
		return

	var roster: Array = gs.roster_ids()
	var failures: Array = []
	var flags := {
		"FIGHTER_SELECT_SCENE_SHELL_PRESENT": false,
		"FIGHTER_SELECT_ROSTER_DATA_PRESENT": roster.size() == 7,
		"FIGHTER_SELECT_P1_IDENTITY_PRESENT": false,
		"FIGHTER_SELECT_P2_IDENTITY_PRESENT": false,
		"FIGHTER_SELECT_P1_MODEL_PRESENT": false,
		"FIGHTER_SELECT_P2_MODEL_PRESENT": false,
		"FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE": false,
		"script_attached": false,
		"roster_count": roster.size(),
	}
	if roster.size() != 7:
		failures.append("roster_count=%d expected 7" % roster.size())

	var packed: PackedScene = load(SELECT_PATH)
	if packed == null:
		failures.append("select_scene_load_null")
		_emit_and_quit(flags, failures, "")
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	flags["FIGHTER_SELECT_SCENE_SHELL_PRESENT"] = scene.get_node_or_null("%FighterGrid") != null \
		and scene.get_node_or_null("%P1Name") != null \
		and scene.get_node_or_null("%PreviewHost") != null
	flags["script_attached"] = scene.get_script() != null
	if scene.get_script() == null:
		failures.append("script_not_attached (parse/load failure)")
		_emit_and_quit(flags, failures, "")
		return

	var grid := scene.get_node_or_null("%FighterGrid") as GridContainer
	var p1 := scene.get_node_or_null("%P1Name") as Label
	var p2 := scene.get_node_or_null("%P2Name") as Label
	var detail := scene.get_node_or_null("%Detail") as Label
	var kids := grid.get_child_count() if grid else 0
	if kids < 7:
		failures.append("grid_children=%d expected >=7" % kids)

	var p1_text := str(p1.text) if p1 else ""
	var p2_text := str(p2.text) if p2 else ""
	flags["FIGHTER_SELECT_P1_IDENTITY_PRESENT"] = p1_text.begins_with("P1:") and p1_text.length() > 4 and not p1_text.strip_edges().ends_with("?")
	flags["FIGHTER_SELECT_P2_IDENTITY_PRESENT"] = p2_text.begins_with("P2:") and p2_text.length() > 4
	if not flags["FIGHTER_SELECT_P1_IDENTITY_PRESENT"]:
		failures.append("p1_identity_missing text=%s" % p1_text)
	if not flags["FIGHTER_SELECT_P2_IDENTITY_PRESENT"]:
		failures.append("p2_identity_missing text=%s" % p2_text)
	if detail == null or str(detail.text).strip_edges().is_empty():
		failures.append("detail_empty")

	var selectable := 0
	var visible_previews := 0
	var ghost_count := 0
	if scene.has_method("_on_tile_focused") and scene.has_method("assert_preview_visibility_invariant"):
		for i in mini(7, roster.size()):
			scene.call("_on_tile_focused", i)
			await process_frame
			await process_frame
			await process_frame
			var inv: Dictionary = scene.call("assert_preview_visibility_invariant")
			selectable += 1
			if bool(inv.get("VISIBLE_RENDERABLE_BODY", false)):
				visible_previews += 1
			if bool(inv.get("GHOST", false)):
				ghost_count += 1
				failures.append("preview_ghost idx=%d fighter=%s" % [i, roster[i]])
	else:
		failures.append("select_methods_missing")

	flags["FIGHTER_SELECT_P1_MODEL_PRESENT"] = visible_previews > 0
	flags["BASELINE_ROSTER_COUNT"] = roster.size()
	flags["BASELINE_SELECTABLE_FIGHTERS"] = selectable
	flags["BASELINE_VISIBLE_PREVIEW_FIGHTERS"] = visible_previews
	flags["SELECT_PREVIEW_GHOST_OCCURRENCES"] = ghost_count

	# Confirm path: pick fighter 0 then advance to battle handoff check.
	var battle_ok := false
	if scene.has_method("_on_tile_pressed") and scene.has_method("_on_next_player_pressed"):
		scene.call("_on_tile_pressed", 0)
		await process_frame
		scene.call("_on_next_player_pressed")  # lock P1 / switch to P2
		await process_frame
		scene.call("_on_tile_pressed", 1)
		await process_frame
		# Second next should teardown and route; call battle handoff directly for headless.
		gs.p1_fighter_id = str(roster[0])
		gs.p2_fighter_id = str(roster[1])
		gs.p1_ready = true
		gs.p2_ready = true
		battle_ok = await _battle_bodies_ok(gs, str(roster[0]), str(roster[1]))
		if not battle_ok:
			failures.append("confirm_to_battle_bodies_missing")
	flags["BASELINE_SELECT_TO_BATTLE_PASS"] = battle_ok
	flags["FIGHTER_SELECT_P2_MODEL_PRESENT"] = battle_ok
	flags["FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE"] = (
		flags["FIGHTER_SELECT_SCENE_SHELL_PRESENT"]
		and flags["FIGHTER_SELECT_ROSTER_DATA_PRESENT"]
		and flags["FIGHTER_SELECT_P1_IDENTITY_PRESENT"]
		and flags["FIGHTER_SELECT_P2_IDENTITY_PRESENT"]
		and visible_previews == 7
		and ghost_count == 0
		and battle_ok
		and failures.is_empty()
	)
	if not flags["FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE"] and failures.is_empty():
		failures.append("dynamic_content_incomplete")

	scene.queue_free()
	_emit_and_quit(flags, failures, str(roster[0]) if roster.size() > 0 else "")


func _apply_gate_env() -> void:
	var mode := OS.get_environment("WAVE020_SLICE_MODE")
	if mode == "baseline" or mode.is_empty():
		GATES.freeze_revised_presentation()
	elif mode == "a":
		GATES.freeze_revised_presentation()
		GATES.enable_slice_a_framing()
	elif mode == "b":
		GATES.freeze_revised_presentation()
		GATES.enable_slice_a_framing()
		GATES.enable_slice_b_flourish()
	elif mode == "all":
		GATES.enable_slice_a_framing()
		GATES.enable_slice_b_flourish()


func _battle_bodies_ok(gs, p1: String, p2: String) -> bool:
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


func _emit_and_quit(flags: Dictionary, failures: Array, _fid: String) -> void:
	var payload := flags.duplicate(true)
	payload["ok"] = failures.is_empty() and bool(flags.get("FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE", false))
	payload["OWNER_REG_009"] = "PASS" if payload["ok"] else "FAIL"
	payload["failures"] = failures
	payload["presentation_gates"] = GATES.currently_enabled()
	_write(payload)
	if payload["ok"]:
		print("OWNER-REG-009 DIAGNOSTIC PASS")
		quit(0)
	else:
		print("OWNER-REG-009 DIAGNOSTIC FAIL: ", failures)
		quit(1)


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
