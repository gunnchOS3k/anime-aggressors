extends SceneTree

## Generic Wave014-class discovery. Uses ACTIVE_CHARACTER_PRESENTATION.

const FALLBACK := ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx"]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var resolver = load("res://scripts/visual/fighter_asset_resolver.gd")
	var ok := resolver != null
	var reasons: Array = []
	var rows: Array = []
	if resolver:
		for fid in FALLBACK:
			var model: Dictionary = resolver.resolve_model_path(fid, {"id": fid})
			var presentation := str(model.get("ACTIVE_CHARACTER_PRESENTATION", model.get("CURRENT_MODEL_SOURCE", "")))
			var path := str(model.get("path", ""))
			var generated := path.contains("generated_production") or path.contains("generated_art")
			var staging := path.contains("human_art_staging")
			if presentation == "":
				ok = false
				reasons.append("%s:missing_ACTIVE_CHARACTER_PRESENTATION" % fid)
			if generated:
				ok = false
				reasons.append("%s:generated_path_selected" % fid)
			if staging:
				ok = false
				reasons.append("%s:staging_selected_with_flag_off" % fid)
			rows.append({"fighter_id": fid, "ACTIVE_CHARACTER_PRESENTATION": presentation, "path": path})
	var result := {
		"ok": ok,
		"reasons": reasons,
		"roster": rows,
		"ART_RUNTIME_DISCOVERY_PASS": ok,
	}
	var f := FileAccess.open("res://../artifacts/art_pipeline/GODOT_RUNTIME_DISCOVERY.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "\t"))
		f.close()
	print(JSON.stringify(result))
	quit(0 if ok else 1)
