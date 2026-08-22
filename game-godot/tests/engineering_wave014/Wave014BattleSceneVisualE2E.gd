extends SceneTree

## Wave014 BattleScene visual E2E — all seven fighters load procedural presentation layer.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var reasons: Array[String] = []
	var scenarios: Dictionary = {}
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		ok = false
		reasons.append("GameState missing")
		_finish(ok, reasons, scenarios)
		return

	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		ok = false
		reasons.append("BattleScene missing")
		_finish(ok, reasons, scenarios)
		return

	for fighter_id in FIGHTERS:
		gs.begin_local_versus(false)
		gs.p1_fighter_id = fighter_id
		gs.p2_fighter_id = "ember-vale" if fighter_id != "ember-vale" else "rook-ironside"
		gs.p1_is_cpu = true
		gs.p2_is_cpu = true
		gs.battle_eval_mode = false
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		for _i in range(20):
			await process_frame
		var p1 = scene.fighter1 if scene != null else null
		var loaded: bool = p1 != null and p1.has_method("is_model_loaded") and p1.is_model_loaded()
		scenarios[fighter_id] = loaded
		if not loaded:
			ok = false
			reasons.append("fighter_not_loaded:" + fighter_id)
		scene.queue_free()
		await process_frame

	_finish(ok, reasons, scenarios)


func _finish(ok: bool, reasons: Array[String], scenarios: Dictionary) -> void:
	var result := {
		"ok": ok,
		"BATTLESCENE_VISUAL_E2E": "PASS" if ok else "FAIL",
		"fighter_scenarios": scenarios,
		"reasons": reasons,
		"all_seven_fighters": scenarios.size() == 7,
	}
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	var abs := repo_root.path_join("artifacts/engineering_wave014/BATTLESCENE_VISUAL_E2E.json")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "\t"))
		f.close()
	print("Wave014BattleSceneVisualE2E ", result["BATTLESCENE_VISUAL_E2E"])
	quit(0 if ok else 1)
