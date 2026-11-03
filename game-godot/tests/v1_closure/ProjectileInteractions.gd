extends SceneTree
## Native BattleScene projectile acceptance fixtures. Aura/positions are
## explicit prerequisites, not earned public-input or campaign evidence.
const Resolver = preload("res://scripts/combat/projectile_interactions.gd")
const Data = preload("res://scripts/data/data_loader.gd")
var output := ""
var failures: Array = []
var rows: Array = []
var p; var d; var sim
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func spawn(actor, aura: float, point := Vector2(0, 100)):
	var shot = actor.projectile_spawner.spawn_from_move(Data.find_move(actor.move_manifest, "neutral_special_projectile"), aura)
	shot.global_position = point; shot.spawn_bounds = shot.world_bounds()
	return shot
func clear() -> void:
	p.projectile_spawner.clear_all(); d.projectile_spawner.clear_all()
	for actor in [p, d]:
		actor.damage_percent = 0; actor.aura = 0; actor._hitstop = 0; actor.invincible = false; actor.armor_frames_remaining = 0
		actor.state_machine.enter("idle")
		if actor.has_meta("story_team"): actor.remove_meta("story_team")
	sim = Resolver.new()
func resolve() -> void:
	sim.begin_frame([p, d]); sim.resolve_frame([p, d])
