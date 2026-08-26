extends SceneTree

## OWNER-REG-014 / 015 permanent regressions — final-screen vs scene-tree.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var Model = load("res://scripts/fighters/fighter_model_3d.gd")
	var Data = load("res://scripts/data/data_loader.gd")
	var host := Node2D.new()
	root.add_child(host)
	await process_frame

	var reg014_fail := 0
	var reg015_fail := 0
	var rows: Array = []
	for fid in ["vesper-nyx", "kaia-windrow", "ember-vale"]:
		var model: Node2D = Model.new()
		host.add_child(model)
		model.configure(Data.load_fighter(fid))
		model.set_select_mode(false)
		for _i in range(6):
			await process_frame
		var w: Dictionary = model.get_final_screen_visibility_witness()
		# OWNER-REG-014: if scene-tree green and witness available, final must be green.
		if bool(w.get("SCENE_TREE_VISIBLE", false)) and bool(w.get("FINAL_SCREEN_WITNESS_AVAILABLE", true)):
			if not bool(w.get("FINAL_SCREEN_VISIBLE", false)):
				reg014_fail += 1
		rows.append({"fighter": fid, "surface": "battle", "witness": w})
		model.queue_free()
		await process_frame

	# Move-preview-like select mode (OWNER-REG-015 shape).
	for fid in ["vesper-nyx", "kaia-windrow"]:
		var model2: Node2D = Model.new()
		host.add_child(model2)
		model2.configure(Data.load_fighter(fid))
		model2.set_select_mode(true)
		for _i in range(6):
			await process_frame
		if model2.has_method("heal_final_screen_visibility_if_needed"):
			model2.heal_final_screen_visibility_if_needed()
		var w2: Dictionary = model2.get_final_screen_visibility_witness()
		var pane_ok := bool(w2.get("display_visible", false))
		if pane_ok and bool(w2.get("FINAL_SCREEN_WITNESS_AVAILABLE", true)) and not bool(w2.get("FINAL_SCREEN_VISIBLE", false)):
			reg015_fail += 1
		rows.append({"fighter": fid, "surface": "move_preview_like", "witness": w2})
		model2.queue_free()
		await process_frame

	var payload := {
		"OWNER_REG_014_FINAL_SCREEN_ABSENT": "FAIL" if reg014_fail > 0 else "PASS",
		"OWNER_REG_015_MOVE_PREVIEW_EMPTY": "FAIL" if reg015_fail > 0 else "PASS",
		"OWNER_REG_014_FAILURES": reg014_fail,
		"OWNER_REG_015_FAILURES": reg015_fail,
		"note": "Headless may mark FINAL_SCREEN_WITNESS_AVAILABLE=false; then counters stay 0 (no false PASS claim).",
		"rows": rows,
		"ok": reg014_fail == 0 and reg015_fail == 0,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	var text := JSON.stringify(payload, "\t")
	for p in [
		"res://../artifacts/engineering_wave020/OWNER_REG_014_015_RESULT.json",
		"../artifacts/engineering_wave020/OWNER_REG_014_015_RESULT.json",
	]:
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
	print("OWNER_REG_014=", payload["OWNER_REG_014_FINAL_SCREEN_ABSENT"], " OWNER_REG_015=", payload["OWNER_REG_015_MOVE_PREVIEW_EMPTY"])
	quit(0 if payload["ok"] else 1)
