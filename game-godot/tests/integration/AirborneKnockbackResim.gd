extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Isolated 2-human-seat airborne knockback + corrected-remote resimulation.
## Uses real Training actors only to bind geometry/jab. Never enables shipping LAN.
var evidence: Dictionary = {}
var resolved_jab: Dictionary = {}
var trial
var resim
const HumanSeats = preload("res://scripts/net/experimental/human_seat_policy.gd")
const Resim = preload("res://scripts/net/experimental/flat_combat_resim.gd")

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated airborne resim profile required"); quit(2); return
	var seat_probe: Dictionary = HumanSeats.self_test()
	check(bool(seat_probe.get("ok", false)), "human_seat_policy_excludes_bots_cpu_and_spectators")
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
	check(trial.configure_from_live(battle.fighter1, battle.fighter2, stage, 931, resolved_jab), "bind_actual_geometry_and_retained_verified_BASE_jab")
	if not trial.failure.is_empty(): evidence.failure = trial.failure; trial.free(); finish(); return
	resim = Resim.new()
	var roster: Array = [
		{"seat_id": 1, "role": "human", "fighter_id": "kaia-windrow", "peer_id": 1},
		{"seat_id": 2, "role": "human", "fighter_id": "juno-spark", "peer_id": 2},
		{"seat_id": 3, "role": "cpu", "fighter_id": "ember-vale", "peer_id": 0},
		{"seat_id": 99, "role": "spectator", "name": "Spec", "fighter_id": "", "peer_id": 9},
		{"seat_id": 4, "role": "bot", "fighter_id": "nix-calder", "peer_id": 0},
	]
	check(resim.bind(trial, roster), "bind_resim_requires_exactly_two_human_fighting_seats")
	check(not resim.shipping_backend_enabled(), "experimental_resim_keeps_shipping_LAN_backend_disabled")
	check(not bool(HumanSeats.validated_two_human_fighters([{"seat_id":1,"role":"bot","fighter_id":"kaia-windrow"},{"seat_id":2,"role":"spectator","fighter_id":""}]).ok), "bots_and_spectators_alone_never_validate_2p")
	await physics_frame
	var neutral := command()
	var walk := command(0.7)
	# Close distance while both remain grounded, then jump the defender and
	# jab immediately so contact occurs before landing.
	var approach := 0
	for i in range(180):
		# Stay close enough that a barely-airborne hurtbox still overlaps jab.
		if trial.actors[1].position.x - trial.actors[0].position.x < 52.0: break
		if not resim.advance_confirmed(walk, neutral): break
		approach += 1
	for i in range(3):
		if not resim.advance_confirmed(neutral, neutral): break
	# Start jab in the same window as jump squat so active frames meet the
	# first barely-airborne hurtbox instead of a high whiff.
	var pre_hit: Dictionary = trial.capture()
	var strike_history: Array = []
	for i in range(36):
		var first: Dictionary = command(0.0, i == 0)
		var second: Dictionary = command(0.0, false, false, i < 8)
		strike_history.append({"frame": trial.frame + 1, "p1": first, "p2": second})
		if not resim.advance_confirmed(first, second): break
	var baseline: Dictionary = trial.capture()
	var body_events: Array = trial.events.duplicate(true)
	check(trial.failure.is_empty(), "airborne_body_path_supported:" + trial.failure)
	check(body_events.size() == 1 and str(body_events[0].get("contact_result", "")) == "hit" and float(body_events[0].get("damage_applied", 0.0)) > 0.0, "one_airborne_body_contact_with_damage")
	if body_events.size() == 1 and str(body_events[0].get("contact_result", "")) == "hit":
		var hit: Dictionary = body_events[0]
		check(bool(hit.get("defender_airborne", false)), "contact_contract_marks_defender_airborne")
		check(not bool(pre_hit.actors[1].grounded) or bool(hit.get("defender_airborne", false)), "strike_path_uses_airborne_defender_contract")
		check(str(hit.get("actual_defender_state", "")) in ["hurt_light", "hurt_heavy", "launched", "hitstun", "tumble"], "airborne_hurt_or_launch_state")
		check(trial.actors[1].damage_percent > 0.0 and trial.actors[0].combo_count == 1, "airborne_damage_and_combo_applied")
		check(trial.restore(pre_hit), "restore_world_snapshot_before_airborne_contact")
		check(trial.last_retired_events == body_events, "discarded_airborne_hit_intent_retired")
		for step in strike_history:
			if not trial.advance_owned(trial.epoch, int(step.frame), step.p1, step.p2): break
		check(trial.capture() == baseline, "same_inputs_exact_airborne_knockback_replay")
		check(trial.restore(pre_hit), "restore_before_corrected_remote_di")
		resim = Resim.new()
		check(resim.bind(trial, roster), "rebind_resim_after_snapshot_restore")
		var contact_frame: int = int(hit.gameplay_frame)
		var di_frame: int = contact_frame + 1
		for step in strike_history:
			if int(step.frame) > contact_frame:
				break
			if not resim.advance_confirmed(step.p1, step.p2): break
		var predicted: Dictionary = neutral.duplicate(true)
		for step in strike_history:
			if int(step.frame) <= contact_frame:
				continue
			if int(step.frame) == di_frame:
				check(resim.advance_with_prediction(0, step.p1, predicted), "predict_remote_neutral_after_airborne_hit")
				var corrected: Dictionary = step.p2.duplicate(true)
				corrected["up"] = true
				corrected["jump"] = false
				var reconciliation: Dictionary = resim.correct_remote_input(di_frame, 1, corrected)
				check(bool(reconciliation.get("ok", false)) and bool(reconciliation.get("rolled_back", false)), "corrected_remote_di_triggers_owned_resim")
				check(int(reconciliation.get("rollback_count", 0)) >= 1, "rollback_count_increments")
				check(reconciliation.get("shipping_backend_enabled", true) == false, "resim_reconciliation_keeps_shipping_off")
				check(reconciliation.get("human_seats", []).size() == 2, "reconciliation_records_two_human_seats_only")
				evidence["reconciliation"] = reconciliation
				break
			else:
				if not resim.advance_confirmed(step.p1, step.p2): break
		check(trial.actors[1].damage_percent > 0.0, "corrected_path_retains_airborne_damage")
		evidence["airborne_hit"] = hit
		evidence["approach_steps"] = approach
		evidence["pre_hit_frame"] = pre_hit.frame
		evidence["baseline_frame"] = baseline.frame
		evidence["di_frame"] = di_frame
	check(JSON.stringify(campaign.progress) == story_before, "airborne_resim_preserves_earned_Story")
	if trial != null: trial.free(); trial = null
	finish()

func command(axis: float = 0.0, attack: bool = false, shield: bool = false, jump: bool = false, up: bool = false) -> Dictionary:
	return {"axis": axis, "attack": attack, "shield": shield, "jump": jump, "up": up, "down": false}

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
		"scope": "Isolated flat-trial airborne knockback, world snapshot restore, corrected remote DI resim, and 2-human-seat policy (bots/spectators excluded). Shipping LAN CharacterBody backend remains disabled. Not 8p, not art/device/human acceptance.",
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"shipping_backend_enabled": false,
	}
	var file := FileAccess.open(output.path_join("AIRBORNE_KNOCKBACK_RESIM.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("AIRBORNE_KNOCKBACK_RESIM ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
