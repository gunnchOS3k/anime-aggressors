extends "res://tests/integration/TrainingLifecycle.gd"
## Actual Training UI and ordinary attacks against declared idle/shield dummy.
## No move, damage, root, hitstun, cancel or contact injection. Not CPU proof.
var lesson_rows: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated Training profile required"); quit(2); return
	var gs = root.get_node("GameState")
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	gs.begin_training()
	gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = "female"; gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"; gs.stage_id = "training-grid"
	root.get_node("SceneRouter").go("training_battle")
	check(await wait_route("TrainingBattleScene.tscn"), "actual_training_scene_loaded")
	if not route_is("TrainingBattleScene.tscn"): finish(); return
	var training = current_scene
	await frames(120)
	await click(training._move_list_btn)
	var panel = training._move_list_panel
	check(panel != null and panel.visible and panel.allow_link_practice, "training_move_list_opens_real_link_practice_UI")
	if panel == null or not panel.visible: finish(); return
	# Declared lesson menu selection, not a move/action execution helper.
	var list_index := -1
	for i in panel._list.item_count:
		if panel._list.is_item_disabled(i): continue
		panel._list.select(i); panel._list.item_selected.emit(i)
		if str(panel._current_entry().get("move_id", "")) == "jab_1": list_index = i; break
	check(list_index >= 0 and panel._link_buttons.get_child_count() == 1, "lesson_comes_from_actual_manifest_jab_link")
	if list_index < 0 or panel._link_buttons.get_child_count() == 0: finish(); return
	await process_frame
	await click(panel._link_buttons.get_child(0))
	check(not panel.visible and training._link_practice.selection.get("source", "") == "jab_1" and training._link_practice.selection.get("target", "") == "jab_2", "public_lesson_button_selects_actual_source_and_target")
	var p = training.fighter1; var d = training.fighter2
	check(not training._link_practice.choose(p, "jab_1", "aura_burst") and training._link_practice.selection.target == "jab_2", "unmanifested_link_is_rejected_without_replacing_selection")
	for i in range(180):
		var dx: float = d.position.x - p.position.x
		if absf(dx) < 46 and p.is_on_floor() and d.is_on_floor(): break
		keys(["right" if dx > 0 else "left"]); await physics_frame
	keys([])
	check(await legal_ground_control(p), "ordinary_source_starts_with_real_ground_control")
	keys(["attack"]); await frames(2); keys([])
	var requested := false
	for i in range(100):
		if p.move_runner.current_move_id() == "jab_1" and p.move_runner.confirmed_body_hit and p.move_runner.can_cancel_to("jab_2") and p._hitstop <= 0:
			keys(["attack"]); await frames(2); keys([]); requested = true; break
		await physics_frame
	await frames(65)
	var observed: Dictionary = training._link_practice.snapshot()
	lesson_rows.append(observed)
	check(requested and observed.attempt.get("source_hit", false) and observed.attempt.get("accepted_cancel", false), "ordinary_hit_confirmed_link_is_observed_from_real_cancel_history")
	check(observed.attempt.get("target_contact", false) and observed.attempt.contacts.size() >= 2, "actual_target_activation_contacts_same_defender")
	check(observed.attempt.outcome in ["contact_before_recovery", "recovered_follow_up"], "lesson_distinguishes_observed_contact_from_defender_recovery")
	check(not training._link_label.text.is_empty() and not training._link_label.text.contains("guaranteed combo complete"), "real_HUD_reports_observation_without_guaranteed_combo_claim")
	# Source defense is an actual held shield, with existing fresh-press policy.
	await reset_via_button(training)
	Input.action_press("p2_shield"); await frames(20)
	for i in range(180):
		var dx: float = d.position.x - p.position.x
		if absf(dx) < 46: break
		keys(["right" if dx > 0 else "left"]); await physics_frame
	keys([]); check(await legal_ground_control(p), "shield_probe_starts_with_real_ground_control")
	keys(["attack"]); await frames(2); keys([])
	await frames(45)
	var blocked: Dictionary = training._link_practice.snapshot()
	lesson_rows.append(blocked)
	check(blocked.attempt.get("outcome", "") == "source_defended" and not blocked.attempt.get("source_hit", false) and not blocked.attempt.get("accepted_cancel", false) and d.damage_percent == 0, "real_shield_rejects_body_hit_lesson_completion")
	Input.action_release("p2_shield")
	await reset_via_button(training)
	check(training._link_practice.attempt.is_empty() and not training._link_practice.selection.is_empty(), "public_reset_restarts_attempt_and_retains_lesson")
	await tool_key(KEY_F5)
	check(training._link_practice.selection.is_empty(), "debug_aura_tool_invalidates_ordinary_input_lesson")
	var glyphs = load("res://scripts/ui/input_glyph_presenter.gd")
	check(glyphs.glyphs_for_command("attack_air_up", "keyboard").compact == glyphs.glyphs_for_command("aerial_up", "keyboard").compact, "actual_aerial_manifest_commands_have_readable_device_notation")
	check(JSON.stringify(campaign.progress) == story_before, "lesson_never_changes_earned_Story_progress")
	finish()

func legal_ground_control(actor) -> bool:
	for i in range(180):
		if actor.is_on_floor() and actor.state_machine.can_attack() and actor._hitstop <= 0: return true
		await physics_frame
	return false

func reset_via_button(training) -> void:
	keys([])
	for button in training._practice_panel.find_children("*", "Button", true, false):
		if button.text.begins_with("Reset practice"):
			await click(button); break
	await frames(120)
	check(await legal_ground_control(training.fighter1), "practice_reset_returns_real_ground_control")

func finish() -> void:
	keys([]); Input.action_release("p2_shield")
	var result = {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "rows":lesson_rows, "inputs":inputs,
		"scope":"Actual Training UI + ordinary Kaia/female vs Juno/male idle/shield practice; manifest hit-confirm cancel and same-defender contact observation. Not active-CPU, guaranteed combo, all32-link execution, native visual, art or human acceptance."}
	var file = FileAccess.open(output.path_join("TRAINING_AUTHORED_LINK.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("TRAINING_AUTHORED_LINK ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
