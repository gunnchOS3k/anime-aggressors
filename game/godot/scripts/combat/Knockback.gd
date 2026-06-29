extends RefCounted
class_name Knockback

static func calculate_velocity(
	damage_percent: float,
	base_knockback: float,
	knockback_growth: float,
	angle_deg: float,
	victim_weight: float = 1.0
) -> Vector2:
	var weight_factor := maxf(0.5, victim_weight)
	var scaled_force := (base_knockback + damage_percent * 4.2 * knockback_growth) / weight_factor
	var angle_rad := deg_to_rad(angle_deg)
	return Vector2.RIGHT.rotated(-angle_rad) * scaled_force

static func calculate_hitstun_seconds(knockback_velocity: Vector2) -> float:
	return clampf(knockback_velocity.length() * 0.0028, 0.08, 1.20)
