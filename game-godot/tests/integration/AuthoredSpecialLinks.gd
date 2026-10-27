extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Authored manifest links, existing runtime frames, actual ordinary controls.
## Quiet human defender is a declared mechanical fixture, not active-CPU proof.
const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
var rows: Array = []
var starts: Array = []
var stage_contacts: Array = []
var _juno_defender
var _juno_source_activation := -1
var _juno_tracking := false
var _juno_last_control := false
var _juno_control_edges: Array = []

func record_contact(a, d, info: Dictionary) -> void:
	super.record_contact(a, d, info)
	stage_contacts.append({"frame":Engine.get_physics_frames(), "move":info.get("move_id", ""),
		"result":info.get("contact_result", ""), "damage":info.get("damage", 0.0),
		"damage_applied":info.get("damage_applied", 0.0), "activation":info.get("attack_activation_id", -1),
		"defender_in_hitstun_before":info.get("defender_in_hitstun_before", false),
		"defender_state":d.state_machine.current_state, "contact_event":info.get("combat_event_id", "")})
	if a.fighter_id == "juno-spark" and str(info.get("move_id", "")) == "jab_finisher" and int(info.get("attack_activation_id", -1)) == _juno_source_activation and str(info.get("contact_result", "")) == "hit":
		_juno_tracking = true
		_juno_last_control = false
		_juno_control_edges.append({"frame":Engine.get_physics_frames(), "can_act":false, "state":d.state_machine.current_state, "kind":"source_body_hit"})

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated profile/output required"); quit(2); return
	check(Catalog.roster_ids().size() == 9, "move_learning_includes_all_nine_canonical_fighters")
	for fighter in ["ember-vale", "vesper-nyx", "yin", "yang"]:
		await probe(fighter, "contact")
	await probe("ember-vale", "whiff")
	await probe("ember-vale", "shield")
	for outcome in ["contact", "axis_only", "shield", "expired", "released_tap"]:
		await probe_juno_dash(outcome)
	await probe_vesper_dodge()
	finish()

