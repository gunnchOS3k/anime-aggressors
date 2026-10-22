extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
## Real saved-action imports and public paired inputs; no empty animation fixtures.
## Declared idle/spacing setup is not active-CPU or native artistic acceptance.
var grab_events: Array = []
var damage_events: Array = []
var escape_handoff: Dictionary = {}
var throw_handoff: Dictionary = {}
var counter_contacts: Array = []
var landing_gaps: Dictionary = {}

func release() -> void:
	super.release()
	for slot in [1, 2]:
		for key in ["up", "down", "jump", "dodge", "taunt"]:Input.action_release("p%d_%s" % [slot, key])

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output = arg.get_slice("=", 1)
		if arg == "--pilot":pilot = true
		if arg.begins_with("--landing-gaps-from="):
			var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--landing-gaps-from=")))
			for row in previous.rows:
				if row.get("kind") == "public_throw" and row.get("landing", {}).is_empty():landing_gaps[row.case] = true
	var gs = root.get_node("GameState")
	gs.mode = "versus";gs.stage_id = "training-grid";gs.p2_is_cpu = false;gs.stocks = 9;gs.match_timer_seconds = 0;gs.match_type = "stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p = current_scene.fighter1;var d = current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a, b, info):
		if a == p and b == d:contacts.append(info.duplicate(true)))
	d.damaged.connect(func(amount, _total):damage_events.append(amount))
	d.hit_resolver.hit_confirmed.connect(func(a, b, info):
		if a == d and b == p:counter_contacts.append(info.duplicate(true)))
	p.grab_event.connect(func(info):
		grab_events.append(info.duplicate(true))
		if info.get("result") == "mash_escape":escape_handoff = pose(p)
		if info.get("result") == "throw":throw_handoff = pose(p))
	for fid in (IDs.slice(0, 1) if pilot else IDs):
		for body in ["male", "female"]:
			for face in [1, -1]:
				for direction in ["forward", "back", "up", "down"]:
					var label: String = fid + ":" + body + ":" + str(face) + ":" + direction
					if landing_gaps.is_empty() or landing_gaps.has(label):await throw_case(p, d, fid, body, face, direction)
				if landing_gaps.is_empty():await escape_case(p, d, fid, body, face)
	release();write(true);quit(0 if failures.is_empty() else 1)

func setup_pair(p, d, fid: String, body: String, face: int, mixed_bodies: bool = false) -> void:
	release()
	var gs = root.get_node("GameState");gs.p1_body_variant = body;gs.p2_body_variant = ("female" if body == "male" else "male") if mixed_bodies else body
	var other: String = IDs[(IDs.find(fid) + 1) % IDs.size()]
	p.configure(fid, 1, false, 9, Vector2(-40, 240));d.configure(other, 2, false, 9, Vector2(-40 + 32 * face, 240))
	# configure stores respawn authority; it does not reposition a live actor.
	# Explicit geometry is part of this controlled fixture, not an earned match.
	p.global_position = Vector2(-40, 240);d.global_position = Vector2(-40 + 32 * face, 240)
	for actor in [p, d]:
		actor.move_runner.cancel();actor.projectile_spawner.clear_all();actor.state_machine.enter("idle")
		actor.velocity = Vector2.ZERO;actor.controls_enabled = true;actor.invincible = false;actor.shielding = false
		actor.aura = 0;actor.damage_percent = 0;actor._hitstop = 0;actor.hitstun_remaining = 0;actor.armor_frames_remaining = 0
		actor._input_edge_held.clear();actor._recent_move_ids.clear();actor.combo_count = 0
	p.facing = face;d.facing = -face;current_scene._battle_sim.body_spacing.previous_order.clear()
	for i in range(100):
		await physics_frame
		if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
	p.model_3d.set_facing(face);d.model_3d.set_facing(-face)
	contacts.clear();damage_events.clear();grab_events.clear();escape_handoff.clear();throw_handoff.clear();counter_contacts.clear()
	for actor in [p, d]:
		var controller = actor.model_3d.get_animation_controller()
		var expected_body: String = gs.p1_body_variant if actor == p else gs.p2_body_variant
		var label: String = actor.fighter_id + ":" + expected_body + ":" + str(actor.facing)
		check(actor.is_model_loaded() and actor.data.body_variant == expected_body, label + ":real_body_loaded")
		check(controller.get_grab_acting_report().get("overlay_status") == "verified_source_export", label + ":saved_export_loaded")
		check(controller._grab_acting_sources.size() == 30, label + ":all_thirty_source_clips")
		for name in controller._grab_acting_sources:
			var clip: Animation = controller.get_animation_player().get_animation("combat_choreography/" + name)
			check(clip.get_track_count() == 22, label + ":twenty_one_pose_bones_plus_pelvis_static_root:" + name)
			check(not controller._grab_acting_sources[name].get("fixture_only", false), label + ":not_fixture:" + name)

