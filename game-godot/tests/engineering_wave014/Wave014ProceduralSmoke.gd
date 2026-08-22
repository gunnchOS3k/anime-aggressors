extends SceneTree

## Wave014 procedural roster + animation runtime smoke.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

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
	if resolver:
		for fighter_id in FIGHTERS:
			var model_info: Dictionary = resolver.resolve_model_path(fighter_id, {"id": fighter_id})
			if str(model_info.get("CURRENT_MODEL_SOURCE", "")) == "PROCEDURAL_PRODUCTION_PROXY":
				models_loaded += 1
			var anim_info: Dictionary = resolver.resolve_animation_root(fighter_id)
			if str(anim_info.get("CURRENT_ANIMATION_SOURCE", "")) == "PROCEDURAL_RUNTIME_ANIMATION":
				anim_roots += 1

	if models_loaded < 7:
		ok = false
		reasons.append("models_loaded=%d" % models_loaded)
	if anim_roots < 7:
		ok = false
		reasons.append("anim_roots=%d" % anim_roots)

	for lab in [
		"res://scenes/labs/RosterArtLab.tscn",
		"res://scenes/labs/AnimationLab.tscn",
	]:
		if load(lab) == null:
			ok = false
			reasons.append("missing_lab:" + lab)

	var truth: Dictionary = resolver.truth_flags() if resolver else {}
	var result := {
		"WAVE014_PROCEDURAL_SMOKE": "PASS" if ok else "FAIL",
		"ok": ok,
		"reasons": reasons,
		"ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS": models_loaded,
		"PROCEDURAL_CHARACTER_RUNTIME_PASS": truth.get("PROCEDURAL_CHARACTER_RUNTIME_PASS", false),
		"PROCEDURAL_RUNTIME_ANIMATION_PASS": truth.get("PROCEDURAL_RUNTIME_ANIMATION_PASS", false),
		"FINAL_CHARACTER_ART_PASS": false,
		"FINAL_HUMAN_AUTHORED_ANIMATION_PASS": false,
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
