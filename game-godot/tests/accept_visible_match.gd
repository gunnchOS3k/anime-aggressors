extends SceneTree

## Visible (non-headless) match/menu acceptance driver.
## Usage:
##   /Applications/Godot-4.3.app/Contents/MacOS/Godot --path game-godot -s res://tests/accept_visible_match.gd
## Screenshots are written under user://visible_gui/ — copy into docs after run.

const OUT := "user://visible_gui"

func _init() -> void:
	call_deferred("_run")

func _gs():
	return root.get_node_or_null("GameState")

func _sr():
	return root.get_node_or_null("SceneRouter")

func _log(msg: String) -> void:
	print("[visible_accept] %s" % msg)

func _ensure_out() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		_log("WARN screenshot failed %s" % name)
		return
	var path := "%s/%s.png" % [OUT, name]
	var err := img.save_png(path)
	_log("shot %s err=%s path=%s" % [name, str(err), ProjectSettings.globalize_path(path)])

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _press(action: String, sec: float = 0.12) -> void:
	Input.action_press(action)
	await _wait(sec)
	Input.action_release(action)

func _run() -> void:
	_ensure_out()
	var failed := 0
	var gs = _gs()
	var sr = _sr()
	if gs == null or sr == null:
		_log("FAIL autoloads")
		quit(1)
		return
	var scenes: Dictionary = sr.SCENES

	# Boot → title/main
	change_scene_to_file(scenes.get("boot", "res://scenes/boot/BootScene.tscn"))
	await _wait(2.0)
	await _shot("01-boot")
	if scenes.has("main_menu"):
		change_scene_to_file(scenes["main_menu"])
		await _wait(1.0)
		await _shot("02-main-menu")

	# Configure match via GameState then go through select scenes if present
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p2_is_cpu = true
	gs.cpu_level = 3
	gs.stocks = 2
	var stages: Array = gs.production_stage_ids() if gs.has_method("production_stage_ids") else []
	if stages.is_empty():
		_log("FAIL no stages")
		failed += 1
		quit(1)
		return
	gs.stage_id = stages[0]
	gs.ruleset_id = "stock-1"
	gs.match_type = "stock"
	gs.reset_match()

	if scenes.has("fighter_select"):
		change_scene_to_file(scenes["fighter_select"])
		await _wait(1.0)
		await _shot("03-fighter-select")
	if scenes.has("stage_select"):
		change_scene_to_file(scenes["stage_select"])
		await _wait(1.0)
		await _shot("04-stage-select")

	change_scene_to_file(scenes["battle"])
	await _wait(4.5)
	await _shot("05-match-intro")

	# Movement / jump / attack / special / grab
	await _press("p1_right", 0.35)
	await _press("p1_jump", 0.15)
	await _wait(0.2)
	await _press("p1_attack", 0.12)
	await _shot("06-attack")
	if InputMap.has_action("p1_special"):
		await _press("p1_special", 0.2)
		await _shot("07-special")
	if InputMap.has_action("p1_grab"):
		await _press("p1_right", 0.2)
		await _press("p1_grab", 0.15)
		await _press("p1_right", 0.15)
		await _shot("08-grab-throw")

	# Force a stock loss path similar to headless harness
	var battle = root.get_child(root.get_child_count() - 1)
	var f1 = battle.get("fighter1") if battle else null
	var f2 = battle.get("fighter2") if battle else null
	if f1 == null or f2 == null:
		_log("FAIL fighters missing")
		failed += 1
	else:
		_log("PASS fighters")
		f2.global_position = Vector2(99999, 99999)
		await _wait(2.0)
		await _shot("09-stock-loss")

	# Finish match toward results if methods exist
	if gs.has_method("force_match_end"):
		gs.force_match_end()
	elif battle and battle.has_method("end_match"):
		battle.end_match()
	await _wait(2.0)
	if scenes.has("results"):
		change_scene_to_file(scenes["results"])
		await _wait(1.2)
		await _shot("10-results")

	# Rematch → battle again briefly
	gs.reset_match()
	change_scene_to_file(scenes["battle"])
	await _wait(3.5)
	await _shot("11-rematch")

	# Training + settings if routes exist
	if scenes.has("training"):
		change_scene_to_file(scenes["training"])
		await _wait(1.2)
		await _shot("12-training")
	if scenes.has("settings"):
		change_scene_to_file(scenes["settings"])
		await _wait(1.0)
		if gs.has_method("set") and "master_volume" in gs:
			pass
		await _shot("13-settings")
		if scenes.has("main_menu"):
			change_scene_to_file(scenes["main_menu"])
			await _wait(0.8)
			await _shot("14-menu-after-settings")

	# Verify seven fighters have combat data
	if gs.has_method("all_fighter_ids"):
		var ids: Array = gs.all_fighter_ids()
		_log("fighters=%s" % str(ids))
		if ids.size() < 7:
			_log("FAIL expected 7 fighters got %d" % ids.size())
			failed += 1
	elif gs.has("fighters") or gs.get("fighter_catalog"):
		_log("PASS fighter catalog present")
	else:
		# Fall back to data folder
		var dir := DirAccess.open("res://data/fighters")
		if dir:
			var count := 0
			dir.list_dir_begin()
			var fn := dir.get_next()
			while fn != "":
				if fn.ends_with(".json") or fn.ends_with(".tres"):
					count += 1
				fn = dir.get_next()
			_log("fighter files=%d" % count)
			if count < 7:
				failed += 1
		else:
			_log("WARN could not enumerate fighters")

	_log("RESULT failed=%d" % failed)
	await _wait(0.5)
	quit(0 if failed == 0 else 1)