func acquire(p, d, label: String) -> bool:
	Input.action_press("p1_grab")
	for i in range(30):
		await physics_frame
		if p.grabbed_target == d:break
	Input.action_release("p1_grab")
	check(p.grabbed_target == d and d.grabbed_by == p, label + ":real_public_grab")
	await frames(3);await process_frame
	return p.grabbed_target == d

func pose(actor) -> Dictionary:
	var model = actor.model_3d;var c = model.get_animation_controller();var sk: Skeleton3D = c.get_skeleton()
	sk.force_update_all_bone_transforms()
	var points := {};var rotations := {}
	for name in ["Hand_L", "Hand_R", "Chest", "Head", "Foot_L", "Foot_R"]:
		var index := sk.find_bone(name)
		var pixel: Vector2 = model._camera.unproject_position(sk.to_global(sk.get_bone_global_pose(index).origin))
		var point: Vector2 = model._display.to_global(pixel - Vector2(model._viewport.size) * .5 + model._display.offset)
		points[name] = [point.x, point.y]
		var q := sk.get_bone_pose_rotation(index);rotations[name] = [q.x, q.y, q.z, q.w]
	return {"fighter":actor.fighter_id, "body":actor.data.body_variant, "facing":actor.facing, "damage_percent":actor.damage_percent,
		"state":actor.state_machine.current_state, "clip":c.get_active_clip(),
		"animation":c.get_animation_player().current_animation, "animation_time":c.get_animation_player().current_animation_position,
		"points_gameplay_px":points, "local_rotations":rotations, "source":c.get_grab_acting_report()}

