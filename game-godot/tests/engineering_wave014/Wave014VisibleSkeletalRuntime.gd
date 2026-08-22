extends SceneTree

## Wave014 visible skeletal runtime evidence — bone transform deltas on visible skeleton.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const CLIPS := ["idle", "run", "heavy", "aura_charge", "throw_up", "recovery", "signature_lane_burst"]
const BONES := ["Hips", "Chest", "Hand_R", "Hand_L", "Foot_R", "Foot_L"]
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var failures := 0
	var fighters_tested := 0
	var clips_tested := 0
	var fighter_reports: Dictionary = {}
	for fighter_id in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		root.add_child(model)
		var data := _DataLoader.load_fighter(fighter_id)
		if not model.configure(data):
			ok = false
			failures += 1
			fighter_reports[fighter_id] = {"ok": false, "reason": "configure_failed"}
			model.queue_free()
			continue
		fighters_tested += 1
		var clip_reports: Dictionary = {}
		for clip in CLIPS:
			clips_tested += 1
			var move := {"move_id": clip}
			if clip == "signature_lane_burst":
				move = {"move_id": "signature_lane_burst"}
			var state := _state_for_clip(clip)
			var before := _sample(model)
			model.play_for_state(state, move)
			for _i in range(12):
				await process_frame
			var mid := _sample(model)
			for _i in range(12):
				await process_frame
			var after := _sample(model)
			var delta := _max_delta(before, mid) + _max_delta(mid, after)
			var clip_ok: bool = delta > 0.0001 and model.get_active_animation_clip() != ""
			if not clip_ok:
				ok = false
				failures += 1
			clip_reports[clip] = {
				"ok": clip_ok,
				"active_clip": model.get_active_animation_clip(),
				"before": before,
				"mid": mid,
				"after": after,
				"transform_delta": delta,
			}
		var fighter_clip_ok := true
		for clip_name in clip_reports.keys():
			if not bool(clip_reports[clip_name].get("ok", false)):
				fighter_clip_ok = false
		fighter_reports[fighter_id] = {
			"ok": fighter_clip_ok,
			"clips": clip_reports,
			"truth": model.truth_flags(),
		}
		model.queue_free()
		await process_frame

	var result := {
		"ok": ok,
		"FIGHTERS_VISIBLE_SKELETON_TESTED": fighters_tested,
		"VISIBLE_SKELETAL_CLIPS_TESTED_PER_FIGHTER": CLIPS.size(),
		"VISIBLE_SKELETAL_TRANSFORM_FAILURES": failures,
		"fighters": fighter_reports,
	}
	_write_json(result)
	print("Wave014VisibleSkeletalRuntime ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _state_for_clip(clip: String) -> String:
	match clip:
		"run":
			return _FighterStates.RUN
		"heavy":
			return _FighterStates.ATTACK_ACTIVE
		"aura_charge":
			return _FighterStates.AURA_CHARGE
		"throw_up":
			return _FighterStates.THROW_RELEASE
		"recovery":
			return _FighterStates.ATTACK_RECOVERY
		"signature_lane_burst":
			return _FighterStates.SPECIAL_ACTIVE
		_:
			return _FighterStates.IDLE


func _sample(model) -> Dictionary:
	var out := {}
	for bone in BONES:
		if model.has_method("sample_bone_transform"):
			out[bone] = _vec3(model.sample_bone_transform(bone).origin)
	return out


func _vec3(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _max_delta(a: Dictionary, b: Dictionary) -> float:
	var total := 0.0
	for key in a.keys():
		if not b.has(key):
			continue
		var av: Array = a[key]
		var bv: Array = b[key]
		total += Vector3(av[0], av[1], av[2]).distance_to(Vector3(bv[0], bv[1], bv[2]))
	return total


func _write_json(payload: Dictionary) -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	var abs := repo_root.path_join("artifacts/engineering_wave014/VISIBLE_SKELETAL_RUNTIME_RESULT.json")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
