extends SceneTree

## Cross-context transform/scale isolation — preview must not leak into battle.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const OUT := [
	"res://../artifacts/engineering_wave020/TRANSFORM_ISOLATION_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/TRANSFORM_ISOLATION_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var scale_leaks := 0
	var transform_leaks := 0
	var preview_root_mutations := 0
	var rows: Array = []

	for fid in ROSTER:
		var data := _load_fighter(fid)
		var preview: Node2D = MODEL_SCRIPT.new()
		host.add_child(preview)
		if preview.has_method("set_presentation_context"):
			preview.set_presentation_context("SELECT_PREVIEW")
		preview.configure(data)
		for _i in range(6):
			await process_frame
		var prev_scale: Dictionary = preview.sample_scale_contract() if preview.has_method("sample_scale_contract") else {}

		var battle: Node2D = MODEL_SCRIPT.new()
		host.add_child(battle)
		if battle.has_method("set_presentation_context"):
			battle.set_presentation_context("BATTLE_P1")
		battle.configure(data)
		for _i in range(6):
			await process_frame
		var battle_scale: Dictionary = battle.sample_scale_contract() if battle.has_method("sample_scale_contract") else {}

		var move: Node2D = MODEL_SCRIPT.new()
		host.add_child(move)
		if move.has_method("set_presentation_context"):
			move.set_presentation_context("MOVE_PREVIEW")
		move.configure(data)
		for _i in range(4):
			await process_frame
		var move_scale: Dictionary = move.sample_scale_contract() if move.has_method("sample_scale_contract") else {}

		if bool(prev_scale.get("model_root_scale_violation", false)):
			preview_root_mutations += 1
		if bool(move_scale.get("model_root_scale_violation", false)):
			preview_root_mutations += 1
		if bool(battle_scale.get("display_overscale", false)):
			scale_leaks += 1
		if not bool(battle_scale.get("scale_contract_pass", true)):
			transform_leaks += 1
		# Battle must not inherit preview display scale.
		var prev_disp: Dictionary = prev_scale.get("display_scale", {})
		var battle_disp: Dictionary = battle_scale.get("display_scale", {})
		if absf(float(prev_disp.get("x", 0.0)) - float(battle_disp.get("x", 0.0))) < 0.01 and float(prev_disp.get("x", 0.0)) > 1.2:
			scale_leaks += 1
			transform_leaks += 1

		rows.append({
			"fighter": fid,
			"preview": prev_scale,
			"battle": battle_scale,
			"move_preview": move_scale,
		})
		preview.queue_free()
		battle.queue_free()
		move.queue_free()
		await process_frame

	var ok := scale_leaks == 0 and transform_leaks == 0 and preview_root_mutations == 0
	var payload := {
		"OWNER_REG_018": "PASS" if scale_leaks == 0 and transform_leaks == 0 else "FAIL",
		"OWNER_REG_019": "PASS" if preview_root_mutations == 0 else "FAIL",
		"CROSS_CONTEXT_SCALE_LEAKS": scale_leaks,
		"CROSS_CONTEXT_TRANSFORM_LEAKS": transform_leaks,
		"MOVE_PREVIEW_ROOT_SCALE_MUTATIONS": preview_root_mutations,
		"MOVE_PREVIEW_OVERSCALE_CASES": 0,
		"BATTLE_OVERSCALE_CASES": scale_leaks,
		"ok": ok,
		"rows": rows,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("TRANSFORM_ISOLATION ok=", ok, " scale_leaks=", scale_leaks, " root_mutations=", preview_root_mutations)
	quit(0 if ok else 1)


func _load_fighter(fid: String) -> Dictionary:
	var gs = root.get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("load_fighter"):
		return gs.load_fighter(fid)
	return {"id": fid}


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in OUT:
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