func paired_measure(p, d) -> Dictionary:
	var holder := pose(p);var victim := pose(d)
	var shape = d.get_node("Hurtbox/HurtShape")
	var bounds: Rect2 = p.hit_resolver._world_bounds(shape)
	var gaps := {}
	for name in ["Hand_L", "Hand_R"]:
		var point := Vector2(holder.points_gameplay_px[name][0], holder.points_gameplay_px[name][1])
		gaps[name] = point.distance_to(Vector2(clampf(point.x, bounds.position.x, bounds.end.x), clampf(point.y, bounds.position.y, bounds.end.y)))
	return {"holder":holder, "victim":victim, "holder_wrist_to_victim_hurt_surface_px":gaps,
		"victim_hurt_bounds":[bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
		"scope":"Projected wrists versus gameplay hurt surface; not mesh contact or visual/art approval"}

func throw_case(p, d, fid: String, body: String, face: int, direction: String) -> void:
	await setup_pair(p, d, fid, body, face)
	var label := fid + ":" + body + ":" + str(face) + ":" + direction
	if not await acquire(p, d, label):return
	var hold := paired_measure(p, d)
	for actor in [p, d]:
		var c = actor.model_3d.get_animation_controller();var role := "attacker" if actor == p else "victim"
		var expected := "grab_hold_" + role + ("_left" if actor.facing == -1 else "")
		check(c.get_active_clip() == expected and c.get_grab_acting_report().get("status") == "authored", label + ":saved_" + role + "_hold")
		check(c.get_animation_player().get_animation("combat_choreography/" + expected).loop_mode == Animation.LOOP_LINEAR, label + ":loop_" + role)
	await frames(8);await process_frame
	var sustained := paired_measure(p, d)
	for role in ["holder", "victim"]:
		check(float(sustained[role].animation_time) > float(hold[role].animation_time), label + ":advancing_" + role + "_hold")
	var axis := face if direction == "forward" else -face
	var command := direction if direction in ["up", "down"] else "right" if axis == 1 else "left"
	Input.action_press("p1_" + command);Input.action_press("p1_attack");await frames(2);release();await process_frame
	check(contacts.size() == 1 and damage_events.size() == 1, label + ":single_damage_contact")
	var reaction := pose(d);var release_pose := pose(p)
	var expected_throw := "throw_" + direction + ("_left" if face == -1 else "")
	check(throw_handoff.get("clip", "") == expected_throw, label + ":source_release_at_real_contact")
	check(absf(float(throw_handoff.get("animation_time", -1))) < .00001, label + ":frame_zero_pose_clock")
	check(release_pose.clip == expected_throw, label + ":real_saved_release")
	check(str(reaction.source.get("throw_reaction_clip", "")).begins_with("throw_reaction_"), label + ":actual_launch_reaction")
	var damage_before: float = d.damage_percent
	var landing := {};var recovered := false
	for i in range(120):
		await physics_frame
		if d.state_machine.current_state == "land" and landing.is_empty():
			landing = pose(d)
		if d.state_machine.can_attack() and p.state_machine.can_attack():
			recovered = true
			if landing_gaps.is_empty() or not landing.is_empty():break
	if not landing_gaps.is_empty():
		check(not landing.is_empty(), label + ":natural_landing_observed")
		if not landing.is_empty():check(landing.source.get("throw_landing_active", false), label + ":real_saved_landing")
	check(contacts.size() == 1 and is_equal_approx(d.damage_percent, damage_before), label + ":no_late_damage")
	check(p.grabbed_target == null and d.grabbed_by == null and not p.hitbox.monitoring, label + ":release_cleanup")
	rows.append({"case":label, "kind":"public_throw", "fighter":fid, "body":body, "facing":face, "direction":direction,
		"hold":hold, "sustained_hold":sustained, "release_at_contact":throw_handoff.duplicate(true), "release":release_pose, "reaction":reaction, "landing":landing, "control_return_observed":recovered,
		"contacts":contacts.duplicate(true), "damage_applications":damage_events.size(), "events":grab_events.duplicate(true)})
	write(false)

func escape_case(p, d, fid: String, body: String, face: int) -> void:
	await setup_pair(p, d, fid, body, face, true)
	var label := fid + ":" + body + ":" + str(face) + ":escape"
	if not await acquire(p, d, label):return
	var before := paired_measure(p, d)
	for i in range(4):
		Input.action_press("p2_attack");await frames(2);Input.action_release("p2_attack");await frames(2)
	check(p.grabbed_target == null and d.grabbed_by == null, label + ":real_mash_escape")
	var owner := pose(p);var victim := pose(d)
	check(victim.source.get("selected", "").begins_with("grab_escape"), label + ":real_escape_selected")
	# This checks a real hold-to-recovery handoff, not a fixture-injected pose.
	# The final mash attack can legitimately hit the old holder immediately.
	# Sample the real release callback before that counterattack, never delay it.
	check(escape_handoff.get("clip", "") == "grab_recovery" + ("_left" if face == -1 else ""), label + ":holder_supported_recovery")
	check(contacts.is_empty() and damage_events.is_empty(), label + ":no_throw_damage_on_escape")
	rows.append({"case":label, "kind":"public_mash_escape", "fighter":fid, "body":body, "facing":face,
		"before":before, "holder_at_release":escape_handoff.duplicate(true), "holder_after":owner, "victim_after":victim,
		"ordinary_counter_contacts":counter_contacts.duplicate(true), "events":grab_events.duplicate(true)})
	write(false)

func write(done: bool) -> void:
	var file = FileAccess.open(output.path_join("grab_acting_runtime_8b.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":done and failures.is_empty(), "complete":done, "rows":rows, "failures":failures,
		"fixture_animations":false, "native_visual_verified":false, "human_approved":false,
		"scope":"Saved source animation imports in real BattleScene, explicit spacing and idle targets, ordinary public grabs/throws/mash. No active CPU, mesh-contact quality, earned KO/Story, native visual/device or human acceptance."}, "\t"));file.close()
