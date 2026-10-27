extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Authored manifest links, existing runtime frames, actual ordinary controls.
## Quiet human defender is a declared mechanical fixture, not active-CPU proof.
const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
var rows: Array = []
var starts: Array = []
var stage_contacts: Array = []

func record_contact(a, d, info: Dictionary) -> void:
	super.record_contact(a, d, info)
	stage_contacts.append({"frame":Engine.get_physics_frames(), "move":info.get("move_id", ""),
		"result":info.get("contact_result", ""), "damage":info.get("damage", 0.0),
		"defender_state":d.state_machine.current_state, "contact_event":info.get("combat_event_id", "")})

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
		keys([]); await frames(3)
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

func finish() -> void:
	keys([]); Input.action_release("p2_shield")
	var result = {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"rows":rows,
		"scope":"Actual ordinary-input manifest special-cancel execution and whiff/shield rejection; mechanical quiet-human fixtures, not active-CPU true-combo or artistic acceptance",
		"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("AUTHORED_SPECIAL_LINKS.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  ")); file.close()
	print("AUTHORED_SPECIAL_LINKS ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