func run() -> void:
	create_timer(45).timeout.connect(func(): push_error("Projectile fixture watchdog"); quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	var gs = root.get_node("GameState"); gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"; gs.p2_is_cpu = false; gs.stocks = 9
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	p = current_scene.fighter1; d = current_scene.fighter2
	p.controls_enabled = false; d.controls_enabled = false
	for amount in [0, 50, 75]:
		clear()
		var a = spawn(p, amount); var b = spawn(d, amount)
		a._queue_target(d); b._queue_target(p)
		resolve()
		check(not a.active and not b.active, "equal_cancel:" + str(amount))
		check(p.damage_percent == 0 and d.damage_percent == 0, "cancel_before_pending_damage:" + str(amount))
		check(a.pending_targets.is_empty() and b.pending_targets.is_empty(), "cancel_clears_callbacks")
		a._deliver_hit(d); b._deliver_hit(p)
		check(p.damage_percent == 0 and d.damage_percent == 0, "no_late_canceled_damage")
		check(sim.history.size() == 1, "one_interception_event")
		rows.append({"case": "equal", "aura_fixture": amount, "history": sim.history.duplicate(true)})
	clear()
	var near_target: Vector2 = d.get_node("Hurtbox/HurtShape").global_position
	var near_a = spawn(p, 0, near_target); var near_b = spawn(d, 0, near_target)
	resolve()
	check(not near_a.active and not near_b.active and d.damage_percent == 0, "near_fighter_interception_precedes_swept_damage")
	clear()
	var strong = spawn(d, 75)
	var original_damage: float = strong.damage
	for index in range(4):
		var weak = spawn(p, 0)
		resolve()
		check(strong.integrity == 3 - index and not weak.active, "four_quick_shots:" + str(index))
		check(strong.active == (index < 3), "survive_exactly_three")
		if strong.active:
			check(is_equal_approx(strong.damage, original_damage * (3 - index) / 4.0), "authored_residual_damage")
			check(strong._renderer.slots[strong._flight_slot].strength < 1.0, "visible_strength_reduction")
		rows.append({"case": "breakthrough", "interception": index + 1, "remaining_integrity": strong.integrity, "remaining_damage": strong.damage, "active": strong.active})
	clear()
	strong = spawn(d, 75); var weak = spawn(p, 0)
	resolve(); strong._deliver_hit(p)
	check(p.damage_percent > 0, "survivor_normal_fighter_damage")
	var total: float = p.damage_percent
	strong._deliver_hit(p)
	check(p.damage_percent == total, "persistent_beam_one_hit_per_target")
	clear()
	strong = spawn(d, 75); weak = spawn(p, 0); resolve()
	p.state_machine.enter("shield_hold"); strong._deliver_hit(p)
	check(p.damage_percent == 0, "survivor_shield_preserved")
	clear()
	strong = spawn(d, 75); weak = spawn(p, 0); resolve()
	p.invincible = true; strong._deliver_hit(p)
	check(p.damage_percent == 0, "survivor_dodge_invulnerability_preserved")
	clear()
	p.set_meta("story_team", "allies"); d.set_meta("story_team", "allies")
	var a = spawn(p, 0); var b = spawn(d, 0); resolve()
	check(a.active and b.active and sim.history.is_empty(), "same_team_excluded")
	a._deliver_hit(d); check(d.damage_percent == 0, "same_team_damage_excluded")
	clear()
	a = spawn(p, 0, Vector2(-100, 100)); b = spawn(d, 0, Vector2(100, 100))
	sim.begin_frame([p, d]); a.position.x += 200; b.position.x -= 200
	sim.resolve_frame([d, p])
	check(not a.active and not b.active, "fast_crossing_without_endpoint_overlap")
	check(sim.history.size() == 1 and sim.history[0].time_of_impact > 0 and sim.history[0].time_of_impact < 1, "swept_contact_time")
	rows.append({"case": "fast_sweep", "history": sim.history.duplicate(true)})
	# Stable pair ordering is independent of fighter-list order.
	var outcomes: Array = []
	for reversed in [false, true]:
		clear(); strong = spawn(p, 75); a = spawn(d, 0); b = spawn(d, 50)
		strong.order_id = 1000001; a.order_id = 2000001; b.order_id = 2000002
		sim.begin_frame([p, d]); sim.resolve_frame([d, p] if reversed else [p, d])
		outcomes.append(sim.history.duplicate(true))
		check(strong.integrity == 1 and strong.active and not a.active and not b.active, "multiple_same_frame_interceptions")
	check(outcomes[0] == outcomes[1], "deterministic_pair_order")
	clear()
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		p.configure(fid, 1, false, 9, Vector2(-202, 240)); p.controls_enabled = false
		for amount in [0, 50, 75]:
			var shot = spawn(p, amount)
			check(shot.clash_eligible, fid + ":explicit_behavior_eligibility:" + shot.behavior)
			check(shot.integrity == (1 if amount == 0 else 2 if amount == 50 else 4), fid + ":authored_integrity")
			check(shot.damage == shot.initial_damage, fid + ":damage_unchanged_before_interception")
			rows.append({"case": "roster_authored_behavior", "fighter": fid, "aura_fixture": amount, "behavior": shot.behavior, "integrity": shot.integrity})
			shot._expire()
	clear()
	a = spawn(p, 0); b = spawn(d, 0); a.clash_eligible = false; resolve()
	check(a.active and b.active, "unlisted_behavior_ineligible")
	a.lifetime_frames = 2; a.tick_sim_frame(); a.tick_sim_frame()
	check(not a.active and a.pending_targets.is_empty(), "lifetime_cleanup")
	for mode in ["Full", "Balanced", "Reduced"]:
		root.get_node("StoryDialogue").set_option("vfx_intensity", mode)
		clear(); a = spawn(p, 75); b = spawn(d, 0); resolve()
		var renderer = a._renderer
		renderer._process(.5)
		check(renderer.active_count() <= (32 if mode == "Reduced" else 96) and renderer.slots.size() <= 96, "bounded_effects:" + mode)
		check(a.integrity == 3 and not b.active, "accessibility_preserves_rules:" + mode)
	clear()
	a = spawn(p, 75); a._queue_target(d)
	p.projectile_spawner.clear_all(); a._deliver_hit(d)
	check(not a.active and a.pending_targets.is_empty() and d.damage_percent == 0, "scene_clear_retires_authority_immediately")
	for i in range(2): await physics_frame
	check(p.projectile_spawner.count() == 0 and d.projectile_spawner.count() == 0, "no_owned_emitters_after_cleanup")
	var f = FileAccess.open(output.path_join("projectile_interactions.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS": failures.is_empty(), "failures": failures, "rows": rows, "scope": "native BattleScene prerequisites/geometry fixtures; no earned aura, public combo, native video or full roster artistic acceptance", "max_integrity": 16}, "  ")); f.close()
	print("PROJECTILE_INTERACTIONS ", "PASS" if failures.is_empty() else "FAIL", " rows=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
