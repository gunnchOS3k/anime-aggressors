extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Isolated public-asset scene/UI regression. No forced combat outcome or Story
## progress. Menu selections are declared setup; lesson actions use public input.
## Execute ONLY through the existing resource-guarded runner.
var observations: Array = []

func wait_route(suffix: String) -> bool:
	for i in range(180):
		await process_frame
		if route_is(suffix):
			await process_frame
			return true
	return false

func tool_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func cancel() -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile")
		quit(2)
		return
	var gs = root.get_node("GameState")
	var router = root.get_node("SceneRouter")
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	# Reproduce opening training from another mode. The menu owns defaults;
	# the subsequent stage/dummy selections must survive battle entry.
	gs.mode = "versus"
	router.go("training")
	check(await wait_route("TrainingMenuScene.tscn"), "training_menu_loaded")
	if not route_is("TrainingMenuScene.tscn"):
		finish()
		return
	var menu = current_scene
	check(gs.mode == "training" and gs.ruleset_id == "training", "training_defaults_precede_configuration")
	var p1_index: int = menu._roster.find("kaia-windrow")
	var p2_index: int = menu._roster.find("juno-spark")
	var stage_index: int = menu._stages.find("skyline-arena")
	check(p1_index >= 0 and p2_index >= 0 and stage_index >= 0, "requested_public_configuration_available")
	if p1_index < 0 or p2_index < 0 or stage_index < 0:
		finish()
		return
	menu.p1_option.select(p1_index)
	menu.p2_option.select(p2_index)
	menu.stage_option.select(stage_index)
	menu.dummy_option.select(1) # Existing shield dummy, not a manufactured win.
	await click(menu.get_node("VBox/Start"))
	check(await wait_route("TrainingBattleScene.tscn"), "training_battle_loaded")
	if not route_is("TrainingBattleScene.tscn"):
		finish()
		return
	var training = current_scene
	await frames(30)
	check(gs.stage_id == "skyline-arena" and training.fighter2.dummy_mode == "shield", "stage_and_dummy_choices_preserved")
	check(training.fighter1.fighter_id == "kaia-windrow" and training.fighter2.fighter_id == "juno-spark", "fighter_choices_preserved")
	await image("01_selected_training")
	await tool_key(KEY_F9)
	check(paused and training._paused, "training_pause_entered")
	for button in training._pause_panel.find_children("*", "Button", true, false):
		if button.text == "Return to Training Menu":
			button.grab_focus()
			await accept_focused()
			break
	check(await wait_route("TrainingMenuScene.tscn"), "training_pause_return")
	check(not paused and is_equal_approx(Engine.time_scale, 1.0), "training_return_restores_clock")

	# The public tutorial entry must replace stale CPU/evaluation setup.
	router.go("tutorial")
	check(await wait_route("TutorialScene.tscn"), "tutorial_menu_loaded")
	if not route_is("TutorialScene.tscn"):
		finish()
		return
	gs.p1_is_cpu = true
	gs.battle_eval_mode = true # Declared pre-match configuration boundary.
	await click(current_scene.get_node("VBox/StartGuided"))
	check(await wait_route("TutorialBattleScene.tscn"), "guided_battle_loaded")
	if not route_is("TutorialBattleScene.tscn"):
		finish()
		return
	var tutorial = current_scene
	check(gs.mode == "tutorial" and gs.ruleset_id == "tutorial", "tutorial_authority_preserved_by_shared_scene")
	check(not gs.p1_is_cpu and not gs.battle_eval_mode and not tutorial.fighter1.is_cpu, "tutorial_player_owns_controls")
	check(not gs.tutorial_completed, "fresh_lesson_not_granted")
	await tool_key(KEY_F9)
	await tool_key(KEY_F11)
	await tool_key(KEY_F10)
	check(paused and tutorial._freeze and Engine.time_scale < 1.0, "paused_frozen_slow_tutorial_fixture")
	await cancel()
	check(await wait_route("ModeSelectScene.tscn"), "tutorial_escape_routes_to_mode_select")
	check(not paused and is_equal_approx(Engine.time_scale, 1.0), "tutorial_escape_restores_global_clock")
	check(not gs.tutorial_completed, "early_exit_does_not_grant_completion")

	# Complete the existing five action lessons through ordinary controls.
	router.go("tutorial")
	if not await wait_route("TutorialScene.tscn"):
		check(false, "tutorial_reentry")
		finish()
		return
	await click(current_scene.get_node("VBox/StartGuided"))
	if not await wait_route("TutorialBattleScene.tscn"):
		check(false, "guided_reentry")
		finish()
		return
	tutorial = current_scene
	await frames(30)
	keys(["right"])
	await frames(25)
	keys([])
	await frames(10)
	keys(["jump"])
	await frames(1)
	keys([])
	await frames(70)
	keys(["attack"])
	await frames(1)
	keys([])
	await frames(50)
	keys(["special"])
	await frames(1)
	keys([])
	await frames(80)
	keys(["special", "shield"])
	await frames(100)
	keys([])
	await frames(30)
	check(gs.tutorial_completed and tutorial._completion_recorded, "public_actions_complete_existing_lesson")
	check(tutorial.ORDER.all(func(step): return gs.tutorial_steps_done.has(step)), "all_five_action_observations_recorded")
	check(not tutorial._record_completion_if_ready(), "completed_guide_cannot_commit_twice")
	var saved := ConfigFile.new()
	check(saved.load("user://aa_first_run.cfg") == OK and bool(saved.get_value("tutorial", "completed", false)), "lesson_completion_persisted")
	await image("02_tutorial_complete")
	observations.append({"steps": gs.tutorial_steps_done.duplicate(), "guide": tutorial._guide.text})
	await cancel()
	check(await wait_route("ModeSelectScene.tscn"), "completed_tutorial_menu_return")
	check(JSON.stringify(campaign.progress) == story_before, "Story_progress_unchanged")
	finish()

func finish() -> void:
	keys([])
	# Cleanup follows observations; never use it to make exit assertions pass.
	paused = false
	Engine.time_scale = 1.0
	var file := FileAccess.open(output.path_join("TRAINING_LIFECYCLE.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS": failures.is_empty(), "checks": checks,
		"failures": failures, "inputs": inputs, "observations": observations,
		"screenshots": images, "headless": DisplayServer.get_name() == "headless",
		"scope": "Actual public training/tutorial scenes. Declared menu/CPU configuration and ordinary lesson actions; no forced combat result or earned Story claim. No movie or human acceptance."}, "  "))
	file.close()
	print("TRAINING_LIFECYCLE ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
	quit(0 if failures.is_empty() else 1)
