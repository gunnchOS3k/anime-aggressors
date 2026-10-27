extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Actual LAN stock loss/respawn with ordinary RIGHT and real pause UI.
## Declared walk-off, NOT attack-earned KO or complete combat rollback.
var lan
var side := ""
var port := 27834
var stock_events: Array = []
var respawn_events: Array = []
var deadline_observations: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
		if arg.begins_with("--lan-role="): side = arg.trim_prefix("--lan-role=")
		if arg.begins_with("--lan-port="): port = int(arg.trim_prefix("--lan-port="))
	if output.is_empty() or side not in ["host", "guest"] or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Explicit isolated LAN deadline check required"); quit(2); return
	lan = root.get_node("LanSession")
	if side == "host": await host_run()
	else: await guest_run()
	finish()

func host_run() -> void:
	var gs = root.get_node("GameState")
	gs.p1_fighter_id = "kaia-windrow"; gs.p1_body_variant = "female"
	gs.p2_fighter_id = "rook-ironside"; gs.p2_body_variant = "female"
	gs.stage_id = "training-grid"; gs.stocks = 3; gs.ruleset_id = "stock-3"; gs.match_type = "stock"; gs.match_timer_seconds = 180
	check(lan.host(port, "127.0.0.1") == OK, "real_ENet_respawn_host")
	var ready = FileAccess.open(output.path_join("HOST_READY"), FileAccess.WRITE); ready.store_string("ready"); ready.close()
	for i in range(600):
		await physics_frame
		if lan.guest_pick_ready: break
	check(lan.start_match(), "legal_stock_match_starts")
	for i in range(420):
		await physics_frame
		if active_battle(): break
	if not active_battle(): check(false, "actual_BattleScene"); return
	battle = current_scene
	var p = battle.fighter2
	check(p.use_network_physics_clock and battle.fighter1.use_network_physics_clock, "only_host_actors_own_fixed_network_deadlines")
	p.koed.connect(func():stock_events.append({"clock":p._network_clock,"stocks":p.stocks,"round_clock":battle._network_round_clock,"ko_deadline":battle._network_ko_deadline}))
	p.respawned.connect(func():respawn_events.append({"clock":p._network_clock,"state":p.state_machine.current_state,"invincible":p.invincible}))
	var pending_second_respawn: Array = []
	battle._battle_sim.frame_completed.connect(func(_frame):
		if stock_events.size() == 2 and not p._network_deadlines.is_empty() and pending_second_respawn.is_empty(): pending_second_respawn.append(p.capture_network_deadlines()))
	# A real jump must retain its momentum through the same public pause UI.
	# No velocity/state/root assignment: paused CharacterBody owns the snapshot.
	var jumper = battle.fighter1
	for i in range(90):
		if jumper.is_on_floor() and jumper.state_machine.can_move(): break
		await physics_frame
	keys(["jump"]); await frames(2); keys([])
	for i in range(45):
		if jumper.velocity.y < -50 and not jumper.is_on_floor(): break
		await physics_frame
	check(jumper.velocity.y < -50 and not jumper.is_on_floor(), "ordinary_host_jump_has_real_ascending_momentum")
	var jump_position: Vector2 = jumper.position
	var jump_velocity: Vector2 = jumper.velocity
	var pause_jump = InputEventAction.new(); pause_jump.action = "ui_cancel"; pause_jump.pressed = true; Input.parse_input_event(pause_jump)
	await process_frame
	pause_jump = pause_jump.duplicate(); pause_jump.pressed = false; Input.parse_input_event(pause_jump)
	for i in range(30):
		if battle._paused and battle._pause_panel != null: break
		await process_frame
	check(battle._paused and battle._pause_panel != null, "real_pause_during_ascending_jump")
	if not battle._paused: return
	# Input.parse_input_event queues unhandled input. One ordinary physics
	# tick can finish before the pause UI handles that request. Freeze from
	# its OBSERVED owning boundary, while still rejecting the old zeroing bug.
	var paused_jump_position: Vector2 = jumper.position
	var paused_jump_velocity: Vector2 = jumper.velocity
	check(paused_jump_velocity.y < -50, "pause_keeps_nonzero_ascending_momentum")
	await frames(18)
	deadline_observations.append({"case":"ascending_jump_pause", "position_at_request":[jump_position.x,jump_position.y], "position_at_pause":[paused_jump_position.x,paused_jump_position.y], "position_paused":[jumper.position.x,jumper.position.y], "velocity_at_request":[jump_velocity.x,jump_velocity.y], "velocity_at_pause":[paused_jump_velocity.x,paused_jump_velocity.y], "velocity_paused":[jumper.velocity.x,jumper.velocity.y]})
	check(jumper.position == paused_jump_position and jumper.velocity == paused_jump_velocity, "pause_preserves_actual_airborne_position_and_velocity")
	battle._pause_resume_button.grab_focus(); await accept_focused()
	await frames(4)
	check(not battle._paused and jumper.velocity.y < 0 and jumper.position.y < paused_jump_position.y, "resume_continues_original_ascent_instead_of_erasing_momentum")
	for i in range(600):
		await physics_frame
		if not stock_events.is_empty(): break
	check(stock_events.size() == 1 and p.stocks == 2 and not battle._match_finished, "ordinary_walkoff_loses_one_real_stock_without_terminal_result")
	await frames(4)
	var captured: Dictionary = p.capture_network_deadlines()
	deadline_observations.append(captured)
	check(captured.pending.size() == 1 and captured.pending[0].kind == "respawn" and p.invincible, "actual_respawn_has_serializable_authoritative_deadline")
	# Atomic rejection and restoring the IDENTICAL current queue cannot move
	# the deadline or actor. No historical rewind of a partially restored actor.
	var invalid: Dictionary = captured.duplicate(true); invalid.owner.instance = 0
	check(not p.restore_network_deadlines(invalid) and p.capture_network_deadlines() == captured, "foreign_deadline_restore_rejected_atomically")
	check(p.restore_network_deadlines(captured) and respawn_events.is_empty(), "same_boundary_deadline_restore_has_no_immediate_callback")
	var cancel = InputEventAction.new(); cancel.action = "ui_cancel"; cancel.pressed = true; Input.parse_input_event(cancel)
	await process_frame
	cancel = cancel.duplicate(); cancel.pressed = false; Input.parse_input_event(cancel)
	for i in range(30):
		if battle._paused and battle._pause_panel != null: break
		await process_frame
	check(battle._paused and battle._pause_panel != null, "real_host_pause_UI")
	if not battle._paused: return
	var paused_queue: Dictionary = p.capture_network_deadlines()
	var paused_position: Vector2 = p.position
	var paused_round: Array = [battle._network_round_clock, battle._network_ko_deadline, battle._ko_lock]
	await frames(18)
	deadline_observations.append({"case":"real_pause", "before":paused_queue, "after":p.capture_network_deadlines(), "position_before":paused_position, "position_after":p.position, "round_before":paused_round, "round_after":[battle._network_round_clock,battle._network_ko_deadline,battle._ko_lock]})
	check(p.capture_network_deadlines() == paused_queue, "pause_holds_serialized_fighter_deadline_clock")
	check(p.position == paused_position, "pause_holds_actual_CharacterBody_position")
	check(p.capture_network_deadlines() == paused_queue and p.position == paused_position and respawn_events.is_empty(), "paused_physics_does_not_advance_respawn_or_movement")
	check([battle._network_round_clock,battle._network_ko_deadline,battle._ko_lock] == paused_round, "paused_round_cannot_expire_authoritative_KO_lock")
	# Focused real Resume button owns the input event.
	battle._pause_resume_button.grab_focus(); await accept_focused()
	check(not battle._paused, "real_resume_UI_restarts_gameplay_clock")
	for i in range(120):
		await physics_frame
		if not respawn_events.is_empty(): break
	check(respawn_events.size() == 1 and not p.invincible and p.stocks == 2, "actual_respawn_completes_once_without_new_stock_loss")
	if not respawn_events.is_empty() and not stock_events.is_empty():
		check(int(respawn_events[0].clock) - int(stock_events[0].clock) == 72, "original_1_2_second_respawn_uses_exactly_72_actor_physics_steps")
	check(p._network_deadlines.is_empty(), "expired_respawn_event_removed_before_dispatch")
	check(not battle._ko_lock and not stock_events.is_empty() and int(stock_events[0].ko_deadline) - int(stock_events[0].round_clock) == 48, "original_KO_lock_is_named_48_step_online_deadline")
	# A SECOND ordinary walk-off begins another real respawn. The guest
	# leaves while that deadline is pending; closure must cancel it.
	for i in range(600):
		await physics_frame
		if stock_events.size() == 2: break
	check(stock_events.size() == 2 and p.stocks == 1 and not pending_second_respawn.is_empty(), "second_ordinary_stock_loss_has_pending_deadline_before_disconnect")
	deadline_observations.append_array(pending_second_respawn)
	for i in range(120):
		await physics_frame
		if lan.guest_id == 0: break
	await frames(80)
	check(battle._network_abandoned and p.combat_closed and p._network_deadlines.is_empty() and respawn_events.size() == 1 and not battle._match_finished, "abandoned_match_cannot_reopen_from_late_deadline")
	root.get_node("SceneRouter").go("main_menu"); await frames(5)