func probe(fighter: String, outcome: String) -> void:
	keys([]); Input.action_release("p2_shield")
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.p1_fighter_id = fighter; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = "female" if fighter in ["ember-vale", "yang"] else "male"
	gs.p2_body_variant = "male"; gs.p1_is_cpu = false; gs.p2_is_cpu = false
	gs.stage_id = "training-grid"; gs.stocks = 3; gs.match_timer_seconds = 180; gs.battle_eval_mode = false
	var previous = current_scene
	root.get_node("SceneRouter").go("battle")
	for i in range(420):
		await physics_frame
		if current_scene != previous and active_battle(): break
	check(current_scene != previous and active_battle(), fighter + ":" + outcome + ":actual_BattleScene")
	if not active_battle(): return
	battle = current_scene
	var p = battle.fighter1; var d = battle.fighter2
	starts.clear(); stage_contacts.clear()
	# Countdown suspends grounded movement/gravity. A distant whiff must wait
	# for genuine landing before requesting a grounded jab (no root injection).
	for i in range(90):
		if p.is_on_floor() and d.is_on_floor(): break
		await physics_frame
	check(p.is_on_floor() and d.is_on_floor(), fighter + ":" + outcome + ":natural_grounded_start")
	p.move_runner.move_started.connect(func(mid): starts.append({"move":mid,"frame":Engine.get_physics_frames()}))
	p.hit_resolver.hit_confirmed.connect(record_contact)
	if outcome == "shield": Input.action_press("p2_shield"); await frames(20)
	var attempted := false
	var eligible_before := false
	var defender_recovered := false
	var control_frames: Array = []
	var attempted_frame := -1
	var source_activation := -1
	var target := "down_special" if fighter == "vesper-nyx" else "side_special"
	for jab in ["jab_1", "jab_2", "jab_finisher"]:
		if outcome != "whiff":
			for i in range(180):
				var dx: float = d.position.x - p.position.x
				if absf(dx) < 46 and p.is_on_floor() and d.is_on_floor(): break
				keys(["right" if dx > 0 else "left"]); await physics_frame
		keys([])
		# Ground contact is not yet control return: honor real landing recovery.
		for i in range(120):
			if p.is_on_floor() and p.state_machine.can_attack() and p._hitstop <= 0: break
			await physics_frame
		check(p.is_on_floor() and p.state_machine.can_attack(), fighter + ":" + outcome + ":legal_attack_control_" + jab)
		keys(["attack"]); await frames(2); keys([])
		for i in range(30):
			if p.move_runner.active and p.move_runner.current_move_id() == jab: break
			await physics_frame
		check(p.move_runner.current_move_id() == jab, fighter + ":" + outcome + ":public_" + jab)
		if jab != "jab_finisher":
			for i in range(100):
				await physics_frame
				if not p.move_runner.active: break
			continue
		source_activation = p.move_runner.activation_id
		for i in range(100):
			if not p.move_runner.active or p.move_runner.current_move_id() != jab: break
			if p.move_runner.confirmed_body_hit and (d.state_machine.can_move() or d.state_machine.can_attack()): defender_recovered = true
			for window in p.move_runner.move_data.get("cancel_windows", []):
				if str(window.get("to", "")) != target: continue
				if (outcome != "contact" or p.move_runner.confirmed_body_hit) and p._hitstop <= 0 and p.move_runner.total_frame >= int(window.start) and p.move_runner.total_frame <= int(window.end):
					eligible_before = p.move_runner.can_cancel_to(target)
					attempted_frame = p.move_runner.total_frame
					attempted = true
					keys(["special", "down" if target == "down_special" else "right"])
					break
			if attempted: break
			await physics_frame
		await frames(2); keys([])
		for i in range(60 if outcome == "contact" else 5):
			control_frames.append({"frame":Engine.get_physics_frames(), "can_act":d.state_machine.can_move() or d.state_machine.can_attack(), "state":d.state_machine.current_state})
			await physics_frame
	check(attempted, fighter + ":" + outcome + ":actual_resolved_window_input")
	var links: Array = p.authored_cancel_history.filter(func(row): return row.from == "jab_finisher" and row.to == target and row.activation == source_activation)
	var target_started: bool = starts.any(func(row): return row.move == target)
	if outcome == "contact":
		check(eligible_before and links.size() == 1 and target_started, fighter + ":body_hit_special_link_activates_once")
		check(stage_contacts.any(func(row):return row.move == "jab_finisher" and row.result == "hit"), fighter + ":real_finisher_contact")
	else:
		check(not eligible_before and links.is_empty() and not target_started, fighter + ":" + outcome + ":special_cancel_rejected")
		if outcome == "shield":
			check(stage_contacts.any(func(row): return row.result == "shield") and d.damage_percent == 0, "real_shield_contacts_without_body_damage")
		else: check(stage_contacts.is_empty() and d.damage_percent == 0, "real_whiff_without_contact_or_damage")
	var catalog: Dictionary = Catalog.build_fighter_catalog(fighter)
	var finisher: Array = catalog.entries.filter(func(e):return e.move_id == "jab_finisher")
	check(not finisher.is_empty() and finisher[0].authored_links.any(func(link):return link.to == target), fighter + ":learning_guide_carries_actual_manifest_link")
	var finisher_hits: Array = stage_contacts.filter(func(row):return row.move == "jab_finisher" and row.result == "hit")
	var target_hits: Array = stage_contacts.filter(func(row):return row.move == target and row.result == "hit")
	var link_status := "No subsequent target contact observed"
	if not finisher_hits.is_empty() and not target_hits.is_empty():
		var recovered_between: bool = defender_recovered or control_frames.any(func(row): return row.can_act and int(row.frame) < int(target_hits[0].frame))
		link_status = "Escapable follow-up: defender control returned before target contact" if recovered_between else "Observed contact before defender control returned, quiet defender only; active-opponent acceptance pending"
	rows.append({"fighter":fighter,"body":gs.p1_body_variant,"facing":p.facing,"case":outcome,"target":target,
		"source":"res://data/moves/"+fighter+".json#jab_finisher.cancel_windows", "attempt_move_frame":attempted_frame,
		"eligible":eligible_before,"links":links.duplicate(true),"target_started":target_started,"contacts":stage_contacts.duplicate(true),
		"defender_control_returned_before_cancel":defender_recovered,
		"defender_control_trace":control_frames, "combo_status":link_status, "move_starts":starts.duplicate(true)})
	keys([]); Input.action_release("p2_shield")

