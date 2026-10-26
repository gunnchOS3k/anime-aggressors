extends "res://tests/integration/TrainingLifecycle.gd"
## Actual SceneTree physics and public training inputs. No manual fighter tick,
## contact/damage injection, seeded result or original-art acceptance.
var samples: Array = []

func action(slot: int, suffix: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "p%d_%s" % [slot, suffix]
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func step(training) -> void:
	var before: int = training._frame_clock.frames
	await tool_key(KEY_F12)
	for i in range(20):
		await process_frame
		if training._frame_clock.frames > before: break
	check(training._frame_clock.frames == before + 1, "one_physics_iteration_per_step")
	check(paused and not training._frame_clock.stepping, "step_returns_to_paused_tree")

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile")
		quit(2)
		return
	var gs = root.get_node("GameState")
	gs.begin_training()
	gs.stage_id = "training-grid"
	gs.p1_fighter_id = "kaia-windrow"
	gs.p2_fighter_id = "juno-spark"
	gs.training_dummy_mode = "idle"
	root.get_node("SceneRouter").go("training_battle")
	if not await wait_route("TrainingBattleScene.tscn"):
		check(false, "training_loaded")
		finish()
		return
	var training = current_scene
	await frames(120)
	var player = training.fighter1
	var target = training.fighter2
	await tool_key(KEY_F11)
	var position: Vector2 = player.global_position
	var state_frame: int = player.state_machine.state_frame
	await frames(30)
	check(player.global_position == position and player.state_machine.state_frame == state_frame, "frozen_wall_frames_do_not_advance_actor")
	await action(1, "right", true)
	await action(1, "right", false)
	await frames(20)
	check(player.global_position == position, "buffered_tap_does_not_move_paused_actor")
	await step(training)
	check(player.global_position.x > position.x, "step_runs_real_movement_physics_and_buffered_input")
	check(player.state_machine.state_frame > state_frame or player.state_machine.current_state != "idle", "actor_state_clock_advances")
	check(not Input.is_action_pressed("p1_right"), "injected_tap_is_released_after_step")
	position = player.global_position
	await frames(20)
	check(player.global_position == position, "step_cannot_leak_later_movement")
	await action(1, "jump", true)
	await action(1, "jump", false)
	for i in range(8): await step(training)
	check(player.velocity.y < 0 and player.global_position.y < position.y, "jump_buffer_and_gravity_run_in_physics")
	# Slow motion must not turn F12 into a fraction of a combat frame.
	await tool_key(KEY_F10)
	var clock_before: float = player.state_machine.state_time
	await step(training)
	check(is_equal_approx(Engine.time_scale, 0.35), "step_restores_slow_motion_setting")
	check(absf(player.state_machine.state_time - clock_before - 1.0 / 60.0) < 0.0001, "slow_mode_step_is_one_full_simulation_delta")
	await tool_key(KEY_F10)
	await tool_key(KEY_F11)
	await frames(100)
	# Approach normally, then start and resolve the attack ONLY with F12.
	for i in range(360):
		var dx: float = target.global_position.x - player.global_position.x
		if absf(dx) > 60: keys(["right" if dx > 0 else "left"])
		else: keys([]); break
		await physics_frame
	keys([])
	await frames(12)
	await tool_key(KEY_F11)
	await action(1, "attack", true)
	await action(1, "attack", false)
	for i in range(60):
		await step(training)
		if target.damage_percent > 0: break
	check(target.damage_percent > 0, "stepped_attack_startup_and_contact_apply_actual_damage")
	var applied: float = target.damage_percent
	var hits: int = training._practice.slot_stats(1).hits
	var hitstop: float = player._hitstop
	var hurt_time: float = target.state_machine.state_time
	var renderer = training.get_node_or_null("SpectralFeedback")
	var visual_ages: Array = []
	if renderer != null:
		for slot in renderer.slots:
			if slot.active: visual_ages.append({"id": slot.event_id, "age": slot.age})
	await frames(30)
	check(player._hitstop == hitstop and target.state_machine.state_time == hurt_time, "paused_hitstop_and_hurt_time_are_frozen")
	if renderer != null:
		for prior in visual_ages:
			for slot in renderer.slots:
				if slot.event_id == prior.id:
					check(slot.age == prior.age, "confirmed_contact_effect_lifetime_uses_simulation_time")
	for i in range(8): await step(training)
	check(target.damage_percent == applied and training._practice.slot_stats(1).hits == hits, "step_does_not_duplicate_contact_or_damage")
	check(player._hitstop < hitstop or hitstop == 0.0, "step_advances_real_hitstop")
	var controller = player.model_3d.get_animation_controller()
	check(controller != null and controller._training_physics_clock, "animation_controller_uses_simulation_clock")
	# Practice respawn must expire after active simulation, never paused time.
	training._reset_practice() # Declared practice control, not a match result.
	await frames(100)
	check(player.invincible and target.invincible, "paused_wall_time_cannot_expire_respawn")
	for i in range(73): await step(training)
	check(not player.invincible and not target.invincible, "active_physics_steps_expire_existing_respawn_duration")
	await action(2, "shield", true)
	await step(training)
	var guard_clock: int = target.perfect_guard.clock
	var guard_opened: int = target.perfect_guard.opened
	await frames(30)
	check(target.shielding and target.perfect_guard.clock == guard_clock and target.perfect_guard.opened == guard_opened, "paused_wall_time_cannot_age_fresh_guard")
	await step(training)
	check(target.perfect_guard.clock == guard_clock + 1, "guard_window_advances_exactly_one_simulation_frame")
	await action(2, "shield", false)
	samples.append({"steps": training._frame_clock.frames, "contacts": hits, "damage": applied,
		"original_art": false, "active_CPU": false, "scope": "declared idle practice target"})
	finish()

func finish() -> void:
	keys([])
	paused = false
	Engine.time_scale = 1.0
	var file := FileAccess.open(output.path_join("TRAINING_FRAME_STEP.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS": failures.is_empty(), "checks": checks,
		"failures": failures, "samples": samples, "inputs": inputs,
		"scope": "Actual Godot SceneTree physics, buffering, contact and timers with public assets. No native visual/device/human acceptance."}, "  "))
	file.close()
	quit(0 if failures.is_empty() else 1)
