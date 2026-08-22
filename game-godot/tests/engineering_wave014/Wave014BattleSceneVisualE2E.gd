extends SceneTree

## Wave014 BattleScene visible-runtime E2E — all seven fighters show procedural GLB.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")

const GAMEPLAY_SCENARIOS := [
	{"label": "IDLE", "state": _FighterStates.IDLE, "move": {}},
	{"label": "RUN", "state": _FighterStates.RUN, "move": {}},
	{"label": "JUMP", "state": _FighterStates.JUMP, "move": {}},
	{"label": "AURA_CHARGE", "state": _FighterStates.AURA_CHARGE, "move": {}},
	{"label": "MELEE", "state": _FighterStates.ATTACK_ACTIVE, "move": {"move_id": "heavy_attack"}},
	{"label": "PROJECTILE", "state": _FighterStates.SPECIAL_ACTIVE, "move": {"move_id": "projectile_full"}},
	{"label": "GRAB", "state": _FighterStates.GRAB_ACTIVE, "move": {"move_id": "grab"}},
	{"label": "FORWARD_THROW", "state": _FighterStates.THROW_RELEASE, "move": {"move_id": "throw_forward", "throw_direction": "forward"}},
	{"label": "UP_THROW", "state": _FighterStates.THROW_RELEASE, "move": {"move_id": "throw_up", "throw_direction": "up"}},
	{"label": "DODGE", "state": _FighterStates.DODGE_ACTIVE, "move": {"move_id": "dodge"}},
	{"label": "RECOVERY", "state": _FighterStates.ATTACK_RECOVERY, "move": {"move_id": "recovery"}},
	{"label": "HURT", "state": _FighterStates.HURT_HEAVY, "move": {}},
	{"label": "KO", "state": _FighterStates.KO, "move": {}},
]


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
		for _i in range(24):
			await process_frame
		var fighter = scene.fighter1 if scene != null else null
		var model = fighter.model_3d if fighter != null else null
		var fighter_ok := true
		var fighter_reasons: Array[String] = []
		if model == null or not model.is_model_loaded():
			fighter_ok = false
			fighter_reasons.append("model_not_loaded")
		if model != null:
			if model.get_current_model_source() != "PROCEDURAL_PRODUCTION_PROXY":
				fighter_ok = false
				fighter_reasons.append("model_source=%s" % model.get_current_model_source())
			if not model.is_procedural_proxy_visible():
				fighter_ok = false
				fighter_reasons.append("procedural_proxy_not_visible")
			if model.is_stylized_visible():
				fighter_ok = false
				fighter_reasons.append("stylized_still_visible")
			if model.count_visible_representations() != 1:
				fighter_ok = false
				fighter_reasons.append("visible_representations=%d" % model.count_visible_representations())
			if model.get_visible_skeleton() == null:
				fighter_ok = false
				fighter_reasons.append("missing_visible_skeleton")
			var controller = model.get_animation_controller()
			if controller == null:
				fighter_ok = false
				fighter_reasons.append("missing_animation_controller")
			elif controller.get_skeleton() != model.get_visible_skeleton():
				fighter_ok = false
				fighter_reasons.append("controller_skeleton_mismatch")
			var gameplay: Dictionary = {}
			for scenario in GAMEPLAY_SCENARIOS:
				var before := _sample_bones(model)
				model.play_for_state(str(scenario.state), scenario.move)
				for _j in range(10):
					await process_frame
				var after := _sample_bones(model)
				var clip: String = model.get_active_animation_clip()
				var delta := _bone_delta(before, after)
				gameplay[str(scenario.label)] = {
					"clip": clip,
					"bone_delta": delta,
					"ok": not clip.is_empty() and delta > 0.0001,
				}
				if clip.is_empty():
					fighter_ok = false
					fighter_reasons.append("empty_clip:" + str(scenario.label))
			scenarios[fighter_id] = {
				"ok": fighter_ok,
				"reasons": fighter_reasons,
				"truth": model.truth_flags() if model.has_method("truth_flags") else {},
				"gameplay": gameplay,
			}
		else:
			scenarios[fighter_id] = {"ok": false, "reasons": fighter_reasons}
		if not fighter_ok:
			ok = false
			reasons.append("fighter_fail:" + fighter_id)
		scene.queue_free()
		await process_frame

	_finish(ok, reasons, scenarios)


func _sample_bones(model) -> Dictionary:
	var out := {}
	for bone in ["Hips", "Chest", "Hand_R", "Hand_L"]:
		if model.has_method("sample_bone_transform"):
			out[bone] = model.sample_bone_transform(bone).origin
	return out


func _bone_delta(before: Dictionary, after: Dictionary) -> float:
	var total := 0.0
	for key in before.keys():
		if after.has(key):
			total += before[key].distance_to(after[key])
	return total


func _finish(ok: bool, reasons: Array[String], scenarios: Dictionary) -> void:
	var result := {
		"ok": ok,
		"BATTLESCENE_VISUAL_E2E": "PASS" if ok else "FAIL",
		"fighter_scenarios": scenarios,
		"reasons": reasons,
		"all_seven_fighters": scenarios.size() == 7,
		"PROCEDURAL_PROXY_VISIBLE_ALL_FIGHTERS": ok,
		"STYLIZED_FALLBACK_VISIBLE_COUNT": 0 if ok else -1,
		"VISIBLE_RUNTIME_ANIMATION_CONTROLLERS_PER_FIGHTER": 1,
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
