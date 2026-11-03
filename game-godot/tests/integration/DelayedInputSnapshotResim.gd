extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Delayed remote input + owned snapshot restore against the isolated flat
## trial, using LanControls packet shapes through lan_resim_bridge. Proves a
## late guest correction matches an oracle tip. Shipping LAN backend stays off.
var evidence: Dictionary = {}
var resolved_jab: Dictionary = {}
var trial
var resim
var bridge
const Resim = preload("res://scripts/net/experimental/flat_combat_resim.gd")
const Bridge = preload("res://scripts/net/experimental/lan_resim_bridge.gd")
const DELAY_FRAMES := 4

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated delayed-input profile required"); quit(2); return
	var bridge_probe: Dictionary = Bridge.self_test()
	check(bool(bridge_probe.get("ok", false)), "lan_resim_bridge_round_trip_and_shipping_contract")
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	if not await fresh_training(): finish(); return
	keys(["attack"]); await frames(2); keys([])
	check(battle.fighter1.move_runner.active and battle.fighter1.move_runner.current_move_id() == "jab_1", "ordinary_source_input_resolves_canonical_jab")
	resolved_jab = battle.fighter1.move_runner.move_data.duplicate(true)
	if resolved_jab.is_empty(): finish(); return
	if not await fresh_training(): finish(); return
	var script = load("res://scripts/net/experimental/flat_combat_trial.gd")
	trial = script.new(); root.add_child(trial)
	var stage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages/training-grid.json"))
	check(trial.configure_from_live(battle.fighter1, battle.fighter2, stage, 944, resolved_jab), "bind_actual_geometry_and_retained_verified_BASE_jab")
	if not trial.failure.is_empty(): evidence.failure = trial.failure; trial.free(); finish(); return
	var roster: Array = [
		{"seat_id": 1, "role": "human", "fighter_id": "kaia-windrow", "peer_id": 1},
		{"seat_id": 2, "role": "human", "fighter_id": "juno-spark", "peer_id": 2},
		{"seat_id": 99, "role": "spectator", "name": "Spec", "fighter_id": "", "peer_id": 9},
		{"seat_id": 3, "role": "bot", "fighter_id": "ember-vale", "peer_id": 0},
	]
	resim = Resim.new()
	check(resim.bind(trial, roster), "bind_resim_two_human_seats_only")
	check(not resim.shipping_backend_enabled(), "experimental_resim_keeps_shipping_disabled")
	bridge = Bridge.new()
	check(bridge.bind_resim(resim), "bind_lan_bridge_to_disabled_shipping_resim")
	await physics_frame
	var neutral := command()
	var held_guard := command(0.0, false, true)
	var walk := command(0.65)
	for i in range(180):
		if trial.actors[1].position.x - trial.actors[0].position.x < 61.0: break
		if not resim.advance_confirmed(walk, held_guard): break
	for i in range(8):
		if not resim.advance_confirmed(neutral, held_guard): break
	var checkpoint: Dictionary = trial.capture()
	# Oracle: true guest shield held through the jab window.
	var oracle_history: Array = []
	for i in range(28):
		var first: Dictionary = command(0.0, i == 0)
		var second: Dictionary = held_guard.duplicate(true)
		oracle_history.append({"frame": trial.frame + 1, "p1": first, "p2": second})
		if not resim.advance_confirmed(first, second): break
	var oracle_tip: Dictionary = trial.capture()
	var oracle_events: Array = trial.events.duplicate(true)
	check(trial.failure.is_empty() and oracle_events.size() == 1 and str(oracle_events[0].get("contact_result", "")) == "shield", "oracle_shield_contact_established")
	if oracle_events.is_empty():
		finish(); return
	var contact_frame: int = int(oracle_events[0].gameplay_frame)
	# Predicted path: wrong open-guard remote at contact, continue DELAY frames,
	# then late LanControls correction restores owned snapshot and matches oracle.
	check(trial.restore(checkpoint), "restore_pre_strike_world_snapshot")
	resim = Resim.new()
	check(resim.bind(trial, roster), "rebind_resim_after_snapshot_restore")
	bridge = Bridge.new()
	check(bridge.bind_resim(resim), "rebind_lan_bridge_after_snapshot_restore")
	var predicted_open := neutral.duplicate(true)
	var delay_tip_frame: int = contact_frame + DELAY_FRAMES
	for step in oracle_history:
		var frame: int = int(step.frame)
		if frame < contact_frame:
			if not resim.advance_confirmed(step.p1, step.p2): break
		elif frame == contact_frame:
			# Mis-predict: guest was open on the contact frame.
			check(resim.advance_with_prediction(0, step.p1, predicted_open), "predict_wrong_open_guard_on_contact_frame")
		elif frame <= delay_tip_frame:
			# Keep advancing the mispredicted timeline until the late packet delay.
			if not resim.advance_confirmed(step.p1, step.p2): break
		else:
			break
	check(int(trial.frame) >= delay_tip_frame, "advanced_past_delay_window_before_late_packet")
	var wrong_events: Array = trial.events.duplicate(true)
	check(wrong_events.size() == 1 and str(wrong_events[0].get("contact_result", "")) == "hit", "mispredict_produced_body_hit_before_correction")
	var late_packet: Dictionary = Bridge.lan_packet_from_trial_input(int(trial.epoch), 9001, held_guard)
	check(Bridge.round_trip_ok(held_guard, int(trial.epoch), 9001), "late_packet_round_trips_lan_controls_shape")
	check(bridge.observe_guest_lan_packet(late_packet), "shadow_observer_accepts_valid_lan_packet")
	var reconciliation: Dictionary = bridge.correct_late_guest_packet(contact_frame, late_packet)
	check(bool(reconciliation.get("ok", false)) and bool(reconciliation.get("rolled_back", false)), "late_lan_packet_triggers_owned_resim")
	check(int(reconciliation.get("rollback_count", 0)) >= 1, "delayed_rollback_count_increments")
	check(reconciliation.get("shipping_backend_enabled", true) == false, "delayed_correction_keeps_shipping_off")
	check(bool(reconciliation.get("shipping_committed_states_untouched", false)), "shipping_committed_history_not_mutated")
	# After owned restore+resim, catch up any remaining oracle frames to the tip.
	for step in oracle_history:
		var frame: int = int(step.frame)
		if frame <= int(trial.frame):
			continue
		if not resim.advance_confirmed(step.p1, step.p2): break
	var corrected_tip: Dictionary = trial.capture()
	check(corrected_tip.events.size() == 1 and str(corrected_tip.events[0].get("contact_result", "")) == "shield", "late_correction_restores_oracle_shield_contact")
	check(is_equal_approx(float(corrected_tip.actors[1].damage_percent), float(oracle_tip.actors[1].damage_percent)), "late_correction_damage_matches_oracle")
	check(is_equal_approx(float(corrected_tip.actors[1].shield_health), float(oracle_tip.actors[1].shield_health)), "late_correction_shield_health_matches_oracle")
	check(int(corrected_tip.frame) == int(oracle_tip.frame), "late_correction_tip_frame_matches_oracle")
	# Shipping LAN contract: published host snapshots stay non-restorable.
	var lan = root.get_node_or_null("LanSession")
	if lan != null:
		var contract: Dictionary = bridge.assert_shipping_lan_contract({"rollback_restorable": false, "kind": "state"})
		check(bool(contract.get("ok", false)), "shipping_lan_snapshots_remain_non_restorable")
		# Opt-in observe hook is inert unless bound; bind shadow only for this test.
		lan.experimental_input_observer = Callable(bridge, "observe_guest_lan_packet")
		check(bridge.observe_guest_lan_packet(late_packet), "lan_session_opt_in_observer_receives_shadow_packet")
		lan.experimental_input_observer = Callable()
	check(JSON.stringify(campaign.progress) == story_before, "delayed_input_resim_preserves_earned_Story")
	evidence = {
		"delay_frames": DELAY_FRAMES,
		"contact_frame": contact_frame,
		"oracle_event": oracle_events[0],
		"wrong_events": wrong_events,
		"reconciliation": reconciliation,
		"oracle_frame": oracle_tip.frame,
		"corrected_frame": corrected_tip.frame,
		"shipping_backend_enabled": false,
	}
	if trial != null: trial.free(); trial = null
	finish()

