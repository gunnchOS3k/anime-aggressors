extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Isolated experimental game-owned flat-floor world. Uses real source actors
## to bind approved geometry/movement and an ordinary-input resolved jab.
## It neither replaces BattleSim nor claims shipping CharacterBody parity.
const Trial = preload("res://scripts/net/experimental/flat_combat_trial.gd")
var result_evidence: Dictionary = {}

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated replay profile required"); quit(2); return
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	var gs = root.get_node("GameState")
	gs.begin_training(); gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = "female"; gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"; gs.stage_id = "training-grid"
	root.get_node("SceneRouter").go("training_battle")
	for i in range(180):
		await process_frame
		if route_is("TrainingBattleScene.tscn"): break
	check(route_is("TrainingBattleScene.tscn"), "actual_public_Training_scene")
	if not route_is("TrainingBattleScene.tscn"): finish(); return
	battle = current_scene
	await frames(120)
	var p = battle.fighter1; var d = battle.fighter2
	keys(["attack"]); await frames(2); keys([])
	check(p.move_runner.active and p.move_runner.current_move_id() == "jab_1", "ordinary_input_resolved_actual_canonical_jab")
	if not p.move_runner.active: finish(); return
	var stage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages/training-grid.json"))
	var trial = Trial.new(); root.add_child(trial)
	var configured: bool = trial.configure_from_live(p, d, stage, 417)
	check(configured, "bind_actual_source_geometry_movement_jab_and_epoch")
	if not configured: result_evidence["failure"] = trial.failure; trial.free(); finish(); return
	# The candidate is a separate actual Godot Node2D world, with no hidden
	# CharacterBody cache, native effects or listeners on the shipping actors.
	battle._battle_sim.set_paused(true)
	p.set_physics_process(false); d.set_physics_process(false)
	await process_frame
	var history: Array = []
	var neutral := {"axis":0.0, "attack":false, "shield":false}
	var held_guard := {"axis":0.0, "attack":false, "shield":true}
	var approach_steps := 0
	for i in range(180):
		if trial.actors[1].position.x - trial.actors[0].position.x < 61.0: break
		if not trial.advance({"axis":0.65, "attack":false, "shield":false}, held_guard): break
		approach_steps += 1
	for i in range(12):
		if not trial.advance(neutral, held_guard): break
	check(trial.failure.is_empty() and approach_steps > 5 and trial.actors[0].grounded and trial.actors[1].grounded, "multiple_real_candidate_fixed_steps_approach_stop_and_owned_floor")
	var checkpoint: Dictionary = trial.capture()
	for i in range(28):
		var first: Dictionary = neutral.duplicate(true); first.attack = i == 0
		var step := {"epoch":trial.epoch, "frame":trial.frame + 1, "p1":first, "p2":held_guard.duplicate(true)}
		history.append(step)
		if not trial.advance_owned(step.epoch, step.frame, step.p1, step.p2): break
	var baseline: Dictionary = trial.capture()
	var baseline_events: Array = trial.events.duplicate(true)
	check(trial.failure.is_empty(), "canonical_shield_path_supported_without_live_state_mutation:" + trial.failure)
	check(baseline_events.size() == 1 and baseline_events[0].get("contact_result", "") == "shield", "actual_production_HitResolver_makes_one_normal_shield_contact")
	if baseline_events.size() != 1:
		result_evidence = {"failure":trial.failure, "events":baseline_events, "approach_steps":approach_steps}
		trial.free(); finish(); return
	var contact: Dictionary = baseline_events[0]
	check(trial.restore(checkpoint), "complete_candidate_snapshot_restore")
	var retired: Array = trial.last_retired_events.duplicate(true)
	check(retired == baseline_events and trial.events.is_empty(), "discarded_contact_and_presentation_intent_retired")
	for step in history:
		if not trial.advance_owned(step.epoch, step.frame, step.p1, step.p2): break
	check(trial.capture() == baseline, "same_input_history_reproduces_entire_candidate_state_exactly")
	check(trial.events == baseline_events, "same_canonical_contact_replays_once_with_same_frame_and_identity")
	var poison: Dictionary = checkpoint.duplicate(true); poison.epoch = 418
	check(not trial.restore(poison) and trial.capture() == baseline, "foreign_epoch_restore_is_atomic")
	poison = checkpoint.duplicate(true); poison.actors[1].guard.clock = -1
	check(not trial.restore(poison) and trial.capture() == baseline, "malformed_second_actor_rejects_entire_historical_restore_atomically")
	check(not trial.advance_owned(trial.epoch + 1, trial.frame + 1, neutral, held_guard) and trial.capture() == baseline, "foreign_epoch_input_cannot_advance_world")
	check(not trial.advance_owned(trial.epoch, trial.frame, neutral, held_guard) and trial.capture() == baseline, "duplicate_or_reordered_input_frame_cannot_advance_world")
	check(trial.restore(checkpoint), "restore_before_late_input_correction")
	check(trial.last_retired_events == baseline_events, "repeated_restore_retires_exactly_the_discarded_contact_intent")
	var corrected_frame: int = int(contact.get("gameplay_frame", -1)) - 2
	var corrections := 0
	for step in history:
		var second: Dictionary = step.p2.duplicate(true)
		if step.frame == corrected_frame:
			second.shield = false; corrections += 1
		if not trial.advance_owned(step.epoch, step.frame, step.p1, second): break
	var corrected_events: Array = trial.events.duplicate(true)
	check(corrections == 1 and corrected_frame > checkpoint.frame, "exactly_one_frame_owned_delayed_Shield_release_changed")
	check(trial.failure.is_empty() and corrected_events.size() == 1 and corrected_events[0].get("perfect_guard", false), "actual_PerfectGuard_changes_normal_block_to_legal_fresh_press_parry")
	check(trial.capture() != baseline and trial.actors[1].shield_health > float(baseline.actors[1].shield_health), "alternative_history_has_correct_distinct_authoritative_shield_result")
	check(JSON.stringify(campaign.progress) == story_before and p.damage_percent == 0 and d.damage_percent == 0, "isolated_replay_never_changes_live_fighters_or_Story")
	result_evidence = {"baseline_contact":contact, "corrected_contacts":corrected_events, "corrected_input_frame":corrected_frame,
		"snapshot_frame":checkpoint.frame, "approach_steps":approach_steps, "replay_steps":history.size(), "retired_intents":retired,
		"source_move":p.move_runner.move_data.duplicate(true), "failure":trial.failure,
		"baseline_shield_health":baseline.actors[1].shield_health, "corrected_shield_health":trial.actors[1].shield_health,
		"production_LAN_enabled":false, "historical_CharacterBody_restored":false}
	trial.free()
	finish()

func finish() -> void:
	keys([])
	var result = {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "evidence":result_evidence,
		"scope":"Executed isolated source-owned flat-floor movement/contact world using source geometry, ordinary-input resolved canonical jab and production combat components. Complete candidate restore/replay and one corrected input; NOT shipping CharacterBody parity, full-world rollback, real delayed-packet LAN or native audiovisual/art/device acceptance.",
		"HUMAN_ART_APPROVED":false, "RC2_READY":false, "V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("FLAT_COMBAT_REPLAY.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("FLAT_COMBAT_REPLAY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