func _juno_control_changed(_from: String, _to: String) -> void:
	_observe_juno_control()

func _juno_step_completed(_frame: int) -> void:
	_observe_juno_control()

func _observe_juno_control() -> void:
	if not _juno_tracking or not is_instance_valid(_juno_defender): return
	var can_act: bool = _juno_defender.controls_enabled and _juno_defender._hitstop <= 0.0 and (_juno_defender.state_machine.can_move() or _juno_defender.state_machine.can_attack())
	if can_act == _juno_last_control: return
	_juno_last_control = can_act
	_juno_control_edges.append({"frame":Engine.get_physics_frames(), "can_act":can_act, "state":_juno_defender.state_machine.current_state, "kind":"control_edge"})

func _juno_ground_control(actor) -> bool:
	for i in range(120):
		if actor.is_on_floor() and actor.state_machine.can_attack() and actor._hitstop <= 0.0: return true
		await physics_frame
	return false

func probe_juno_dash(outcome: String) -> void:
	keys([]); Input.action_release("p2_shield")
	_juno_tracking = false
	_juno_source_activation = -1
	_juno_control_edges.clear()
	var prefix := "juno_high_aura:" + outcome + ":"
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.p1_fighter_id = "juno-spark"; gs.p2_fighter_id = "rook-ironside"
	gs.p1_body_variant = "female" if outcome in ["contact", "shield", "released_tap"] else "male"
	gs.p2_body_variant = "male"; gs.p1_is_cpu = false; gs.p2_is_cpu = false
	gs.stage_id = "training-grid"; gs.stocks = 3; gs.match_timer_seconds = 180; gs.battle_eval_mode = false
	var previous = current_scene
	root.get_node("SceneRouter").go("battle")
	for i in range(420):
		await physics_frame
		if current_scene != previous and active_battle(): break
	check(current_scene != previous and active_battle(), prefix + "actual_BattleScene")
	if current_scene == previous or not active_battle(): return
	battle = current_scene
	var p = battle.fighter1; var d = battle.fighter2
	_juno_defender = d
	starts.clear(); stage_contacts.clear()
	p.move_runner.move_started.connect(func(mid): starts.append({"move":mid, "frame":Engine.get_physics_frames(), "activation":p.move_runner.activation_id, "grounded":p.is_on_floor()}))
	p.hit_resolver.hit_confirmed.connect(record_contact)
	d.state_machine.state_changed.connect(_juno_control_changed)
	battle._battle_sim.frame_completed.connect(_juno_step_completed)
	check(await _juno_ground_control(p), prefix + "natural_ground_control")
	# Earn the test meter through the existing ordinary charge chord. No aura,
	# move, root, damage, opponent, timing or hitstun assignments occur here.
	keys(["shield", "special"])
	for i in range(240):
		await physics_frame
		if p.aura >= 64.0: break
	keys([]); await frames(2)
	var charged_aura: float = p.aura
	check(charged_aura >= 60.0 and charged_aura < 75.0, prefix + "ordinary_charge_reaches_high_aura_without_transform_or_super")
	var source_activation := -1
	var damage_before_finisher: float = d.damage_percent
	var aura_at_finisher := 0.0
	for jab in ["jab_1", "jab_2", "jab_finisher"]:
		for i in range(180):
			var dx: float = d.position.x - p.position.x
			if absf(dx) < 46.0 and p.is_on_floor() and d.is_on_floor(): break
			keys(["right" if dx > 0.0 else "left"]); await physics_frame
		keys([])
		check(await _juno_ground_control(p), prefix + "legal_public_" + jab)
		if jab == "jab_finisher":
			if outcome == "shield": Input.action_press("p2_shield"); await frames(20)
			damage_before_finisher = d.damage_percent
			aura_at_finisher = p.aura
		keys(["attack"]); await frames(2); keys([])
		check(p.move_runner.active and p.move_runner.current_move_id() == jab, prefix + "ordinary_" + jab)
		if jab != "jab_finisher":
			for i in range(100):
				await physics_frame
				if not p.move_runner.active: break
		else:
			source_activation = p.move_runner.activation_id
			_juno_source_activation = source_activation
	check(aura_at_finisher >= 50.0 and aura_at_finisher < 100.0, prefix + "finisher_uses_actual_high_aura")
	var window: Dictionary = {}
	for candidate in p.move_runner.move_data.get("cancel_windows", []):
		if str(candidate.get("to", "")) == "dash_attack" and str(candidate.get("requires", "")) == "hit_confirm": window = candidate.duplicate(true); break
	check(not window.is_empty(), prefix + "resolved_original_dash_route_exists")
	if window.is_empty(): keys([]); Input.action_release("p2_shield"); return
	var gesture: Dictionary = {}
	var tap: Dictionary = {}
	var toward := "right" if d.position.x > p.position.x else "left"
	var requested := false
	for i in range(100):
		if not p.move_runner.active or p.move_runner.current_move_id() != "jab_finisher": break
		if outcome == "released_tap" and tap.is_empty() and p.move_runner.confirmed_body_hit and p._hitstop > 0.0:
			tap = {"pressed_frame":Engine.get_physics_frames(), "actual_hitstop":p._hitstop, "move_frame":p.move_runner.total_frame}
			keys(["attack"]); await frames(1); keys([])
			tap["released_frame"] = Engine.get_physics_frames()
			continue
		var frame: int = p.move_runner.total_frame
		var inside: bool = frame >= int(window.start) and frame <= int(window.end)
		var ready: bool = frame > int(window.end) if outcome == "expired" else inside
		if outcome != "shield": ready = ready and p.move_runner.confirmed_body_hit
		if outcome == "released_tap": ready = ready and not tap.is_empty()
		if ready and p._hitstop <= 0.0:
			gesture = {"frame":Engine.get_physics_frames(), "move_frame":frame, "eligible":p.move_runner.can_cancel_to("dash_attack"), "identity_window":p.dash_cancel_remaining, "aura":p.aura, "grounded":p.is_on_floor(), "defender_state":d.state_machine.current_state, "defender_can_act":d.state_machine.can_move() or d.state_machine.can_attack(), "distance":absf(d.position.x - p.position.x), "toward":toward}
			keys([toward] if outcome in ["axis_only", "released_tap"] else [toward, "attack"])
			await frames(2); keys([])
			gesture["after_velocity_x"] = p.velocity.x
			gesture["after_state"] = p.state_machine.current_state
			gesture["after_identity_window"] = p.dash_cancel_remaining
			gesture["source_still_active"] = p.move_runner.active and p.move_runner.activation_id == source_activation
			requested = true
			break
		await physics_frame
	check(requested, prefix + "bounded_real_gesture_reached")
	if outcome == "released_tap": check(not tap.is_empty() and int(tap.get("released_frame", -1)) <= int(gesture.get("frame", -2)), prefix + "attack_tap_released_during_real_hitstop_before_axis")
	await frames(60)
	var links: Array = p.authored_cancel_history.filter(func(row): return row.from == "jab_finisher" and row.to == "dash_attack" and row.activation == source_activation)
	var dash_starts: Array = starts.filter(func(row): return row.move == "dash_attack" and int(row.frame) >= int(gesture.get("frame", 2147483647)))
	var finisher_contacts: Array = stage_contacts.filter(func(row): return row.move == "jab_finisher" and int(row.activation) == source_activation)
	var target_contacts: Array = []
	var target_activation := int(dash_starts[0].activation) if not dash_starts.is_empty() else -1
	for contact in stage_contacts:
		if contact.move == "dash_attack" and int(contact.activation) == target_activation: target_contacts.append(contact)
	if outcome == "contact":
		check(bool(gesture.get("eligible", false)) and float(gesture.get("identity_window", 0.0)) > 0.0 and links.size() == 1, prefix + "exact_authored_link_wins_over_live_identity_dash_once")
		check(dash_starts.size() == 1 and not links.is_empty() and int(dash_starts[0].frame) == int(links[0].gameplay_frame) and int(dash_starts[0].frame) <= int(gesture.get("frame", -100)) + 2 and bool(dash_starts[0].grounded), prefix + "fresh_side_Attack_starts_actual_grounded_dash_attack")
		check(finisher_contacts.size() == 1 and str(finisher_contacts[0].result) == "hit" and target_contacts.size() <= 1, prefix + "real_source_and_target_have_no_duplicate_contacts")
		var applied := 0.0
		for contact in finisher_contacts + target_contacts: applied += float(contact.damage_applied)
		check(is_equal_approx(d.damage_percent - damage_before_finisher, applied), prefix + "actual_meter_matches_only_confirmed_applied_damage")
	else:
		check(links.is_empty(), prefix + "no_unearned_authored_link")
		if outcome in ["axis_only", "released_tap"]:
			var direction := 1.0 if toward == "right" else -1.0
			check(float(gesture.get("identity_window", 0.0)) > 0.0 and not bool(gesture.get("source_still_active", true)) and float(gesture.get("after_identity_window", -1.0)) == 0.0 and float(gesture.get("after_velocity_x", 0.0)) * direction > 0.0 and dash_starts.is_empty(), prefix + "axis_only_keeps_original_identity_dash_without_Attack_reuse")
		elif outcome == "shield":
			check(finisher_contacts.size() == 1 and str(finisher_contacts[0].result) == "shield" and not bool(gesture.get("eligible", true)) and is_equal_approx(d.damage_percent, damage_before_finisher), prefix + "real_finisher_block_grants_no_authored_body_hit_cancel")
		elif outcome == "expired":
			check(int(gesture.get("move_frame", -1)) > int(window.end) and not bool(gesture.get("eligible", true)), prefix + "expired_original_window_is_not_extended")
	var status := "No target body contact observed; cancel execution and combo continuity are separate."
	var target_hits: Array = target_contacts.filter(func(row): return row.result == "hit")
	if not target_hits.is_empty():
		var recovered: bool = not bool(target_hits[0].defender_in_hitstun_before) or _juno_control_edges.any(func(row): return bool(row.can_act) and int(row.frame) < int(target_hits[0].frame))
		status = "Escapable follow-up: defender control returned before target contact." if recovered else "Observed target contact before control returned, quiet defender only; not guaranteed-combo acceptance."
	rows.append({"fighter":"juno-spark", "body":gs.p1_body_variant, "facing":p.facing, "case":outcome, "target":"dash_attack", "source":"res://data/moves/juno-spark.json#jab_finisher.cancel_windows", "opponent":"rook-ironside", "opponent_behavior":"quiet human fixture", "aura_method":"ordinary held Shield + Special, no meter assignment", "charged_aura":charged_aura, "finisher_aura":aura_at_finisher, "resolved_window":window, "source_activation":source_activation, "gesture":gesture, "released_tap":tap, "links":links.duplicate(true), "move_starts":starts.duplicate(true), "contacts":stage_contacts.duplicate(true), "defender_control_edges":_juno_control_edges.duplicate(true), "combo_status":status, "shield_identity_window_policy":"Observed separately; this fixture does not change generic identity dash eligibility on shields."})
	_juno_tracking = false
	keys([]); Input.action_release("p2_shield")

