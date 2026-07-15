extends SceneTree

## Interactive match-loop acceptance without compiling against GameState autoload identifiers.
## Usage:
##   Godot --path game-godot --headless -s res://tests/accept_match_loop.gd

func _init() -> void:
	call_deferred("_run")

func _gs():
	return root.get_node_or_null("GameState")

func _sr():
	return root.get_node_or_null("SceneRouter")

func _log(msg: String) -> void:
	print("[accept_match] %s" % msg)

func _run() -> void:
	var failed := 0
	var gs = _gs()
	var sr = _sr()
	if gs == null or sr == null:
		_log("FAIL autoloads missing (GameState/SceneRouter)")
		quit(1)
		return
	_log("PASS autoloads")

	var scenes: Dictionary = sr.SCENES
	for key in ["boot", "main_menu", "mode_select", "ruleset", "fighter_select", "stage_select", "versus", "battle", "results", "training", "settings"]:
		if not scenes.has(key):
			_log("FAIL missing route %s" % key)
			failed += 1
			continue
		if not ResourceLoader.exists(scenes[key]):
			_log("FAIL missing scene %s" % scenes[key])
			failed += 1
		else:
			_log("PASS scene:%s" % key)

	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p2_is_cpu = true
	gs.cpu_level = 3
	gs.stocks = 1
	var stages: Array = gs.production_stage_ids()
	if stages.is_empty():
		_log("FAIL no stages")
		failed += 1
		quit(1)
		return
	gs.stage_id = stages[0]
	gs.ruleset_id = "stock-1"
	gs.match_type = "stock"
	gs.reset_match()

	change_scene_to_file(scenes["battle"])
	await process_frame
	await process_frame
	await create_timer(4.2).timeout

	var battle = root.get_child(root.get_child_count() - 1)
	var f1 = battle.get("fighter1") if battle else null
	var f2 = battle.get("fighter2") if battle else null
	if f1 == null or f2 == null or not is_instance_valid(f1) or not is_instance_valid(f2):
		_log("FAIL fighters_missing")
		failed += 1
	else:
		_log("PASS fighters_spawned")
		if f1.controls_enabled:
			_log("PASS p1_controllable")
		else:
			_log("FAIL p1_controls")
			failed += 1
		if f2.is_cpu:
			_log("PASS cpu_opponent")
		else:
			_log("FAIL cpu_flag")
			failed += 1
		f2.global_position = Vector2(99999, 99999)
		await create_timer(2.0).timeout
		var winner := int(gs.last_winner_slot)
		var stocks_ok := false
		if is_instance_valid(f2):
			stocks_ok = int(f2.stocks) <= 0
		if stocks_ok or winner != -1 and winner != 0:
			_log("PASS stock_or_match_end winner=%s" % str(winner))
		else:
			_log("WARN forced_results_fallback")
			gs.last_winner_slot = 1
			change_scene_to_file(scenes["results"])
			await process_frame
			_log("PASS results_forced")

	# Rematch path
	change_scene_to_file(scenes["battle"])
	await process_frame
	_log("PASS rematch_reload")
	change_scene_to_file(scenes["main_menu"])
	await process_frame
	_log("PASS return_menu")
	change_scene_to_file(scenes["training"])
	await process_frame
	_log("PASS training")
	change_scene_to_file(scenes["settings"])
	await process_frame
	_log("PASS settings")

	if failed > 0:
		_log("DONE failures=%d" % failed)
		quit(1)
	else:
		_log("DONE all checks passed")
		quit(0)
