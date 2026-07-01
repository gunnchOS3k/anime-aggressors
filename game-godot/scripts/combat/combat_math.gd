extends RefCounted
class_name CombatMath

const FPS := 60.0

static func frames_to_seconds(frames: int) -> float:
	return float(frames) / FPS

static func knockback_vector(damage_percent: float, base_kb: float, growth: float, angle_deg: float, weight: float, facing: int) -> Vector2:
	var kb := (base_kb + damage_percent * growth) * (100.0 / weight)
	var rad := deg_to_rad(angle_deg)
	return Vector2(cos(rad) * kb * facing, -sin(rad) * kb)

static func scaled_damage(base: float, dealt_mult: float) -> float:
	return base * dealt_mult

static func hitstun_seconds(kb_mag: float) -> float:
	return clampf(kb_mag * 0.012, 0.08, 0.55)
