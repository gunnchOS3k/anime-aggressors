extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
## Animation routing fixtures only. Empty in-memory animations explicitly prove
## selection/lifecycle support, never saved source acting or visual quality.
var grab_events: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output = arg.get_slice("=", 1)
	var gs = root.get_node("GameState")
	gs.mode = "versus";gs.stage_id = "training-grid";gs.p2_is_cpu = false;gs.stocks = 9;gs.match_timer_seconds = 0;gs.match_type = "stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p = current_scene.fighter1;var d = current_scene.fighter2
	p.grab_event.connect(func(info):grab_events.append(info.duplicate(true)))
	p.hit_resolver.hit_confirmed.connect(func(_a, _b, info):contacts.append(info.duplicate(true)))
	d.hit_resolver.hit_confirmed.connect(func(_a, _b, info):contacts.append(info.duplicate(true)))
	for face in [1, -1]:
		for ending in ["complete", "attack", "movement", "hurt", "ko", "reset"]:
			await acting_case(p, d, face, ending)
	release();Input.action_release("p2_jump")
	write(true);quit(0 if failures.is_empty() else 1)

func fixture_clips(controller) -> void:
	var library: AnimationLibrary = controller.get_animation_player().get_animation_library("combat_choreography")
	for base in ["grab_hold_attacker", "grab_hold_victim", "grab_escape", "throw_reaction_forward", "throw_reaction_back", "throw_reaction_up", "throw_reaction_down", "throw_landing"]:
		for suffix in ["", "_left"]:
			var name: String = base+suffix
			var animation := Animation.new();animation.length = .35
			animation.set_meta("fixture_only", true)
			if library.has_animation(name):library.remove_animation(name)
			library.add_animation(name, animation);controller._loaded_clips[name] = true
			controller._grab_acting_sources[name] = {"fixture_only":true, "source_action":"IN_MEMORY_ROUTING_FIXTURE", "source_blend":""}

