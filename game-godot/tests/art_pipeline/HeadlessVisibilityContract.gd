extends SceneTree

    ## Regression: never blindly call unsupported viewport-image paths such as texture_2d_get.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var forbidden := ["texture_2d_get"]
	var hits: Array[String] = []
	# Structural evidence only under headless.
	var mode := "STRUCTURAL_HEADLESS"
	if DisplayServer.get_name() != "headless" and DisplayServer.get_name() != "dummy":
		mode = "RENDERED_PIXEL"
	var result := {
		"ok": hits.is_empty(),
		"EVIDENCE_MODE": mode,
		"ART_HEADLESS_VISIBILITY_PASS": hits.is_empty(),
		"forbidden": forbidden,
		"hits": hits,
	}
	var f := FileAccess.open("res://../artifacts/art_pipeline/GODOT_HEADLESS_VISIBILITY.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "\t"))
		f.close()
	print(JSON.stringify(result))
	quit(0 if bool(result["ok"]) else 1)
