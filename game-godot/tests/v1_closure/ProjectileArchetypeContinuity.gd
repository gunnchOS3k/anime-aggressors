extends SceneTree
## Compare surviving emitters with untouched same-move controls through the
## delayed/return phase. Explicit aura prerequisites, not public-play evidence.
var output := ""
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("run")
func run() -> void:
	create_timer(45).timeout.connect(func(): quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	var gs = root.get_node("GameState"); gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p2_is_cpu = false; gs.stocks = 9
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	var p = current_scene.fighter1; var d = current_scene.fighter2
	p.controls_enabled = false; d.controls_enabled = false
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		p.configure(fid, 1, false, 9, Vector2(-202, 240)); p.controls_enabled = false
		for amount in [50, 75]:
			var move: Dictionary = preload("res://scripts/data/data_loader.gd").find_move(p.move_manifest, "neutral_special_projectile")
			var weakened = p.projectile_spawner.spawn_from_move(move, amount)
			var control = p.projectile_spawner.spawn_from_move(move, amount)
			var weak = d.projectile_spawner.spawn_from_move(preload("res://scripts/data/data_loader.gd").find_move(d.move_manifest, "neutral_special_projectile"), 0)
			for shot in [weakened, control, weak]: shot.global_position = Vector2(0, 100); shot.spawn_bounds = shot.world_bounds()
			var sim = preload("res://scripts/combat/projectile_interactions.gd").new()
			sim.begin_frame([p, d]); sim.resolve_frame([p, d])
			var errors: Array = []
			if not weakened.active or weak.active or control.integrity != control.initial_integrity: errors.append("fixture_interception_ownership")
			if weakened.integrity != weakened.initial_integrity - 1: errors.append("integrity_loss")
			var maximum_drift := 0.0
			# Beyond half lifetime exercises boomerang return, stationary wave
			# exhaustion, delayed/trap release and persistent moving beams.
			for frame in range(weakened.lifetime_frames):
				weakened.tick_sim_frame(); control.tick_sim_frame()
				maximum_drift = maxf(maximum_drift, weakened.position.distance_to(control.position))
				if weakened.frame_count != control.frame_count or weakened.direction != control.direction or weakened.active != control.active: errors.append("motion_or_lifetime_changed"); break
			if maximum_drift != 0: errors.append("trajectory_changed")
			if weakened.active or control.active: errors.append("expiration_missing")
			if not errors.is_empty(): failures.append({"fighter": fid, "aura": amount, "errors": errors})
			rows.append({"fighter": fid, "aura_fixture": amount, "behavior": weakened.behavior, "lifetime_frames": weakened.lifetime_frames, "maximum_position_drift_px": maximum_drift, "errors": errors, "scope": "moving native emitter comparison; not owner visual acceptance or public charged play"})
			p.projectile_spawner.clear_all(); d.projectile_spawner.clear_all()
			await physics_frame
	var f = FileAccess.open(output.path_join("projectile_archetype_continuity.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS": failures.is_empty(), "rows": rows, "failures": failures}, "  ")); f.close()
	print("PROJECTILE_ARCHETYPE_CONTINUITY ", "PASS" if failures.is_empty() else "FAIL", " cases=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
