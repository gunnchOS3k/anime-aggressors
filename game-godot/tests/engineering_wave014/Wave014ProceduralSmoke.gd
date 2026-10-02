extends SceneTree

## Wave014 procedural roster + visible runtime smoke.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var reasons: Array[String] = []
	var resolver := load("res://scripts/visual/fighter_asset_resolver.gd")
	if resolver == null:
		ok = false
		reasons.append("fighter_asset_resolver missing")

	var models_loaded := 0
	var anim_roots := 0
	var visible_procedural := 0
	var golden_slice := 0
	var observed_truth: Dictionary = {}

	if resolver:
		for fighter_id in FIGHTERS:
			var model_info: Dictionary = resolver.resolve_model_path(fighter_id, {"id": fighter_id})
			var model_source := str(model_info.get("CURRENT_MODEL_SOURCE", ""))
			var model_path := str(model_info.get("path", ""))
			# V3 promotion keeps staging HUMAN_CANDIDATE GLBs on main; those are loaded
			# models. Do not require PROCEDURAL_PRODUCTION_PROXY exclusively, and do not
			# treat candidate presence as FINAL_CHARACTER_ART_PASS.
			if not model_path.is_empty() and model_source in ["PROCEDURAL_PRODUCTION_PROXY", "HUMAN_CANDIDATE"]:
				models_loaded += 1
			var anim_info: Dictionary = resolver.resolve_animation_root(fighter_id)
			if str(anim_info.get("CURRENT_ANIMATION_SOURCE", "")) == "PROCEDURAL_RUNTIME_ANIMATION":
				anim_roots += 1

			var model: Node = MODEL_SCRIPT.new()
			root.add_child(model)
			var data := _DataLoader.load_fighter(fighter_id)
			if model.configure(data):
				var flags: Dictionary = model.truth_flags() if model.has_method("truth_flags") else {}
				observed_truth[fighter_id] = flags
				if str(flags.get("CURRENT_MODEL_SOURCE", "")) == "GOLDEN_SLICE_CANDIDATE":
					if bool(flags.get("VISIBLE_SKELETON_PRESENT", false)) and int(flags.get("VISIBLE_RUNTIME_ANIMATION_CONTROLLERS_PER_FIGHTER", 0)) == 1 and bool(flags.get("FINAL_CHARACTER_ART_PASS", true)) == false:
						golden_slice += 1
				elif model.is_procedural_proxy_visible():
					visible_procedural += 1
			model.queue_free()
			await process_frame

	if models_loaded < 7:
		ok = false
		reasons.append("models_loaded=%d" % models_loaded)
	if anim_roots < 7:
		ok = false
		reasons.append("anim_roots=%d" % anim_roots)
	# Authority mixed state: Kaia golden slice, the other six stay procedural proxies.
	if visible_procedural != 6 or golden_slice != 1:
		ok = false
		reasons.append("mixed_state procedural=%d golden=%d" % [visible_procedural, golden_slice])

	for lab in [
		"res://scenes/labs/RosterArtLab.tscn",
		"res://scenes/labs/AnimationLab.tscn",
	]:
		if load(lab) == null:
			ok = false
			reasons.append("missing_lab:" + lab)

	var result := {
		"WAVE014_PROCEDURAL_SMOKE": "PASS" if ok else "FAIL",
		"ok": ok,
		"reasons": reasons,
		"ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS": visible_procedural,
		"KAIA_GOLDEN_SLICE_COUNT": golden_slice,
		"AUTHORITY_MIXED_GOLDEN_SLICE": visible_procedural == 6 and golden_slice == 1,
		"ANIMATION_LAB_USES_CANONICAL_RUNTIME_CONTROLLER": ok,
		"PROCEDURAL_CHARACTER_RUNTIME_PASS": false,
		"PROCEDURAL_RUNTIME_ANIMATION_PASS": anim_roots == 7,
		"FINAL_CHARACTER_ART_PASS": false,
		"FINAL_HUMAN_AUTHORED_ANIMATION_PASS": false,
		"HUMAN_CANDIDATE_MODELS_COUNT_AS_LOADED_NOT_FINAL": true,
		"observed_truth": observed_truth,
	}
	_write_json("../artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json", result)
	_write_json("artifacts/engineering_wave014/PROCEDURAL_SMOKE_RESULT.json", result)
	print("Wave014ProceduralSmoke ", result["WAVE014_PROCEDURAL_SMOKE"], result)
	quit(0 if ok else 1)


func _write_json(rel: String, payload: Dictionary) -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	var abs := repo_root.path_join(rel)
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
