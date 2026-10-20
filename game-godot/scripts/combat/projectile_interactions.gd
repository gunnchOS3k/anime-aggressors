extends RefCounted
signal interception_confirmed(info: Dictionary)
## One deterministic post-movement pass. Existing projectile rectangles are
## swept in relative motion; every interception precedes fighter delivery.
var starts: Dictionary = {}
var history: Array = []
var frame := 0
var last_pair_tests := 0
var last_resolve_us := 0

func shots(fighters: Array) -> Array:
	var result: Array = []
	for fighter in fighters:
		if not is_instance_valid(fighter) or not "projectile_spawner" in fighter: continue
		for shot in fighter.projectile_spawner.active_projectiles:
			if is_instance_valid(shot) and shot.active: result.append(shot)
	result.sort_custom(func(a, b): return a.order_id < b.order_id)
	return result

func begin_frame(fighters: Array) -> void:
	starts.clear(); frame += 1
	for shot in shots(fighters): starts[shot.order_id] = shot.world_bounds()

static func swept_time(a: Rect2, travel_a: Vector2, b: Rect2, travel_b: Vector2) -> float:
	var relative := a.get_center() - b.get_center()
	var travel := travel_a - travel_b
	var half := (a.size + b.size) * .5
	var enter := 0.0; var leave := 1.0
	for axis in [0, 1]:
		if absf(travel[axis]) < .000001:
			if absf(relative[axis]) > half[axis]: return -1.0
		else:
			var t0: float = (-half[axis] - relative[axis]) / travel[axis]
			var t1: float = (half[axis] - relative[axis]) / travel[axis]
			enter = maxf(enter, minf(t0, t1)); leave = minf(leave, maxf(t0, t1))
			if enter > leave: return -1.0
	return enter if enter >= 0 and enter <= 1 else -1.0

static func contact_point(a: Rect2, b: Rect2) -> Vector2:
	# Rect2.intersection discards zero-area touching faces. The contact point
	# must still lie on that face, including unequal projectile sizes.
	var low := Vector2(maxf(a.position.x, b.position.x), maxf(a.position.y, b.position.y))
	var high := Vector2(minf(a.end.x, b.end.x), minf(a.end.y, b.end.y))
	return low + Vector2(maxf(0, high.x - low.x), maxf(0, high.y - low.y)) * .5

func resolve_frame(fighters: Array) -> void:
	var started := Time.get_ticks_usec()
	var live := shots(fighters)
	var candidates: Array = []; last_pair_tests = 0
	for i in range(live.size()):
		var a = live[i]
		if not a.clash_eligible: continue
		for j in range(i + 1, live.size()):
			var b = live[j]
			if not b.clash_eligible or a.team_key == b.team_key or a.owner_fighter == b.owner_fighter: continue
			if a.intercepted_ids.has(b.order_id): continue
			last_pair_tests += 1
			var old_a: Rect2 = starts.get(a.order_id, a.spawn_bounds)
			var old_b: Rect2 = starts.get(b.order_id, b.spawn_bounds)
			var da: Vector2 = a.world_bounds().position - old_a.position
			var db: Vector2 = b.world_bounds().position - old_b.position
			var toi := swept_time(old_a, da, old_b, db)
			if toi >= 0: candidates.append({"a": a, "b": b, "time": toi, "point": contact_point(Rect2(old_a.position + da * toi, old_a.size), Rect2(old_b.position + db * toi, old_b.size))})
	# Time of impact, then stable owner/shot sequence, never callback order or RNG.
	candidates.sort_custom(func(a, b): return a.time < b.time if a.time != b.time else a.a.order_id < b.a.order_id if a.a.order_id != b.a.order_id else a.b.order_id < b.b.order_id)
	for pair in candidates:
		var a = pair.a; var b = pair.b
		if not a.active or not b.active: continue
		a.intercepted_ids[b.order_id] = true; b.intercepted_ids[a.order_id] = true
		var ai: int = a.integrity; var bi: int = b.integrity
		var event_id := "projectile:%d:%d:%d" % [frame, a.order_id, b.order_id]
		var result := "mutual_cancel" if ai == bi else "breakthrough"
		var renderer = a._renderer if is_instance_valid(a._renderer) else b._renderer
		a.intercept(bi); b.intercept(ai)
		var winner_direction: Vector2 = a.direction if ai > bi else b.direction
		var event := {"event_id": event_id, "confirmed_interception": true, "sim_frame": frame, "physics_frame": Engine.get_physics_frames(), "a": a.order_id, "b": b.order_id, "fighters": [a.fighter_id, b.fighter_id], "before": [ai, bi], "after": [a.integrity, b.integrity], "result": result, "world": [pair.point.x, pair.point.y], "time_of_impact": pair.time, "winner_direction": [winner_direction.x, winner_direction.y]}
		history.append(event)
		if history.size() > 256: history.pop_front()
		interception_confirmed.emit(event.duplicate(true))
		if is_instance_valid(renderer): renderer.projectile_contact(a.fighter_id, b.fighter_id, pair.point, a.direction, result, event_id, a, event)
	# All projectile interceptions have resolved. A canceled shot can never
	# consume a pending overlap or a swept hurtbox contact later in this frame.
	for shot in live:
		if not shot.active: continue
		var old: Rect2 = starts.get(shot.order_id, shot.spawn_bounds)
		var travel: Vector2 = shot.world_bounds().position - old.position
		var targets: Array = []
		for target in fighters:
			if not is_instance_valid(target) or target == shot.owner_fighter or not target.has_method("receive_hit"): continue
			var shape = target.get_node_or_null("Hurtbox/HurtShape")
			if shape == null: continue
			var bounds: Rect2 = target.hit_resolver._world_bounds(shape)
			var toi := swept_time(old, travel, bounds, Vector2.ZERO)
			if toi >= 0 or shot.pending_targets.has(target.get_instance_id()): targets.append({"target": target, "time": maxf(0, toi), "slot": target.slot, "point": contact_point(Rect2(old.position + travel * maxf(0, toi), old.size), bounds) if toi >= 0 else shot.global_position})
		targets.sort_custom(func(a, b): return a.time < b.time if a.time != b.time else a.slot < b.slot)
		shot.pending_targets.clear()
		for candidate in targets:
			if shot.active: shot._deliver_hit(candidate.target, candidate.point)
	starts.clear()
	last_resolve_us = Time.get_ticks_usec() - started