func command(axis: float = 0.0, attack: bool = false, shield: bool = false, jump: bool = false) -> Dictionary:
	return {"axis": axis, "attack": attack, "shield": shield, "jump": jump, "up": false, "down": false}

func fresh_training() -> bool:
	keys([])
	var previous = current_scene
	var gs = root.get_node("GameState")
	gs.begin_training(); gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = "female"; gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"; gs.stage_id = "training-grid"
	root.get_node("SceneRouter").go("training_battle")
	for i in range(180):
		await process_frame
		if current_scene != previous and route_is("TrainingBattleScene.tscn"): break
	if not route_is("TrainingBattleScene.tscn") or current_scene == previous:
		check(false, "fresh_real_training_scene"); return false
	battle = current_scene
	await frames(120)
	return true

func finish() -> void:
	keys([])
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"evidence": evidence,
		"scope": "Delayed guest LanControls packet + owned flat-trial snapshot restore matching oracle shield tip. 2 human seats only. Shipping LAN CharacterBody rollback remains disabled; host committed states stay non-restorable. Not 8p/art/device/human acceptance.",
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"shipping_backend_enabled": false,
	}
	var file := FileAccess.open(output.path_join("DELAYED_INPUT_SNAPSHOT_RESIM.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("DELAYED_INPUT_SNAPSHOT_RESIM ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
