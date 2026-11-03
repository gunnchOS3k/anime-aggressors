extends "res://tests/integration/AttackEarnedMatch.gd"
## Actual UI, canonical Story rules, ordinary P1 inputs and active CPU3.
## No progress/result/damage/stock/position assignment. Two real processes
## share ONLY their isolated, normally-created authenticated user profile.
var pass_name := ""
var observations: Dictionary = {}
var move_counts := {"1": 0, "2": 0}
var guard_frames := 0
var p1_motion := false
var started_position := Vector2.ZERO
var original_node: Dictionary = {}
var actor_samples: Array = []
var invulnerable_transitions: Array = []
var stale_invulnerability: Array = []
var ledge_move_leaks: Array = []

func wire_equal(a: Variant, b: Variant) -> bool:
	# JSON has one numeric type; native Dictionary equality distinguishes
	# int stocks from JSON-decoded float stocks. Compare exact wire values,
	# preserving every key/type except that specified numeric representation.
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not wire_equal(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not wire_equal(a[i], b[i]): return false
		return true
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return float(a) == float(b)
	return typeof(a) == typeof(b) and a == b

func wait_route(suffix: String, limit := 180) -> bool:
	for i in range(limit):
		await process_frame
		if route_is(suffix):
			await process_frame
			return true
	return false

func activate(button: Button) -> bool:
	if button == null: return false
	var label: String = button.text
	var delivered := {"count": 0}
	button.pressed.connect(func(): delivered.count += 1, CONNECT_ONE_SHOT)
	button.grab_focus()
	await process_frame
	var viewport = button.get_viewport()
	var owner = viewport.gui_get_focus_owner()
	var detail := {"button": label, "can_process": button.can_process(), "paused": paused,
		"focus": str(owner.get_path()) if owner != null else "NONE", "disabled": button.disabled, "visible": button.is_visible_in_tree()}
	var event := InputEventAction.new()
	event.action = "ui_accept"; event.pressed = true
	viewport.push_input(event, true)
	detail["press_handled"] = viewport.is_input_handled()
	detail["paused_after_press"] = paused
	detail["button_down_after_press"] = button.is_pressed()
	await process_frame
	event = event.duplicate(); event.pressed = false
	if is_instance_valid(viewport): viewport.push_input(event, true)
	else: root.push_input(event, true)
	await process_frame
	detail["delivered"] = delivered.count
	detail["paused_after_release"] = paused
	if not observations.has("UI"): observations["UI"] = []
	observations["UI"].append(detail)
	inputs.append({"frame": Engine.get_physics_frames(), "UI_confirm_delivered": delivered.count})
	return delivered.count == 1

func choose(text: String) -> bool:
	for button in current_scene.find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			return await activate(button)
	return false

func public_key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate(); event.pressed = false; root.push_input(event, true)
	await process_frame
	inputs.append({"frame": Engine.get_physics_frames(), "key": code})

func move_started(_id: String, actor) -> void:
	move_counts[str(actor.slot)] += 1

func actor_snapshot(actor) -> Dictionary:
	return {"slot": actor.slot, "state": actor.state_machine.current_state,
		"state_time": actor.state_machine.state_time, "invincible": actor.invincible,
		"floor": actor.is_on_floor(), "velocity": [actor.velocity.x, actor.velocity.y],
		"position": [actor.position.x, actor.position.y], "controls": actor.controls_enabled,
		"grabbed_by": actor.grabbed_by.slot if is_instance_valid(actor.grabbed_by) else 0,
		"grabbed_target": actor.grabbed_target.slot if is_instance_valid(actor.grabbed_target) else 0,
		"pending": actor._pending_attack_cmd, "runner_active": actor.move_runner.active,
		"runner_phase": actor.move_runner.phase, "runner_frame": actor.move_runner.total_frame,
		"CPU_goal": actor.cpu._last_goal, "CPU_timer": actor.cpu._timer,
		"moves": int(move_counts[str(actor.slot)])}

func transition_observed(from: String, to: String, actor) -> void:
	if actor.invincible:
		invulnerable_transitions.append({"frame": Engine.get_physics_frames(), "slot": actor.slot,
			"from": from, "to": to, "invincible_before_entry": true})

func observe() -> void:
	if not is_instance_valid(battle): return
	for actor in [battle.fighter1, battle.fighter2]:
		if actor.state_machine.current_state in ["ledge_hang", "ledge_getup"] and actor.move_runner.active and ledge_move_leaks.size() < 12:
			ledge_move_leaks.append({"frame": Engine.get_physics_frames(), "actor": actor_snapshot(actor)})
		# Kaia/Juno's respawn immunity expires in1.2s; ordinary grounded shield
		# is never a long-lived invulnerability owner. Preserve actual failures.
		if actor.invincible and actor.state_machine.current_state in ["idle", "shield_hold", "shield_break"] and actor.state_machine.state_time > 1.3 and stale_invulnerability.size() < 12:
			stale_invulnerability.append({"frame": Engine.get_physics_frames(), "actor": actor_snapshot(actor)})
	if battle.fighter1.shielding: guard_frames += 1
	if absf(battle.fighter1.position.x - started_position.x) > 10.0: p1_motion = true
	if battle._active and Engine.get_physics_frames() % 120 == 0:
		actor_samples.append({"frame": Engine.get_physics_frames(), "actors": [actor_snapshot(battle.fighter1), actor_snapshot(battle.fighter2)]})
	if Engine.get_physics_frames() % 15 == 0 or battle._match_finished:
		super.observe()

func play_controls() -> void:
	var p = battle.fighter1; var d = battle.fighter2
	if elapsed >= 600 or p.grabbed_by != null or p.grabbed_target != null:
		drive() # Existing normal-input spacing/grab/throw/recovery driver.
		return
	if not p.is_on_floor() and p.position.y > p.platform_surface_y:
		drive(); return
	var dx: float = d.position.x - p.position.x
	var actions: Array = []
	if absf(dx) > 60: actions.append("right" if dx > 0 else "left")
	if elapsed % 100 < 16: actions = ["shield"]
	elif elapsed % 70 == 20: actions.append("attack"); actions.append("special")
	elif elapsed % 27 == 0: actions.append("attack")
	if d.position.y < p.position.y - 60 and elapsed % 50 < 2: actions.append("jump")
	phase = "ordinary_story_combat"
	keys(actions)

func enter_authored_battle(campaign) -> bool:
	original_node = campaign.current_node().duplicate(true)
	var body: String = campaign.progress.presentation
	check(await choose("Play Encounter"), "actual_Play_Encounter_UI")
	check(await wait_route("BattleScene.tscn"), "authored_BattleScene_entered")
	if not route_is("BattleScene.tscn"): return false
	battle = current_scene
	check(battle._story_attempt_token == campaign.active_encounter.token and campaign._battle_producer == battle, "Story_attempt_and_producer_owned")
	check(battle.fighter1.fighter_id == campaign.route_data(campaign.progress.selected_route).anchor and battle.fighter2.fighter_id == original_node.opponent, "authored_player_and_opponent_preserved")
	check(battle.fighter1.model_3d.get_body_variant() == body and root.get_node("GameState").stage_id == original_node.stage, "saved_body_and_authored_stage_preserved")
	check(campaign.active_encounter.qualifying, "ordinary_earned_attempt_not_review_or_eval")
	var dialogue = root.get_node("StoryDialogue")
	check(dialogue.is_busy() and dialogue.node_id == original_node.id, "real_owned_encounter_intro")
	observations["intro"] = {"node": dialogue.node_id, "generation": dialogue._generation, "cue": dialogue.current.get("cue_id", ""), "public_skip": true}
	await frames(8)
	await public_key(KEY_F6) # Supported Skip dialogue, never combat authority.
	for i in range(480):
		await physics_frame
		if active_battle(): break
	check(active_battle(), "normal_countdown_enables_battle")
	if not active_battle(): return false
	check(battle.fighter1.controls_enabled and not battle.fighter1.is_cpu and battle.fighter2.controls_enabled and battle.fighter2.is_cpu, "normal_player_and_active_CPU_controls")
	check(battle.fighter1.stocks == 2 and battle.fighter2.stocks == 2 and battle.fighter1.damage_percent == 0 and battle.fighter2.damage_percent == 0, "fresh_authorized_attempt_not_prior_outcome_damage")
	for actor in [battle.fighter1, battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(record_contact)
		actor.koed.connect(stock_lost.bind(actor))
		actor.grab_event.connect(grab_event.bind(actor))
		actor.move_runner.move_started.connect(move_started.bind(actor))
		actor.state_machine.state_changed.connect(transition_observed.bind(actor))
	started_position = battle.fighter1.position
	physics_frame.connect(observe)
	return true

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--story-pass="): pass_name = arg.trim_prefix("--story-pass=")
	if output.is_empty() or OS.get_user_data_dir().get_file() != "aa-native-ci-story-encounter" or pass_name not in ["story-play", "story-restart", "story-controls"]:
		push_error("Refusing nonisolated Story profile or unknown journey")
		quit(2); return
	var campaign = root.get_node("CampaignRuntime")
	var gs = root.get_node("GameState")
	if gs.battle_eval_mode or campaign.route_review_enabled():
		push_error("Privileged/evaluation Story prohibited"); quit(2); return
	root.get_node("SceneRouter").go("main_menu")
	check(await wait_route("MainMenuScene.tscn"), "main_menu_loaded")
	check(await choose("Story"), "actual_main_menu_Story_UI")
	check(await wait_route("StoryCampaignScene.tscn"), "Story_menu_loaded")
	if not route_is("StoryCampaignScene.tscn"): finish(); return
	if pass_name in ["story-play", "story-controls"]:
		check(not FileAccess.file_exists(campaign.save_path), "new_isolated_profile_not_owner_or_staged_save")
		check(await choose("New Campaign"), "actual_New_Campaign_UI")
		var confirmation: ConfirmationDialog
		for child in current_scene.get_children():
			if child is ConfirmationDialog and child.visible: confirmation = child
		check(confirmation != null, "actual_new_campaign_confirmation")
		if confirmation != null: check(await activate(confirmation.get_ok_button()), "actual_confirmation_input")
		check(FileAccess.file_exists(campaign.save_path) and FileAccess.file_exists(campaign.save_path + ".key"), "application_created_authenticated_checkpoint")
	check(await choose("Resume Save"), "actual_Resume_Save_UI")
	check(campaign.last_error.is_empty(), "authenticated_resume_without_warning")
	if pass_name == "story-restart":
		var previous_file := FileAccess.open(output.path_join("STORY_ENCOUNTER_PLAY.json"), FileAccess.READ)
		var previous: Dictionary = JSON.parse_string(previous_file.get_as_text()) if previous_file != null else {}
		check(previous.get("PASS", false), "previous_real_process_completed_qualifying_journey")
		var expected: Dictionary = previous.get("observations", {}).get("saved", {})
		check(campaign.current_node().get("id", "") == expected.get("node", "MISSING") and campaign.progress.presentation == expected.get("body", "MISSING"), "new_process_restores_authored_node_and_body")
		check(wire_equal(campaign.progress.routes[campaign.progress.selected_route].completed, expected.get("completed", null)) and wire_equal(campaign.progress.routes[campaign.progress.selected_route].receipts, expected.get("receipts", null)), "new_process_restores_only_real_earned_receipts")
		check(wire_equal(campaign.progress.checkpoint, expected.get("checkpoint", null)), "new_process_restores_signed_result_metadata")
		observations["restore_types"] = {"actual_stocks": type_string(typeof(campaign.progress.checkpoint.get("combat", {}).get("stocks"))),
			"JSON_stocks": type_string(typeof(expected.get("checkpoint", {}).get("combat", {}).get("stocks")))}
	if not await enter_authored_battle(campaign): finish(); return
	var initial_completed: Array = campaign.progress.routes[campaign.progress.selected_route].completed.duplicate()
	# Cover the actual authored180s timer, never shorten/change match rules.
	# First100s probe legitimately took one stock but did not finish.
	for i in range(11400 if pass_name == "story-play" else 420):
		if not is_instance_valid(battle) or not battle._active: break
		elapsed = i; play_controls()
		await physics_frame
	keys([])
	check(stale_invulnerability.is_empty(), "no_permanent_grounded_invincibility")
	check(ledge_move_leaks.is_empty(), "ledge_acquisition_retires_interrupted_move")
	check(p1_motion and int(move_counts["1"]) > 0, "ordinary_player_movement_and_attacks_work")
	check(int(move_counts["2"]) > 0, "normal_CPU_uses_actual_moves")
	if pass_name in ["story-restart", "story-controls"]:
		await public_cancel()
		observations["pause"] = {"scene_paused": battle._paused, "tree_paused": paused, "panel_visible": battle._pause_panel.visible if battle._pause_panel != null else false}
		check(battle._paused and paused, "real_cancel_opens_pause")
		if pass_name == "story-controls":
			check(root.gui_get_focus_owner() == battle._pause_resume_button, "pause_opens_with_Resume_focus")
			check(await choose("Resume"), "focused_Resume_release_activates_once")
			check(not paused and not battle._paused, "focused_Resume_restores_combat")
			await public_cancel()
			check(await choose("Move List / Command Guide"), "focused_Move_List_confirm")
			check(paused and battle._move_list_panel.visible, "command_guide_keeps_combat_paused")
			check(await choose("Close Move List"), "focused_nested_Close_confirm")
			check(paused and not battle._move_list_panel.visible, "nested_close_keeps_pause_menu")
			await public_cancel()
			check(not paused and not battle._paused, "Escape_resumes_without_confirm_conflict")
			await public_cancel()
		check(await choose("Return to Menu"), "real_pause_return_after_resumed_controls")
		check(await wait_route("StoryCampaignScene.tscn"), "resumed_attempt_returns_to_Story")
		check(campaign.progress.routes[campaign.progress.selected_route].completed == initial_completed, "abandoned_attempt_awards_no_progress")
	else:
		check(is_instance_valid(battle) and battle._match_finished, "legitimate_combat_outcome_within_bound")
		if not is_instance_valid(battle) or not battle._match_finished: finish(); return
		check(contacts.any(func(c): return c.attacker_slot == 1 and c.damage > 0), "player_attack_causes_real_contact_and_damage")
		check(guard_frames > 0, "player_uses_real_guard")
		var receipt: Dictionary = campaign.last_result.duplicate(true)
		check(receipt.get("node_id", "") == original_node.id and receipt.get("qualifying", false), "real_owned_qualifying_Story_result")
		var won: bool = gs.last_winner_slot == 1
		check(bool(receipt.get("advanced", false)) == won, "only_actual_victory_advances")
		observations["outcome"] = {"winner": gs.last_winner_slot, "receipt": receipt, "finish_proof": finish_proof, "terminal": terminal}
		var success_cue: Dictionary = {}
		for row in root.get_node("StoryDialogue").history:
			if row.node_id == original_node.id and row.event == "encounter_success": success_cue = row.duplicate(true)
		observations["success_cue"] = success_cue
		# Preserve exact postcombat narrative lifetime; public Skip is allowed
		# only after observing at least45 frames of the finished battle.
		await frames(45)
		var dialogue = root.get_node("StoryDialogue")
		observations["postcombat"] = {"at_45_frames": current_scene.scene_file_path, "busy": dialogue.is_busy(), "node": dialogue.node_id}
		if won and float(success_cue.get("duration", 0)) > 0.75:
			check(route_is("BattleScene.tscn") and dialogue.is_busy(), "authored_success_line_not_cut_off_by_results_timer")
		if dialogue.is_busy(): await public_key(KEY_F6)
		check(await wait_route("ResultsScene.tscn"), "legitimate_Story_results_transition")
		if not route_is("ResultsScene.tscn"): finish(); return
		var result_chip: Label = current_scene.get_node_or_null("VictoryChip")
		observations["results"] = {"title": current_scene.title_label.text, "chip": result_chip.text if result_chip != null else "MISSING"}
		check(result_chip != null and result_chip.text == ("WIN" if won else "DEFEAT"), "Story_result_chip_matches_actual_outcome")
		check(await choose("Return to Story" if won else "Back Home"), "actual_results_return_to_Story_UI")
		check(await wait_route("StoryCampaignScene.tscn"), "results_return_to_Story")
		check(campaign.progress.routes[campaign.progress.selected_route].completed.size() == initial_completed.size() + (1 if won else 0), "canonical_completion_prefix_matches_outcome")
		check(await choose("Resume Save"), "real_resume_after_combat_save")
		check(campaign.last_error.is_empty(), "actual_outcome_saved_and_authenticated")
	var dialogue = root.get_node("StoryDialogue")
	check(not dialogue.is_busy() and not dialogue._panel.visible, "no_old_battle_dialogue_leaks_to_Story")
	var route: Dictionary = campaign.progress.routes[campaign.progress.selected_route]
	observations["saved"] = {"node": campaign.current_node().get("id", ""), "body": campaign.progress.presentation,
		"completed": route.completed.duplicate(), "receipts": route.receipts.duplicate(true), "checkpoint": campaign.progress.get("checkpoint", {}).duplicate(true)}
	await frames(90)
	check(route_is("StoryCampaignScene.tscn"), "old_callbacks_cannot_redirect_returned_Story")
	finish()

func public_cancel() -> void:
	var event := InputEventAction.new(); event.action = "ui_cancel"; event.pressed = true
	Input.parse_input_event(event); await process_frame
	event = event.duplicate(); event.pressed = false; Input.parse_input_event(event); await frames(2)

func finish() -> void:
	keys([])
	observations["combat"] = {"contacts": contacts, "stock_losses": losses, "moves": move_counts,
		"guard_frames": guard_frames, "input_count": inputs.size(), "frames_bound": 11400,
		"player_damage_or_stock_written": false, "result_injected": false, "CPU_overridden": false, "actor_samples": actor_samples, "invulnerable_transitions": invulnerable_transitions, "stale_invulnerability": stale_invulnerability, "ledge_move_leaks": ledge_move_leaks}
	observations["combat"]["last_trace"] = trace.slice(maxi(0, trace.size()-4))
	var active_trace: Array = trace.filter(func(row): return row.active)
	observations["combat"]["last_active_trace"] = active_trace.slice(maxi(0, active_trace.size()-4))
	var data := {"PASS": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations,
		"inputs": inputs, "trace": trace, "scope": "Actual canonical Story UI/combat, active normal CPU, isolated application-created signed save and real process restart. Public assets/headless; no native visual/art/device/full-campaign acceptance."}
	var filename := "STORY_ENCOUNTER_PLAY.json" if pass_name == "story-play" else "STORY_ENCOUNTER_RESTART.json"
	if pass_name == "story-controls": filename = "STORY_ENCOUNTER_CONTROLS.json"
	var file := FileAccess.open(output.path_join(filename), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ")); file.close()
	quit(0 if failures.is_empty() else 1)
