extends "res://tests/integration/TrainingLifecycle.gd"
## Pending real-scene acceptance. No damage/contact/state injection. An idle
## practice target is declared setup, not active-CPU or true-combo acceptance.
var practice_observation: Dictionary = {}

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile")
		quit(2)
		return
	var gs = root.get_node("GameState")
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	gs.begin_training()
	gs.p1_fighter_id = "kaia-windrow"
	gs.p2_fighter_id = "juno-spark"
	gs.stage_id = "training-grid"
	gs.training_dummy_mode = "shield"
	root.get_node("SceneRouter").go("training_battle")
	if not await wait_route("TrainingBattleScene.tscn"):
		check(false, "training_scene_loaded")
		finish()
		return
	var training = current_scene
	await frames(120)
	check(training.fighter2.dummy_mode == "shield" and Input.is_action_pressed("p2_shield"), "shield_dummy_owns_held_action")
	# Public F8 cycle returns shield -> jump -> attack -> CPU -> DI -> idle.
	for i in range(6): await tool_key(KEY_F8)
	check(training.fighter2.dummy_mode == "idle" and not Input.is_action_pressed("p2_shield"), "idle_releases_previous_dummy_shield")
	await frames(60)
	var defender = training.fighter2
	var before: float = defender.damage_percent
	for i in range(360):
		var dx: float = defender.global_position.x - training.fighter1.global_position.x
		if absf(dx) > 60: keys(["right" if dx > 0 else "left"])
		elif i % 35 == 0: keys(["attack"])
		else: keys([])
		await physics_frame
		if defender.damage_percent > before: break
	keys([])
	await frames(60)
	var counter: Dictionary = training._practice.slot_stats(1)
	check(defender.damage_percent > before and counter.hits > 0, "ordinary_attack_applies_real_damage")
	check(is_equal_approx(float(counter.damage), defender.damage_percent - before), "HUD_session_damage_matches_actual_meter")
	check(counter.combo == 0, "combo_clears_after_defender_recovers")
	var hits: int = counter.hits
	var misses: int = counter.whiffs
	# Walk away and swing through ordinary controls; never relocate the actor.
	var retreat := "left" if training.fighter1.global_position.x < defender.global_position.x else "right"
	keys([retreat])
	await frames(55)
	keys([])
	await frames(20)
	keys(["attack"])
	await frames(1)
	keys([])
	await frames(75)
	check(counter.hits == hits and counter.whiffs > misses, "completed_missed_swing_is_not_a_hit")
	practice_observation = training._practice.snapshot()
	await image("01_real_training_contacts")
	for button in training._practice_panel.find_children("*", "Button", true, false):
		if button.text.begins_with("Reset practice"):
			await click(button)
			break
	check(training.fighter1.damage_percent == 0 and defender.damage_percent == 0, "public_practice_reset_uses_actor_respawn")
	check(training._practice.slot_stats(1).hits == 0, "practice_reset_clears_session_counters")
	await frames(90)
	check(not training.fighter1.invincible and not defender.invincible, "existing_respawn_immunity_expires")
	# Reset during an actual new contact, while its real hitstop is active.
	# No synthetic hitstop/damage assignment or forced combat result.
	for i in range(360):
		var dx: float = defender.global_position.x - training.fighter1.global_position.x
		if absf(dx) > 60: keys(["right" if dx > 0 else "left"])
		elif i % 35 == 0: keys(["attack"])
		else: keys([])
		await physics_frame
		if defender.damage_percent > 0: break
	keys([])
	var stopped_by_contact: bool = training.fighter1._hitstop > 0.0 or defender._hitstop > 0.0
	check(defender.damage_percent > 0 and stopped_by_contact, "reset_probe_reaches_real_contact_hitstop")
	training._reset_practice()
	check(training.fighter1._hitstop == 0.0 and defender._hitstop == 0.0, "practice_reset_retires_previous_contact_hitstop")
	var controller = training.fighter1.model_3d.get_animation_controller()
	check(controller != null and not controller.presentation_frozen, "practice_reset_releases_contact_animation_freeze")
	check(JSON.stringify(campaign.progress) == story_before, "practice_does_not_change_Story_progress")
	finish()

func finish() -> void:
	keys([])
	paused = false
	Engine.time_scale = 1.0
	var file := FileAccess.open(output.path_join("TRAINING_PRACTICE.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS": failures.is_empty(), "checks": checks,
		"failures": failures, "inputs": inputs, "practice": practice_observation,
		"screenshots": images, "headless": DisplayServer.get_name() == "headless",
		"scope": "Actual public-input training against declared practice dummy, no injected contacts/damage. Not active-CPU, artistic or true-combo acceptance."}, "  "))
	file.close()
	quit(0 if failures.is_empty() else 1)
