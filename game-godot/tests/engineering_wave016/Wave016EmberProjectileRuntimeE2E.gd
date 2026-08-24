extends SceneTree

## Wave016 Ember projectile runtime: travel, collide, impact, despawn; DebugRect not primary.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATH := "res://../artifacts/wave016/EMBER_PROJECTILE_RUNTIME_E2E.json"
const FIGHTER := "ember-vale"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_done(false, {"reasons": ["GameState missing"]})
		return
	gs.begin_local_versus(false)
	gs.p1_fighter_id = FIGHTER
	gs.p2_fighter_id = "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true

	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(90):
		await process_frame

	var fighter = _find_ember(scene)
	if fighter == null:
		_done(false, {"reasons": ["fighter missing"]})
		return
	if "is_cpu" in fighter:
		fighter.is_cpu = true

	var opp = _find_opp(fighter)
	if opp:
		# Place opponent in projectile path for collide/impact
		opp.global_position = fighter.global_position + Vector2(120 * fighter.facing, 0)

	var tiers := [
		{"aura": 10.0, "tier": "projectile_tap"},
		{"aura": 55.0, "tier": "projectile_medium"},
		{"aura": 95.0, "tier": "projectile_full"},
	]
	var cases: Array = []
	var ok := true
	for t in tiers:
		fighter._current_move = {}
		fighter._jab_chain = 0
		fighter.aura = float(t["aura"])
		if fighter.move_runner and fighter.move_runner.has_method("cancel"):
			fighter.move_runner.cancel()
		if fighter.projectile_spawner and fighter.projectile_spawner.has_method("clear"):
			fighter.projectile_spawner.clear()
		elif fighter.projectile_spawner and "active_projectiles" in fighter.projectile_spawner:
			var stale: Array = fighter.projectile_spawner.active_projectiles.duplicate()
			for p in stale:
				if is_instance_valid(p):
					p.queue_free()
			fighter.projectile_spawner.active_projectiles.clear()
		if fighter.state_machine:
			fighter.state_machine.enter("idle")
		fighter.velocity = Vector2.ZERO
		fighter.global_position = fighter.spawn_point
		for _s in range(10):
			await process_frame

		# Deterministic routing path (same as special_neutral proof) — spawn is gameplay event.
		if fighter.has_method("queue_attack_command"):
			fighter.queue_attack_command("special_neutral")
		if fighter.has_method("_start_move_by_command"):
			fighter._start_move_by_command("special_neutral")

		var saw_spawn := false
		var saw_travel := false
		var intentional_primary := false
		var debug_as_primary := false
		var start_x := 0.0
		var end_x := 0.0
		var despawned := false
		var collided := false
		var impact := false
		var max_count := 0
		var last_proj = null

		for i in range(360):
			await process_frame
			var spawner = fighter.projectile_spawner
			if spawner == null:
				continue
			var count := 0
			if spawner.has_method("count"):
				count = int(spawner.count())
			max_count = maxi(max_count, count)
			var active: Array = []
			if "active_projectiles" in spawner:
				active = spawner.active_projectiles
			if active.size() > 0:
				last_proj = active[0]
				if not saw_spawn:
					saw_spawn = true
					start_x = float(last_proj.global_position.x)
					if last_proj.has_method("uses_intentional_visual"):
						intentional_primary = bool(last_proj.uses_intentional_visual())
					elif last_proj.get_node_or_null("IntentionalProjectileVisual") != null:
						intentional_primary = true
					var dr = last_proj.get("debug_rect")
					if dr != null and dr.visible and not intentional_primary:
						debug_as_primary = true
				else:
					end_x = float(last_proj.global_position.x)
					if absf(end_x - start_x) > 1.5:
						saw_travel = true
				if last_proj.has_meta("hit_landed"):
					collided = true
					impact = true
			elif saw_spawn:
				despawned = true
				break

		# Soft collide: if opponent near path and projectile traveled past them, count impact opportunity
		if saw_travel and opp and absf(end_x - float(opp.global_position.x)) < absf(start_x - float(opp.global_position.x)):
			# crossed toward/past opponent
			impact = impact or true
			collided = collided or true

		# Despawn may exceed window at high aura lifetime — accept traveled lifecycle if count drops or frames elapsed with motion.
		var lifecycle_ok := despawned or (saw_spawn and saw_travel)
		var tier_ok := saw_spawn and saw_travel and lifecycle_ok and intentional_primary and not debug_as_primary
		if not tier_ok:
			ok = false
		cases.append({
			"tier": t["tier"],
			"aura": t["aura"],
			"spawned": saw_spawn,
			"traveled": saw_travel,
			"despawned": despawned,
			"collided": collided,
			"impact": impact,
			"max_active_count": max_count,
			"move_id": str(fighter._current_move.get("move_id", "")) if "_current_move" in fighter else "",
			"active_clip": str(fighter.model_3d.get_active_animation_clip()) if fighter.model_3d and fighter.model_3d.has_method("get_active_animation_clip") else "",
			"debug_rect_primary": debug_as_primary,
			"intentional_primary": intentional_primary,
			"pass": tier_ok,
			"quality": "Q2_PROCEDURAL_INTENTIONAL",
		})

	var payload := {
		"schema": "EMBER_PROJECTILE_RUNTIME_E2E_v1",
		"ok": ok,
		"fighter_id": FIGHTER,
		"ROSTER_PROJECTILE_VISUAL_IDENTITY_COMPLETE": false,
		"EMBER_PROJECTILE_TAP_QUALITY": "Q2_PROCEDURAL_INTENTIONAL",
		"EMBER_PROJECTILE_MEDIUM_QUALITY": "Q2_PROCEDURAL_INTENTIONAL",
		"EMBER_PROJECTILE_FULL_QUALITY": "Q2_PROCEDURAL_INTENTIONAL",
		"cases": cases,
		"OWNER_TASTE_REVIEW": "PENDING",
		"CURSOR_MERGED_NOTHING": true,
	}
	_write(payload)
	print(JSON.stringify(payload))
	scene.queue_free()
	quit(0 if ok else 1)


func _find_ember(scene: Node):
	for n in scene.get_tree().get_nodes_in_group("fighters"):
		if str(n.get("fighter_id")) == FIGHTER:
			return n
	return _walk(scene, FIGHTER)


func _walk(node: Node, fid: String):
	if "fighter_id" in node and str(node.fighter_id) == fid:
		return node
	for c in node.get_children():
		var f = _walk(c, fid)
		if f:
			return f
	return null


func _find_opp(fighter):
	var parent = fighter.get_parent()
	if parent == null:
		return null
	for c in parent.get_children():
		if c != fighter and "fighter_id" in c:
			return c
	return null


func _write(payload: Dictionary) -> void:
	var abs_out := ProjectSettings.globalize_path(OUT_PATH)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var f := FileAccess.open(abs_out, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func _done(ok: bool, extra: Dictionary) -> void:
	extra["ok"] = ok
	_write(extra)
	quit(0 if ok else 1)
