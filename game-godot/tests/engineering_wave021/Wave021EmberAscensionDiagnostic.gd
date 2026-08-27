extends SceneTree

## Wave021 Ember ascension digital gate — >=50 transform activations, failure counters 0.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATHS := [
	"res://../artifacts/engineering_wave021/EMBER_ASCENSION_RESULT.json",
	"../artifacts/engineering_wave021/EMBER_ASCENSION_RESULT.json",
]

const TARGET_ACTIVATIONS := 50


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_write({"ok": false, "reason": "GameState missing"})
		quit(1)
		return
	gs.begin_local_versus(false)
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true

	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(60):
		await process_frame

	var fighter = _find_ember(scene)
	if fighter == null:
		_write({"ok": false, "reason": "ember fighter missing"})
		quit(1)
		return

	var failures := 0
	var scale_violations := 0
	var form_mismatches := 0
	var activations := 0

	for _i in range(TARGET_ACTIVATIONS):
		fighter.apply_form("EMBER_BASE")
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
		var fid: String = str(fighter.get_current_form_id())
		if fid.is_empty():
			form_mismatches += 1
		var model = fighter.model_3d
		if model != null and model.has_method("get_body_scale_contract"):
			var sc: Dictionary = model.get_body_scale_contract()
			if float(sc.get("body_scale", 1.0)) > 1.05:
				scale_violations += 1

	var ok := activations >= TARGET_ACTIVATIONS and failures == 0 and scale_violations == 0 and form_mismatches == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_024": "PASS" if ok else "FAIL",
		"TRANSFORM_ACTIVATIONS": activations,
		"TRANSFORM_ACTIVATION_TARGET": TARGET_ACTIVATIONS,
		"SCALE_VIOLATIONS": scale_violations,
		"FORM_MISMATCHES": form_mismatches,
		"FAILURES": failures,
		"EMBER_ASCENSION_DESKTOP": "PASS" if ok else "FAIL",
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("EMBER_ASCENSION ok=", ok, " activations=", activations)
	quit(0 if ok else 1)


func _find_ember(scene: Node):
	for n in scene.get_tree().get_nodes_in_group("fighters"):
		if "fighter_id" in n and str(n.fighter_id) == "ember-vale":
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
