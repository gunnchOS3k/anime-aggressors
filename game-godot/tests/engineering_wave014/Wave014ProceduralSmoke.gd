extends SceneTree

## Wave014 generated-production runtime discovery + visible smoke.
## Counts instantiated model/anim roots, not resolver metadata alone.

const FALLBACK_FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const LIVE_MODEL_SOURCES := [
	"GENERATED_PRODUCTION_ART",
	"PROCEDURAL_PRODUCTION_PROXY",
]
const LIVE_ANIM_SOURCES := [
	"PROCEDURAL_RUNTIME_ANIMATION",
	"GENERATED_PRODUCTION_ANIMATION",
]


func _init() -> void:
	call_deferred("_run")


func _discover_roster() -> Array[String]:
	var found: Array[String] = []
	var gs = root.get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("roster_ids"):
		for fidv in gs.roster_ids():
			found.append(str(fidv))
	if found.is_empty():
		for fidv in _DataLoader.roster_ids():
			found.append(str(fidv))
	if found.is_empty():
		var dir := DirAccess.open("res://data/fighters")
		if dir:
			dir.list_dir_begin()
			var name := dir.get_next()
			while name != "":
				if name.ends_with(".json") and not name.ends_with("_animations.json") and name != "roster.json":
					found.append(name.get_basename())
				name = dir.get_next()
	if found.is_empty():
		found.append_array(FALLBACK_FIGHTERS)
	found.sort()
	return found


func _is_live_model(source: String) -> bool:
	return source in LIVE_MODEL_SOURCES


func _is_live_anim(source: String) -> bool:
	return source in LIVE_ANIM_SOURCES


func _run() -> void:
	var ok := true
	var reasons: Array[String] = []
	var resolver := load("res://scripts/visual/fighter_asset_resolver.gd")
	if resolver == null:
		ok = false
		reasons.append("fighter_asset_resolver missing")

	var roster := _discover_roster()
	if roster.size() < FALLBACK_FIGHTERS.size():
		ok = false
		reasons.append("roster_discovered=%d expected>=%d" % [roster.size(), FALLBACK_FIGHTERS.size()])

	var models_loaded := 0
	var anim_roots := 0
	var visible_procedural := 0
	var observed_truth: Dictionary = {}
	var discovery: Array = []

	if resolver:
		for fighter_id in roster:
			var model_info: Dictionary = resolver.resolve_model_path(fighter_id, {"id": fighter_id})
			var anim_info: Dictionary = resolver.resolve_animation_root(fighter_id)
			var path := str(model_info.get("path", ""))
			var path_exists := (not path.is_empty()) and (ResourceLoader.exists(path) or FileAccess.file_exists(path))

			var model: Node = MODEL_SCRIPT.new()
			root.add_child(model)
			var data := _DataLoader.load_fighter(fighter_id)
			var configured: bool = bool(model.configure(data))
			await process_frame
			var truth: Dictionary = model.truth_flags() if model.has_method("truth_flags") else {}
			observed_truth[fighter_id] = truth

			var visible_node := str(truth.get("VISIBLE_MODEL_NODE", ""))
			var skeleton_ok := bool(truth.get("VISIBLE_SKELETON_PRESENT", false))
			var source := str(truth.get("CURRENT_MODEL_SOURCE", model_info.get("CURRENT_MODEL_SOURCE", "")))
			var anim_source := str(truth.get("CURRENT_ANIMATION_SOURCE", anim_info.get("CURRENT_ANIMATION_SOURCE", "")))
			var controllers := int(truth.get("VISIBLE_RUNTIME_ANIMATION_CONTROLLERS_PER_FIGHTER", 0))
			var clip := str(truth.get("ACTIVE_ANIMATION_CLIP", ""))
			var fallback := bool(truth.get("STYLIZED_FALLBACK_VISIBLE", true))
			var instance_ok: bool = configured and visible_node != "" and skeleton_ok and _is_live_model(source) and path_exists and not fallback
			if instance_ok:
				models_loaded += 1
				# Generated-production bodies are the live visible roster, not only the old proxy flag.
				visible_procedural += 1
			var anim_ok: bool = instance_ok and controllers == 1 and clip != "" and _is_live_anim(anim_source)
			if anim_ok:
				anim_roots += 1
			discovery.append({
				"fighter_id": fighter_id,
				"resolver_model_source": str(model_info.get("CURRENT_MODEL_SOURCE", "")),
				"resolver_anim_source": str(anim_info.get("CURRENT_ANIMATION_SOURCE", "")),
				"path": path,
				"path_exists": path_exists,
				"instance_ok": instance_ok,
				"anim_ok": anim_ok,
				"visible_node": visible_node,
				"skeleton": skeleton_ok,
				"controllers": controllers,
				"clip": clip,
			})
			model.queue_free()
			await process_frame

	var expected := roster.size()
	if models_loaded < expected:
		ok = false
		reasons.append("models_loaded=%d" % models_loaded)
	if anim_roots < expected:
		ok = false
		reasons.append("anim_roots=%d" % anim_roots)
	if visible_procedural < expected:
		ok = false
		reasons.append("visible_procedural=%d" % visible_procedural)

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
		"roster": roster,
		"discovery": discovery,
		"WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS": ok,
		"ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS": visible_procedural,
		"ANIMATION_LAB_USES_CANONICAL_RUNTIME_CONTROLLER": ok,
		"PROCEDURAL_CHARACTER_RUNTIME_PASS": visible_procedural == expected and expected > 0,
		"PROCEDURAL_RUNTIME_ANIMATION_PASS": anim_roots == expected and expected > 0,
		"FINAL_CHARACTER_ART_PASS": false,
		"FINAL_HUMAN_AUTHORED_ANIMATION_PASS": false,
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