func acting_case(p, d, face: int, ending: String) -> void:
	await prepare(p, d, "juno-spark", "male", face)
	p.model_3d.set_facing(face);d.model_3d.set_facing(-face)
	var owner = p.model_3d.get_animation_controller();var victim = d.model_3d.get_animation_controller()
	# Explicitly simulate a missing/unverified export without modifying assets.
	owner._grab_acting_sources.clear();victim._grab_acting_sources.clear()
	grab_events.clear()
	Input.action_press("p1_grab")
	for i in range(30):
		await physics_frame
		if p.grabbed_target == d:break
	Input.action_release("p1_grab")
	var label := str(face)+":"+ending
	check(p.grabbed_target == d and d.grabbed_by == p, label+":genuine_public_acquisition")
	if p.grabbed_target != d:return
	var fallback_owner: Dictionary = owner.get_grab_acting_report()
	var fallback_victim: Dictionary = victim.get_grab_acting_report()
	check(fallback_owner.get("role") == "attacker" and fallback_victim.get("role") == "victim", label+":reciprocal_roles")
	check(fallback_owner.get("status") == "fallback" and fallback_victim.get("status") == "fallback", label+":missing_source_honesty")
	check(fallback_owner.get("metadata_role") == "attacker" and fallback_victim.get("metadata_role") == "victim", label+":fighter_presentation_metadata")
	fixture_clips(owner);fixture_clips(victim)
	p._play_current_animation("grab_hold");d._play_current_animation("grab_hold")
	await frames(3)
	var hold_owner: String = "grab_hold_attacker"+("_left" if face == -1 else "")
	var hold_victim: String = "grab_hold_victim"+("_left" if face == 1 else "")
	check(owner.get_active_clip() == hold_owner and victim.get_active_clip() == hold_victim, label+":distinct_facing_clips")
	check(owner.get_grab_acting_report().get("status") == "fixture_only" and victim.get_grab_acting_report().get("status") == "fixture_only", label+":fixture_never_claimed_authored")
	check(owner.get_animation_player().get_animation("combat_choreography/"+hold_owner).loop_mode == Animation.LOOP_LINEAR, label+":holder_loops")
	check(victim.get_animation_player().get_animation("combat_choreography/"+hold_victim).loop_mode == Animation.LOOP_LINEAR, label+":victim_loops")
	# The old grab runner is still allowed its unchanged recovery clock, but
	# cannot replace the pair's holder pose with the old reach animation.
	owner.synchronize_move(1, p._current_move)
	check(owner.get_active_clip() == hold_owner and owner.get_animation_player().current_animation.ends_with(hold_owner), label+":stale_grab_callback_cannot_replace_hold")
	for i in range(4):
		Input.action_press("p2_attack");await frames(2);Input.action_release("p2_attack");await frames(2)
	check(p.grabbed_target == null and d.grabbed_by == null, label+":real_mash_escape")
	var escape: String = "grab_escape"+("_left" if face == 1 else "")
	var actual_escape: Dictionary = victim.get_grab_acting_report()
	check(actual_escape.get("selected") == escape and actual_escape.get("role") == "escape", label+":real_victim_escape_selects_clip")
	check(contacts.filter(func(info):return info.get("contact_owner") == "direct_throw" or info.get("move_id") == "grab_escape").is_empty(), label+":escape_has_no_damage_contact_owner")
	# The unchanged final mash press may legally start an ordinary jab in the
	# victim's callback. Yielding to it is correct. Rearm only this explicit
	# in-memory presentation fixture after that real action has completed.
	var rearmed_fixture := not bool(actual_escape.get("escape_active", false))
	if rearmed_fixture:
		await frames(40)
		victim.begin_grab_escape()
	check(victim.get_grab_acting_report().get("escape_active", false) and d.state_machine.can_attack(), label+":escape_has_no_control_lock")
	if ending == "attack":Input.action_press("p2_attack");await frames(2);release()
	elif ending == "movement":Input.action_press("p2_right");await frames(2);release()
	elif ending == "hurt":
		d.receive_hit(p, {"damage":1.0, "launch":Vector2(30, -20), "hitstop_frames":2, "move_id":"jab_1"})
	elif ending == "ko":d.state_machine.enter("ko") # Declared state interruption fixture, no earned KO claim.
	elif ending == "reset":d.reset_position()
	else:await frames(28)
	check(not victim.get_grab_acting_report().get("escape_active", false), label+":escape_finishes_or_yields")
	check(p.grabbed_target == null and d.grabbed_by == null, label+":no_reacquisition")
	rows.append({"case":label, "fallback_owner":fallback_owner, "fallback_victim":fallback_victim, "holder_clip":hold_owner, "victim_clip":hold_victim, "actual_escape_callback":actual_escape, "rearmed_presentation_fixture":rearmed_fixture, "escape":victim.get_grab_acting_report(), "events":grab_events.duplicate(true), "fixture_only":true})
	# Declared reaction/landing routing fixture uses the existing hurt clock.
	if ending == "complete":
		for direction in ["forward", "back", "up", "down"]:
			var launch: Vector2 = Vector2(30 * d.facing, 0) if direction == "forward" else Vector2(-30 * d.facing, 0) if direction == "back" else Vector2(0, -30) if direction == "up" else Vector2(0, 30)
			victim.begin_hit_reaction({"move_id":"throw_forward", "incoming":launch, "performance_clip":"reaction_light"})
			var requested: String = "throw_reaction_"+direction+("_left" if face == 1 else "")
			check(victim.get_grab_acting_report().get("throw_reaction_clip") == requested, label+":actual_launch_reaction:"+direction)
			d.state_machine.enter("launched");d.begin_landing(true)
			check(victim.get_grab_acting_report().get("throw_landing_active", false), label+":throw_only_landing:"+direction)
			d.state_machine.enter("idle")
			check(not victim.get_grab_acting_report().get("throw_landing_active", false), label+":landing_cleanup:"+direction)
	write(false)

func write(done: bool) -> void:
	var payload := {"PASS":done and failures.is_empty(), "complete":done, "rows":rows, "failures":failures, "scope":"Public acquisition/mash with explicit spacing; empty in-memory fixture animations prove only routing, looping, lifecycle, interruption and no added control lock. No source-action, native visual, CPU or earned KO acceptance.", "fixture_only":true}
	if not output.is_empty():
		var file = FileAccess.open(output.path_join("grab_acting_support_8b.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(payload, "\t"));file.close()
	print("GRAB_ACTING_SUPPORT_8B ", "PASS" if done and failures.is_empty() else "IN_PROGRESS" if not done else "FAIL", " rows=", rows.size())
