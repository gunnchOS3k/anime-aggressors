extends SceneTree
## Actual BattleScene rigs; bounded transition/interrupt fixture, not CPU combo proof.
var output := ""
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func feet(sk: Skeleton3D) -> Dictionary:
	sk.force_update_all_bone_transforms()
	return {"L": sk.get_bone_global_pose(sk.find_bone("Foot_L")).origin, "R": sk.get_bone_global_pose(sk.find_bone("Foot_R")).origin}
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	var gs = root.get_node("GameState")
	gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p2_is_cpu = false; gs.stocks = 9
	root.get_node("SceneRouter").go("battle")
	for i in range(180): await physics_frame
	var p = current_scene.fighter1
	current_scene.fighter2.controls_enabled = false
	current_scene.fighter2.position.x = 420
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for body in ["male", "female"]:
			gs.p1_body_variant = body
			p.configure(fid, 1, false, 9, Vector2(-80, 240))
			# Reconfiguration retains the preceding case's control flag. Enable
			# ordinary gravity/movement while settling, then isolate the pose.
			p.controls_enabled = true
			for i in range(60): await physics_frame
			check(p.is_on_floor(), fid + ":" + body + ":physical_ground_precondition")
			p.controls_enabled = false
			var c = p.model_3d.get_animation_controller()
			var player = c.get_animation_player()
			var sk: Skeleton3D = c.get_skeleton()
			var hips := sk.find_bone("Hips")
			for facing in [1, -1]:
				p.facing = facing; p.model_3d.set_facing(facing)
				# The final authored strike pose differs from the neutral crouch.
				c.presentation_frozen = false
				c.play_for_state("attack_recovery", preload("res://scripts/data/data_loader.gd").find_move(p.move_manifest, "heavy_attack"))
				player.seek(player.current_animation_length, true)
				var finished_player_animation: String = player.current_animation
				var old_hips := sk.get_bone_pose_position(hips)
				var old_feet := feet(sk)
				c.play_for_state("idle")
				var first_hip_jump := old_hips.distance_to(sk.get_bone_pose_position(hips))
				var new_feet := feet(sk)
				var first_foot_jump: float = maxf(old_feet.L.distance_to(new_feet.L), old_feet.R.distance_to(new_feet.R))
				var label: String = fid + ":" + body + ":" + str(facing)
				# Numerical pose continuity, not a chosen artistic passing tolerance.
				check(first_hip_jump < .00001, label + ":no_pelvis_snap")
				check(first_foot_jump < .00001, label + ":no_foot_snap")
				var maximum_support_error := 0.0
				for step in range(10):
					player.advance(1.0 / 60.0)
					c._blend_neutral_return(1.0 / 60.0)
					if "_grounded_return" in c: maximum_support_error = maxf(maximum_support_error, c._grounded_return.support_error_m)
				check(maximum_support_error < .00001, label + ":reachable_support_targets")
				if "_grounded_return" in c:
					check(not c._grounded_return.active, label + ":bounded_settle")
					c.play_for_state("attack_recovery", preload("res://scripts/data/data_loader.gd").find_move(p.move_manifest, "heavy_attack"))
					player.seek(.3, true); c.play_for_state("idle")
					c.presentation_frozen = true; c._process(.2)
					check(c._grounded_return.elapsed == 0, label + ":hitstop_freezes_settle")
					c.presentation_frozen = false
					c.play_for_state("attack_startup", preload("res://scripts/data/data_loader.gd").find_move(p.move_manifest, "jab_1"))
					check(not c._grounded_return.active, label + ":next_action_immediate")
					c.play_for_state("idle")
					c.play_for_state("walk")
					check(not c._grounded_return.active, label + ":movement_owns_feet")
					c.play_for_state("idle")
					c.play_for_state("shield_hold")
					check(not c._grounded_return.active, label + ":shield_immediate")
				rows.append({"fighter": fid, "body": body, "facing": facing, "finished_player_animation": finished_player_animation, "grounded": p.is_on_floor(), "bound_runtime": is_instance_valid(c._runtime_fighter), "first_hip_jump_m": first_hip_jump, "first_foot_jump_m": first_foot_jump, "maximum_support_error_m": maximum_support_error, "scope": "live rigs on physical floor; controller transition fixture; not floor-coordinate or human motion approval"})
	var f = FileAccess.open(output.path_join("grounded_recovery.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS": failures.is_empty(), "rows": rows, "failures": failures}, "  ")); f.close()
	print("GROUNDED_RECOVERY ", "PASS" if failures.is_empty() else "FAIL", " cases=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
