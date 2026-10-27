extends "res://tests/integration/TrainingAuthoredLink.gd"
## Existing Frost Shot -> Grab, real projectile and public controls. Quiet
## Training dummy, not active-CPU/inescapable-combo or native visual proof.
var source_events: Array = []
var grab_events: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated Nix practice required"); quit(2); return
	var campaign = root.get_node("CampaignRuntime")
	var story_before := JSON.stringify(campaign.progress)
	await probe_nix("body", "female")
	await probe_nix("shield", "male")
	await probe_nix("whiff", "female")
	check(JSON.stringify(campaign.progress) == story_before, "authored_grab_practice_preserves_Story")
	finish()

func source_contact(attacker, _defender, info: Dictionary) -> void:
	if str(info.get("move_id", "")) != "neutral_special_projectile": return
	source_events.append({"info":info.duplicate(true), "owns_confirmation_at_contact":attacker.move_runner.owns_confirmed_contact(info), "current_activation":attacker.move_runner.activation_id, "current_move_frame":attacker.move_runner.total_frame})

func acquired(info: Dictionary, actor) -> void:
	grab_events.append({"frame":Engine.get_physics_frames(), "result":info.get("result", ""), "reason":info.get("reason", ""), "activation":actor.move_runner.activation_id, "actual_target":actor.grabbed_target.get_instance_id() if is_instance_valid(actor.grabbed_target) else 0, "reciprocal_hold":is_instance_valid(actor.grabbed_target) and actor.grabbed_target.grabbed_by == actor})

func probe_nix(outcome: String, body: String) -> void:
	keys([]); Input.action_release("p2_shield")
	var gs = root.get_node("GameState")
	gs.begin_training()
	gs.p1_fighter_id = "nix-calder"; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = body; gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"; gs.stage_id = "training-grid"
	var previous = current_scene
	root.get_node("SceneRouter").go("training_battle")
	for i in range(180):
		await process_frame
		if current_scene != previous and route_is("TrainingBattleScene.tscn"): break
	check(current_scene != previous and route_is("TrainingBattleScene.tscn"), outcome + ":real_Training_scene")
	if current_scene == previous or not route_is("TrainingBattleScene.tscn"): return
	var training = current_scene
	await frames(120)
	var p = training.fighter1; var d = training.fighter2
	source_events.clear(); grab_events.clear()
	p.hit_resolver.hit_confirmed.connect(source_contact)
	p.grab_event.connect(acquired.bind(p))
	# Declared lesson/menu setup, no direct attack or combat state helper.
	training._on_training_link("neutral_special_projectile", "grab")
	check(training._link_practice.selection.get("target", "") == "grab", outcome + ":existing_manifest_lesson_selected")
	if outcome == "shield": Input.action_press("p2_shield"); await frames(20)
	if outcome != "whiff":
		for i in range(180):
			var dx: float = d.position.x - p.position.x
			if absf(dx) < 44 and p.is_on_floor() and d.is_on_floor(): break
			keys(["right" if dx > 0 else "left"]); await physics_frame
	keys([])
	check(await legal_ground_control(p), outcome + ":real_ground_control")
	keys(["special"]); await frames(2); keys([])
	check(p.move_runner.current_move_id() == "neutral_special_projectile", outcome + ":ordinary_Frost_Shot")
	var cast_activation: int = p.move_runner.activation_id
	var requested := false
	var before: Dictionary = {}
	for i in range(100):
		if not p.move_runner.active or p.move_runner.current_move_id() != "neutral_special_projectile": break
		for window in p.move_runner.move_data.get("cancel_windows", []):
			if str(window.get("to", "")) != "grab" or p.move_runner.total_frame < int(window.start) or p.move_runner.total_frame > int(window.end) or p._hitstop > 0: continue
			if outcome == "body" and not p.move_runner.confirmed_body_hit: continue
			before = {"frame":Engine.get_physics_frames(), "move_frame":p.move_runner.total_frame, "eligible":p.move_runner.can_cancel_to("grab"), "confirmed_body_hit":p.move_runner.confirmed_body_hit, "defender_state":d.state_machine.current_state, "defender_can_act":d.state_machine.can_move() or d.state_machine.can_attack(), "distance":absf(d.position.x - p.position.x)}
			keys(["grab"]); await frames(2); keys([]); requested = true; break
		if requested: break
		await physics_frame
	await frames(90)
	var links: Array = p.authored_cancel_history.filter(func(row): return row.from == "neutral_special_projectile" and row.to == "grab" and row.activation == cast_activation)
	var snapshot: Dictionary = training._link_practice.snapshot()
	check(requested, outcome + ":fresh_Grab_inside_resolved_original_window")
	if outcome == "body":
		check(source_events.size() == 1 and source_events[0].owns_confirmation_at_contact and str(source_events[0].info.contact_owner) == "projectile", "actual_owned_projectile_body_contact_earns_confirmation")
		check(before.get("eligible", false) and links.size() == 1, "existing_projectile_to_grab_cancel_accepted_once")
		check(grab_events.any(func(row): return row.result == "success" and row.reciprocal_hold), "original_grab_resolver_acquires_real_target")
		check(snapshot.attempt.get("target_contact", false) and snapshot.attempt.get("outcome", "") in ["grab_before_observed_recovery", "grab_after_recovery"], "Training_reports_real_acquisition_without_fabricated_hit")
		# A new ordinary cast cannot borrow the old real projectile receipt.
		check(await legal_ground_control(p), "new_cast_waits_real_control")
		keys(["special"]); await frames(2); keys([])
		check(p.move_runner.activation_id != cast_activation and not source_events.is_empty() and not p.move_runner.owns_confirmed_contact(source_events[0].info) and not p.move_runner.confirmed_body_hit, "old_shot_cannot_confirm_replacement_cast")
	else:
		check(not before.get("eligible", true) and links.is_empty() and grab_events.all(func(row): return row.result != "success"), outcome + ":unearned_grab_cancel_rejected")
		if outcome == "shield":
			check(source_events.any(func(row): return str(row.info.contact_result) == "shield" and not row.owns_confirmation_at_contact) and d.damage_percent == 0, "actual_blocked_shot_grants_no_body_cancel")
		else: check(source_events.is_empty() and d.damage_percent == 0, "distant_missed_shot_grants_no_cancel")
	lesson_rows.append({"case":outcome, "fighter":"nix-calder", "body":body, "facing":p.facing, "source":"res://data/moves/nix-calder.json#neutral_special_projectile.cancel_windows", "requested_at":before, "links":links.duplicate(true), "source_contacts":source_events.duplicate(true), "grabs":grab_events.duplicate(true), "lesson":snapshot})
	keys([]); Input.action_release("p2_shield")

func finish() -> void:
	keys([]); Input.action_release("p2_shield")
	var result = {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "rows":lesson_rows, "inputs":inputs,
		"scope":"Actual public-input Nix Frost Shot -> Grab using original manifest timing, real owned projectile and normal grab acquisition. Female body hit, male shield and female distant whiff. Quiet Training dummy only; not active-CPU, both-facing/all-aura, guaranteed combo, native visual or rollback acceptance."}
	var file = FileAccess.open(output.path_join("NIX_AUTHORED_GRAB.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("NIX_AUTHORED_GRAB ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
