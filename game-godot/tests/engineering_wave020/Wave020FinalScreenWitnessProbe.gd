extends SceneTree

## Wave020 CP2 reopen — SCENE_TREE vs FINAL_SCREEN witness for Vesper vs Kaia.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var Model = load("res://scripts/fighters/fighter_model_3d.gd")
	if Model == null:
		push_error("FAILED_LOAD fighter_model_3d.gd")
		quit(3)
		return
	var Data = load("res://scripts/data/data_loader.gd")
	var host := Node2D.new()
	host.name = "WitnessHost"
	root.add_child(host)
	var cam := Camera2D.new()
	cam.enabled = true
	host.add_child(cam)
	cam.make_current()
	cam.position = Vector2(0, 120)
	cam.zoom = Vector2(1.2, 1.2)
	await process_frame

	var rows: Array = []
	for pair in [["vesper-nyx", Vector2(-180, 200)], ["kaia-windrow", Vector2(180, 200)]]:
		var fid := str(pair[0])
		var pos: Vector2 = pair[1]
		var model: Node2D = Model.new()
		model.name = "Model_%s" % fid
		model.position = pos
		host.add_child(model)
		var data: Dictionary = Data.load_fighter(fid)
		var configured: bool = bool(model.configure(data))
		if model.has_method("set_select_mode"):
			model.set_select_mode(false)
		for _i in range(10):
			await process_frame
		if model.has_method("refresh_viewport_texture"):
			model.refresh_viewport_texture(true)
		await process_frame
		await process_frame
		var witness: Dictionary = {}
		if model.has_method("get_final_screen_visibility_witness"):
			witness = model.get_final_screen_visibility_witness()
		else:
			witness = {"SCENE_TREE_VISIBLE": false, "FINAL_SCREEN_VISIBLE": false, "invisible_failure_class": "NO_WITNESS_API"}
		witness["fighter_id"] = fid
		witness["configure_ok"] = configured
		witness["position"] = {"x": pos.x, "y": pos.y}
		rows.append(witness)
		print(
			"WITNESS fighter=", fid,
			" scene_tree=", witness.get("SCENE_TREE_VISIBLE"),
			" final_screen=", witness.get("FINAL_SCREEN_VISIBLE"),
			" opaque=", witness.get("viewport_opaque_pixels"),
			" path=", witness.get("display_path"),
			" failure=", witness.get("invisible_failure_class", "")
		)

	var out := {
		"probe": "Wave020FinalScreenWitnessProbe",
		"pair": "vesper-nyx_vs_kaia-windrow",
		"rows": rows,
		"any_final_screen_fail": false,
	}
	for r in rows:
		if not bool(r.get("FINAL_SCREEN_VISIBLE", false)) and bool(r.get("FINAL_SCREEN_WITNESS_AVAILABLE", true)):
			out["any_final_screen_fail"] = true
		if not bool(r.get("FINAL_SCREEN_WITNESS_AVAILABLE", true)):
			out["headless_witness_unavailable"] = true
	_write(out)
	quit(0)


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in [
		"res://../artifacts/engineering_wave020/CP2_VESPER_KAIA_FINAL_SCREEN_PROBE.json",
		"../artifacts/engineering_wave020/CP2_VESPER_KAIA_FINAL_SCREEN_PROBE.json",
	]:
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
			print("Wrote ", p)
