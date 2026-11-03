extends RefCounted
## Owner-authorized playable tuning candidates. No boss immunity, parry,
## reflection, forced placement, new hitstop or bypass of projectile authority.
const Sfx = preload("res://scripts/audio/elemental_performance.gd")
const Vfx = preload("res://scripts/visual/spectral_feedback_renderer.gd")

static func on_active(actor, move: Dictionary) -> bool:
	if actor.fighter_id != "yin" or not move.has("cosmic_counter"): return false
	actor.hitbox.monitoring = false
	actor.state_machine.enter("special_active")
	if actor.move_runner.frame_in_phase == 1:
		var renderer = Vfx.obtain(actor)
		if renderer != null: renderer.emit_effect("yin", 2, actor.global_position + Vector2(0, -24), Vector2(actor.facing, 0), 54, .14)
		Sfx.one_shot("yin", "charge_release", actor, .4)
	return true

static func absorb(actor, shot, point: Vector2) -> bool:
	if actor.fighter_id != "yin" or not actor.move_runner.is_active_phase(): return false
	var policy: Dictionary = actor.move_runner.move_data.get("cosmic_counter", {})
	if policy.is_empty() or actor._cosmic_counter_activation == actor.move_runner.activation_id: return false
	if actor.invincible or actor.grabbed_by != null or actor._hitstop > 0 or actor.stocks <= 0 or actor.get_meta("story_cosmic_contract", false) or actor.get_meta("story_released", false): return false
	if not shot.active or not shot.clash_eligible or shot.integrity > int(policy.max_integrity): return false
	var cost := float(policy.aura_cost)
	if actor.aura < cost: return false
	# Called only at the existing swept fighter-contact point, AFTER all normal
	# projectile clashes resolve. One eligible shot per real move activation.
	actor._cosmic_counter_activation = actor.move_runner.activation_id
	actor.aura -= cost
	shot.global_position = point
	shot.intercept(shot.integrity)
	var event := {"event_id": "yin-absorb:%d:%d:%d" % [actor.slot, actor.move_runner.activation_id, shot.order_id], "frame": Engine.get_physics_frames(), "result": "projectile_absorbed", "projectile": shot.order_id, "source_fighter": shot.fighter_id, "aura_cost": cost, "world": [point.x, point.y], "damage": 0}
	actor.cosmic_kit_history.append(event)
	if actor.cosmic_kit_history.size() > 64: actor.cosmic_kit_history.pop_front()
	actor.stamp_runtime_hook("projectile_absorption")
	var renderer = Vfx.obtain(actor)
	if renderer != null: renderer.emit_effect("yin", 1, point, shot.direction, 68, .16, event.event_id)
	Sfx.one_shot("yin", "block", actor, .6)
	return true
