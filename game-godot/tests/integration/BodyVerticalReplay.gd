extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Real public Training actors versus an isolated owned world. No damage,
## position, hitstun, winner or move grant. No shipping backend replacement.
var evidence: Dictionary = {}
var native_contacts: Array = []
var resolved_jab: Dictionary = {}
var trial
var pair_inputs: Array = [{}, {}]
var parity_rows: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated body/vertical profile required"); quit(2); return
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	if not await fresh_training(): finish(); return
	keys(["attack"]); await frames(2); keys([])
	check(battle.fighter1.move_runner.active and battle.fighter1.move_runner.current_move_id() == "jab_1", "ordinary_source_input_resolves_canonical_jab")
	resolved_jab = battle.fighter1.move_runner.move_data.duplicate(true)
	if resolved_jab.is_empty(): finish(); return
	# New genuine scene resets normal practice state/stale history; no seeded
	# positions or damage. Retained move must match the canonical BASE resolver.
	if not await fresh_training(): finish(); return
	var script = load("res://scripts/net/experimental/flat_combat_trial.gd")
	trial = script.new(); root.add_child(trial)
	var stage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages/training-grid.json"))
	check(trial.configure_from_live(battle.fighter1, battle.fighter2, stage, 822, resolved_jab), "bind_actual_geometry_and_retained_verified_BASE_jab")
	if not trial.failure.is_empty(): evidence.failure = trial.failure; trial.free(); finish(); return
	for actor in [battle.fighter1, battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(func(a,d,info):
			native_contacts.append({"attacker":a.fighter_id, "defender":d.fighter_id, "info":info.duplicate(true), "velocity":d.velocity, "hitstun":d.hitstun_remaining, "hitstop":d._hitstop, "di":d._di_strength}))
	await physics_frame
	var neutral := command()
	var walk := command(0.65)
	var approach := 0
	for i in range(180):
		if trial.actors[1].position.x - trial.actors[0].position.x < 61.0: break
		if not await both_step(walk, neutral): break
		approach += 1
	for i in range(12):
		if not await both_step(neutral, neutral): break
	var checkpoint: Dictionary = trial.capture()
	var history: Array = []
	for i in range(48):
		var first: Dictionary = command(0.0, i == 0)
		history.append({"frame":trial.frame + 1,"p1":first,"p2":neutral.duplicate(true)})
		if not await both_step(first, neutral): break
	var baseline: Dictionary = trial.capture()
	var body_events: Array = trial.events.duplicate(true)
	check(trial.failure.is_empty(), "actual_body_path_supported:" + trial.failure)
	check(native_contacts.size() == 1 and body_events.size() == 1, "one_real_native_and_one_candidate_body_contact")
	if native_contacts.size() == 1 and body_events.size() == 1:
		var native: Dictionary = native_contacts[0]
		var candidate: Dictionary = body_events[0]
		check(candidate.contact_result == "hit" and candidate.damage_applied > 0.0 and candidate.actual_defender_state == "hurt_light", "real_HitResolver_body_damage_and_hurt_state")
		check(is_equal_approx(float(native.info.damage_applied), float(candidate.damage_applied)) and native.info.actual_launch.is_equal_approx(candidate.actual_launch) and native.info.move_frame == candidate.move_frame and native.info.actual_defender_state == candidate.actual_defender_state, "production_contact_damage_launch_active_frame_and_hurt_parity")
		check(is_equal_approx(float(battle.fighter2.damage_percent), float(trial.actors[1].damage_percent)) and battle.fighter1.combo_count == trial.actors[0].combo_count and is_equal_approx(float(battle.fighter1.aura), float(trial.actors[0].aura)), "production_damage_combo_and_earned_aura_parity")
		check(trial.restore(checkpoint), "body_history_atomic_restore")
		check(trial.last_retired_events == body_events, "discarded_body_intent_retired")
		for step in history:
			if not trial.advance_owned(trial.epoch, step.frame, step.p1, step.p2): break
		check(trial.capture() == baseline, "same_inputs_exact_body_damage_DI_hurt_hitstop_and_recovery_replay")
		check(trial.restore(checkpoint), "restore_before_changed_defensive_input")
		var changed := 0
		for step in history:
			var second: Dictionary = step.p2.duplicate(true)
			# One confirmed contact frame gets one fresh Shield press. No state
			# or result injection and no invented extension of the parry window.
			if step.frame == candidate.gameplay_frame: second.shield = true; changed += 1
			if not trial.advance_owned(trial.epoch, step.frame, step.p1, second): break
		check(changed == 1 and trial.events.size() == 1 and trial.events[0].contact_result in ["shield", "parry"] and trial.actors[1].damage_percent == 0.0, "one_changed_public_input_produces_legitimate_defended_alternative_history")
		evidence["body"] = {"native":native, "candidate":candidate, "alternative":trial.events.duplicate(true), "snapshot_frame":checkpoint.frame, "replayed_steps":history.size(), "approach_steps":approach}
	# Independent ordinary jump, double jump and landing, at unchanged spawn
	# spacing. Avoid relying on a low-strength jab to create an exaggerated lift.
	trial.free(); trial = null
	if not await fresh_training(): finish(); return
	trial = script.new(); root.add_child(trial)
	check(trial.configure_from_live(battle.fighter1, battle.fighter2, stage, 823, resolved_jab), "fresh_vertical_world_uses_same_verified_source_contract")
	await physics_frame
	var jump_history: Array = []
	var airborne_snapshot: Dictionary = {}
	var saw_air := false; var saw_double := false; var saw_landing := false
	for i in range(105):
		var second := command(0.0, false, false, i < 8 or (i >= 16 and i < 20))
		jump_history.append({"frame":trial.frame + 1,"p1":neutral.duplicate(true),"p2":second})
		if not await both_step(neutral, second): break
		saw_air = saw_air or not trial.actors[1].grounded
		saw_double = saw_double or trial.actors[1].state_machine.current_state == "double_jump"
		saw_landing = saw_landing or trial.actors[1].state_machine.current_state == "land"
		if i == 22: airborne_snapshot = trial.capture()
	var vertical_end: Dictionary = trial.capture()
	check(trial.failure.is_empty() and saw_air and saw_double and saw_landing and trial.actors[1].grounded, "ordinary_full_jump_double_jump_and_landing_complete")
	check(not airborne_snapshot.is_empty() and not airborne_snapshot.actors[1].grounded and airborne_snapshot.actors[1].velocity.y != 0.0, "snapshot_contains_actual_nonzero_airborne_motion")
	if not airborne_snapshot.is_empty():
		check(trial.restore(airborne_snapshot), "restore_airborne_root_velocity_jump_budget_floor_and_landing_state")
		for step in jump_history:
			if step.frame <= airborne_snapshot.frame: continue
			if not trial.advance_owned(trial.epoch, step.frame, step.p1, step.p2): break
		check(trial.capture() == vertical_end, "same_inputs_exact_airborne_through_landing_replay")
		var poison := airborne_snapshot.duplicate(true); poison.actors[1].floor_normal = Vector2.UP
		check(not trial.restore(poison) and trial.capture() == vertical_end, "contradictory_airborne_floor_rejected_atomically")
		poison = airborne_snapshot.duplicate(true); poison.actors[1].current_input.jump = "bad"
		check(not trial.restore(poison) and trial.capture() == vertical_end, "malformed_historical_jump_input_rejects_entire_restore")
	var maxima := {"position":0.0,"velocity":0.0,"floor_mismatch":0,"state_mismatch":0}
	for row in parity_rows:
		maxima.position = maxf(maxima.position, row.position_delta)
		maxima.velocity = maxf(maxima.velocity, row.velocity_delta)
		if not row.floor_agrees: maxima.floor_mismatch += 1
		if not row.state_agrees: maxima.state_mismatch += 1
	# Record raw parity, never raise a tolerance or alter gameplay to hide it.
	# CharacterBody's existing safe_margin bounds its floor separation; the
	# candidate uses the exact top plane. Integration remains experimental.
	check(maxima.position <= float(battle.fighter2.safe_margin) * 2.0 and maxima.velocity < 0.001 and maxima.floor_mismatch == 0 and maxima.state_mismatch == 0, "production_fixed_step_motion_parity_with_native_safe_margin_only")
	evidence["vertical"] = {"snapshot":airborne_snapshot,"end":vertical_end,"steps":jump_history.size()}
	evidence["parity"] = {"maxima":maxima,"native_safe_margin":battle.fighter2.safe_margin,"rows":parity_rows}
	check(JSON.stringify(campaign.progress) == story_before, "isolated_public_profiles_preserve_earned_Story")
	trial.free(); trial = null
	finish()

func command(axis: float = 0.0, attack: bool = false, shield: bool = false, jump: bool = false) -> Dictionary:
	return {"axis":axis,"attack":attack,"shield":shield,"jump":jump,"up":false,"down":false}

func set_pair_input(index: int, input: Dictionary) -> void:
	var old: Dictionary = pair_inputs[index]
	for action in ["left","right","attack","shield","jump","up","down"]:
		var strength: float = maxf(0.0, -float(input.axis)) if action == "left" else maxf(0.0,float(input.axis)) if action == "right" else 1.0 if bool(input.get(action,false)) else 0.0
		var previous: float = float(old.get(action,0.0))
		if strength == previous: continue
		if strength > 0.0: Input.action_press("p%d_%s" % [index + 1,action],strength)
		else: Input.action_release("p%d_%s" % [index + 1,action])
		old[action] = strength
	pair_inputs[index] = old

func both_step(first: Dictionary, second: Dictionary) -> bool:
	set_pair_input(0, first); set_pair_input(1, second)
	var ok: bool = trial.advance_owned(trial.epoch, trial.frame + 1, first, second)
	await physics_frame # Previous native frame is now closed, before the next actors tick.
	for i in range(2):
		var native = battle.fighter1 if i == 0 else battle.fighter2
		var actor = trial.actors[i]
		parity_rows.append({"epoch":trial.epoch,"frame":trial.frame,"slot":i+1,"native_position":native.position,"candidate_position":actor.position,"native_velocity":native.velocity,"candidate_velocity":actor.velocity,"native_state":native.state_machine.current_state,"candidate_state":actor.state_machine.current_state,"position_delta":native.position.distance_to(actor.position),"velocity_delta":native.velocity.distance_to(actor.velocity),"floor_agrees":native.is_on_floor() == actor.grounded,"state_agrees":native.state_machine.current_state == actor.state_machine.current_state})
	return ok

func fresh_training() -> bool:
	keys([])
	for slot in range(2): set_pair_input(slot, command())
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
		check(false,"fresh_real_training_scene"); return false
	battle = current_scene
	await frames(120)
	return true

func finish() -> void:
	keys([])
	for slot in range(2): set_pair_input(slot, command())
	var result := {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Real public Training CharacterBody actors and isolated owned world, canonical ordinary jab, source contact/DI/hurt and full/double jump/landing. Same-world body/air restore/replay and one changed defensive input. NOT enabled in shipping LAN; no complete world/projectile/grab/edge rollback, active CPU, rendered native/audio/device/art or human acceptance.","HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file := FileAccess.open(output.path_join("BODY_VERTICAL_REPLAY.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  ")); file.close()
	print("BODY_VERTICAL_REPLAY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