func guest_run() -> void:
	root.get_node("GameState").p1_fighter_id = "juno-spark"
	root.get_node("GameState").p1_body_variant = "male"
	check(lan.join("127.0.0.1", port) == OK, "real_ENet_respawn_guest")
	var saw_respawn := false
	var recovered := false
	var second_respawn := false
	for i in range(1800):
		await physics_frame
		if lan.latest.is_empty() or not lan.latest.get("active", false): continue
		var row: Dictionary = lan.latest.actors[1]
		keys(["right"] if int(row.stocks) == 3 or (recovered and int(row.stocks) == 2) else [])
		if int(row.stocks) == 2 and row.state == "respawn": saw_respawn = true
		if saw_respawn and row.state != "respawn" and int(row.stocks) == 2:
			recovered = true
		if recovered and int(row.stocks) == 1 and row.state == "respawn":
			second_respawn = true; break
	keys([])
	check(saw_respawn and recovered, "guest_observes_real_stock_respawn_and_recovery")
	check(second_respawn, "guest_disconnects_during_second_legitimate_pending_respawn")
	check(current_scene.fighter2.combat_closed and not current_scene.fighter2.use_network_physics_clock, "guest_replica_never_runs_authoritative_deadline_callbacks")
	lan.stop(); await frames(10)

func finish() -> void:
	keys([])
	var result := {"PASS":failures.is_empty(), "role":side, "checks":checks, "failures":failures, "stock_events":stock_events, "respawn_events":respawn_events, "deadline_observations":deadline_observations,
		"scope":"Actual two-process ordinary jump/pause/resume momentum, walkoff, unchanged72-step online respawn, same-boundary atomic deadline restoration, retirement on abandonment. NOT attack-earnedKO, historical physics/contact resimulation, native visuals or human approval.",
		"HUMAN_ART_APPROVED":false, "RC2_READY":false, "V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("LAN_" + side.to_upper() + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	lan.stop()
	print("LAN_RESPAWN ", side, " ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
	quit(0 if failures.is_empty() else 1)