func probe_vesper_dodge() -> void:
	keys([]); Input.action_release("p2_shield")
	_juno_tracking = false
	_juno_source_activation = -1
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.p1_fighter_id = "vesper-nyx"; gs.p2_fighter_id = "rook-ironside"
	gs.p1_body_variant = "female"; gs.p2_body_variant = "male"
	gs.p1_is_cpu = false; gs.p2_is_cpu = false; gs.battle_eval_mode = false
	gs.stage_id = "training-grid"; gs.stocks = 3; gs.match_timer_seconds = 180
	var previous = current_scene
	root.get_node("SceneRouter").go("battle")
	for i in range(420):
		await physics_frame
		if current_scene != previous and active_battle(): break
	check(current_scene != previous and active_battle(), "vesper_high_aura:actual_BattleScene")
	if current_scene == previous or not active_battle(): return
	battle = current_scene
	var p = battle.fighter1; var d = battle.fighter2
	starts.clear(); stage_contacts.clear()
	p.move_runner.move_started.connect(func(mid): starts.append({"move":mid, "frame":Engine.get_physics_frames(), "activation":p.move_runner.activation_id}))
	p.hit_resolver.hit_confirmed.connect(record_contact)
	check(await _juno_ground_control(p), "vesper_high_aura:natural_ground_control")
	keys(["shield", "special"])
	for i in range(240):
		await physics_frame
		if p.aura >= 64.0: break
	keys([]); await frames(2)
	check(p.aura >= 60.0 and p.aura < 75.0, "vesper_high_aura:ordinary_charge_without_meter_assignment")
	for i in range(180):
		var dx: float = d.position.x - p.position.x
		if absf(dx) < 46.0 and p.is_on_floor() and d.is_on_floor(): break
		keys(["right" if dx > 0.0 else "left"]); await physics_frame
	keys([])
	check(await _juno_ground_control(p), "vesper_high_aura:legal_public_jab")
	keys(["attack"]); await frames(2); keys([])
	var activation: int = p.move_runner.activation_id
	check(p.move_runner.active and p.move_runner.current_move_id() == "jab_1", "vesper_high_aura:ordinary_jab_1")
	var gesture: Dictionary = {}
	for i in range(100):
		if not p.move_runner.active or p.move_runner.activation_id != activation: break
		if p.move_runner.confirmed_body_hit and p.phase_cancel_remaining > 0.0 and p._hitstop <= 0.0:
			gesture = {"frame":Engine.get_physics_frames(), "move_frame":p.move_runner.total_frame, "phase_window":p.phase_cancel_remaining, "aura":p.aura, "grounded":p.is_on_floor(), "defender_state":d.state_machine.current_state}
			keys(["dodge"]); await frames(2); keys([])
			gesture["after_state"] = p.state_machine.current_state
			gesture["after_window"] = p.phase_cancel_remaining
			gesture["source_still_active"] = p.move_runner.active and p.move_runner.activation_id == activation
			break
		await physics_frame
	check(not gesture.is_empty() and float(gesture.get("aura", 0.0)) >= 50.0, "vesper_high_aura:real_contact_opens_existing_phase_cancel")
	check(stage_contacts.any(func(row): return row.move == "jab_1" and row.result == "hit" and int(row.activation) == activation), "vesper_high_aura:actual_source_contact")
	check(str(gesture.get("after_state", "")) in ["dodge_start", "dodge_active", "dodge_recovery"] and not bool(gesture.get("source_still_active", true)) and float(gesture.get("after_window", -1.0)) == 0.0, "vesper_high_aura:single_fresh_Dodge_takes_existing_dodge_branch")
	check(not starts.any(func(row): return row.move == "neutral_special_projectile" and int(row.frame) >= int(gesture.get("frame", 2147483647))), "vesper_high_aura:Dodge_is_not_consumed_into_neutral_Special")
	rows.append({"fighter":"vesper-nyx", "body":gs.p1_body_variant, "facing":p.facing, "case":"high_aura_dodge_phase_cancel", "source":"res://scripts/combat/aura_special_runtime.gd#apply_attacker_on_confirm", "opponent":"rook-ironside", "opponent_behavior":"quiet human fixture", "aura_method":"ordinary held Shield + Special, no meter assignment", "source_activation":activation, "gesture":gesture, "move_starts":starts.duplicate(true), "contacts":stage_contacts.duplicate(true), "combo_status":"Existing identity Dodge cancellation only; no target attack or guaranteed combination claimed."})
	keys([])

func finish() -> void:
	keys([]); Input.action_release("p2_shield")
	var result = {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"rows":rows,
		"scope":"Actual ordinary-input manifest special-cancel execution, whiff/shield rejection, Juno ordinary-charged high-aura authored dash versus identity dash cases and Vesper phase-Dodge branch. Mechanical quiet-human fixtures, not active-CPU true-combo, two-process network, rollback or artistic acceptance",
		"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("AUTHORED_SPECIAL_LINKS.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  ")); file.close()
	print("AUTHORED_SPECIAL_LINKS ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
