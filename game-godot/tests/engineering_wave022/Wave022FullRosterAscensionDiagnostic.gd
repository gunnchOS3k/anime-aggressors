extends SceneTree

## Wave022 full-roster ascension digital gate — >=30 transform activations per fighter, >=210 total.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATHS := [
	"res://../artifacts/engineering_wave022/FULL_ROSTER_ASCENSION_RESULT.json",
	"../artifacts/engineering_wave022/FULL_ROSTER_ASCENSION_RESULT.json",
]

const ROSTER := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]

const TARGET_PER_FIGHTER := 30
const TARGET_TOTAL := 210

const _FormDefinition = preload("res://scripts/combat/form_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_write({"ok": false, "reason": "GameState missing"})
		quit(1)
		return

	var per_fighter: Dictionary = {}
	var total_activations := 0
	var total_failures := 0
	var total_scale_violations := 0
	var total_form_mismatches := 0

	for fid in ROSTER:
		var result := await _test_fighter(gs, fid)
		per_fighter[fid] = result
		total_activations += int(result.get("TRANSFORM_ACTIVATIONS", 0))
		total_failures += int(result.get("FAILURES", 0))
		total_scale_violations += int(result.get("SCALE_VIOLATIONS", 0))
		total_form_mismatches += int(result.get("FORM_MISMATCHES", 0))

	var ok := (
		total_activations >= TARGET_TOTAL
		and total_failures == 0
		and total_scale_violations == 0
		and total_form_mismatches == 0
	)
	for fid in ROSTER:
		if int(per_fighter[fid].get("TRANSFORM_ACTIVATIONS", 0)) < TARGET_PER_FIGHTER:
			ok = false

	var payload := {
		"ok": ok,
		"OWNER_REG_031": "PASS" if ok else "FAIL",
		"TRANSFORM_ACTIVATIONS_TOTAL": total_activations,
		"TRANSFORM_ACTIVATION_TARGET_TOTAL": TARGET_TOTAL,
		"TRANSFORM_ACTIVATION_TARGET_PER_FIGHTER": TARGET_PER_FIGHTER,
		"FAILURES": total_failures,
		"SCALE_VIOLATIONS": total_scale_violations,
		"FORM_MISMATCHES": total_form_mismatches,
		"FULL_ROSTER_ASCENSION_DESKTOP": "PASS" if ok else "FAIL",
		"per_fighter": per_fighter,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("FULL_ROSTER_ASCENSION ok=", ok, " total=", total_activations)
	quit(0 if ok else 1)


func _clear_battle_scenes() -> void:
	for child in root.get_children():
		if child.name == "BattleScene":
			child.queue_free()
	for _i in range(45):
		await process_frame


func _test_fighter(gs, fighter_id: String) -> Dictionary:
	await _clear_battle_scenes()

	gs.begin_local_versus(false)
	gs.p1_fighter_id = fighter_id
	gs.p2_fighter_id = "ember-vale" if fighter_id != "ember-vale" else "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true

	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(60):
		await process_frame

	var fighter = _find_fighter(scene, fighter_id)
	if fighter == null:
		return {
			"ok": false,
			"TRANSFORM_ACTIVATIONS": 0,
			"FAILURES": TARGET_PER_FIGHTER,
			"SCALE_VIOLATIONS": 0,
			"FORM_MISMATCHES": TARGET_PER_FIGHTER,
		}

	var forms_doc := _FormDefinition.load_forms(fighter_id)
	var base_form: String = str(forms_doc.get("default_form", ""))
	var failures := 0
	var scale_violations := 0
	var form_mismatches := 0
	var activations := 0

	for _i in range(TARGET_PER_FIGHTER):
		fighter.apply_form(base_form)
		fighter.aura = 100.0
		await process_frame
		var before: int = int(fighter.get_transform_activations())
		if fighter.attempt_transform():
			for _t in range(40):
				fighter.tick_transform_pipeline(0.04, false)
				await process_frame
		var after: int = int(fighter.get_transform_activations())
		if after > before:
			activations += 1
		else:
			failures += 1
		var form_id: String = str(fighter.get_current_form_id())
		if form_id.is_empty():
			form_mismatches += 1
		var model = fighter.model_3d
		if model != null and model.has_method("get_body_scale_contract"):
			var sc: Dictionary = model.get_body_scale_contract()
			if float(sc.get("body_scale", 1.0)) > 1.05:
				scale_violations += 1

	scene.queue_free()
	await _clear_battle_scenes()

	return {
		"ok": activations >= TARGET_PER_FIGHTER and failures == 0,
		"TRANSFORM_ACTIVATIONS": activations,
		"FAILURES": failures,
		"SCALE_VIOLATIONS": scale_violations,
		"FORM_MISMATCHES": form_mismatches,
	}


func _find_fighter(scene: Node, fighter_id: String):
	for n in scene.get_tree().get_nodes_in_group("fighters"):
		if "fighter_id" in n and str(n.fighter_id) == fighter_id:
			return n
	return null


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in OUT_PATHS:
		var abs_path := ProjectSettings.globalize_path(p) if str(p).begins_with("res://") else str(p)
		if not abs_path.is_absolute_path():
			abs_path = ProjectSettings.globalize_path("res://../") + abs_path.trim_prefix("../")
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
