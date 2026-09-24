extends RefCounted
class_name FighterFacingContract

## Authoritative presentation facing. Does not change CombatMath knockback formulas.
## logical_facing = LEFT | RIGHT
## presentation_forward derived from logical_facing
## attack_direction locked at attack start unless the move explicitly turns
## mesh_forward_axis = +Z (KayKit / current candidate GLBs)
## animation_root_yaw is presentation-only and bounded

const FACING_LEFT := "LEFT"
const FACING_RIGHT := "RIGHT"
const MESH_FORWARD_AXIS := "+Z"
const ATTACK_YAW_RIGHT := 42.0
const ATTACK_YAW_LEFT := -42.0
const MAX_ROOT_YAW_DELTA := 18.0
const HURT_YAW_SCALE := 10.0


static func logical_facing_from_int(facing: int) -> String:
	return FACING_RIGHT if facing >= 0 else FACING_LEFT


static func facing_int(logical: String) -> int:
	return 1 if logical == FACING_RIGHT else -1


static func presentation_forward(logical: String) -> Vector2:
	return Vector2(1.0, 0.0) if logical == FACING_RIGHT else Vector2(-1.0, 0.0)


static func lock_attack_direction(logical: String, move: Dictionary = {}) -> Dictionary:
	var turns := bool(move.get("explicit_turn", false)) or str(move.get("direction", "")) == "back"
	return {
		"logical_facing": logical,
		"presentation_forward": presentation_forward(logical),
		"attack_direction": facing_int(logical),
		"locked": not turns,
		"explicit_turn": turns,
		"mesh_forward_axis": MESH_FORWARD_AXIS,
		"mesh_yaw_deg": ATTACK_YAW_RIGHT if logical == FACING_RIGHT else ATTACK_YAW_LEFT,
		"animation_root_yaw_bound": MAX_ROOT_YAW_DELTA,
	}


static func mesh_yaw_for_facing(logical: String) -> float:
	return ATTACK_YAW_RIGHT if logical == FACING_RIGHT else ATTACK_YAW_LEFT


static func bound_root_yaw(base_yaw: float, requested_delta: float) -> float:
	return base_yaw + clampf(requested_delta, -MAX_ROOT_YAW_DELTA, MAX_ROOT_YAW_DELTA)


static func projectile_sign(attack_direction: int, fallback_facing: int) -> int:
	if attack_direction == 0:
		return 1 if fallback_facing >= 0 else -1
	return 1 if attack_direction >= 0 else -1


static func hurt_away_from_force(incoming: Vector2) -> Dictionary:
	var force := incoming
	if force.length_squared() < 0.0001:
		force = Vector2(1.0, 0.0)
	var dir := force.normalized()
	var logical := FACING_LEFT if dir.x > 0.0 else FACING_RIGHT
	return {
		"logical_facing": logical,
		"react_dir": dir,
		"mesh_yaw_deg": mesh_yaw_for_facing(logical) + dir.x * HURT_YAW_SCALE,
		"launch_follows_force": true,
		"readable_hurt_before_launch": true,
	}


static func launch_follows_force(incoming: Vector2) -> bool:
	return incoming.length_squared() > 0.0


static func attack_faces_target(attacker_logical: String, attacker_x: float, defender_x: float) -> bool:
	if attacker_logical == FACING_RIGHT:
		return attacker_x <= defender_x
	return attacker_x >= defender_x


static func contract_dict() -> Dictionary:
	return {
		"logical_facing": "LEFT | RIGHT",
		"presentation_forward": "derived from logical_facing",
		"attack_direction": "locked at attack start unless the move explicitly turns",
		"mesh_forward_axis": MESH_FORWARD_AXIS,
		"animation_root_yaw": "presentation-only and bounded",
		"max_root_yaw_delta": MAX_ROOT_YAW_DELTA,
	}
