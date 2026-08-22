extends RefCounted
class_name CombatMath

const FPS := 60.0
const DI_BASE := 0.085
const DI_HEAVY := 0.12
const DI_LAUNCH := 0.16
const SHORT_HOP_MULT := 0.72
const JUMP_SQUAT_FRAMES := 3
const LANDING_LAG_NORMAL := 0.08
const LANDING_LAG_AERIAL := 0.14
const LANDING_LAG_FAST_FALL := 0.18
const AIR_DODGE_RECOVERY := 0.18
const GROUND_DODGE_RECOVERY := 0.12
const AIR_DODGE_INVULN := 0.14
const GROUND_DODGE_INVULN := 0.10
## WAVE011 competitive depth — canonical constants (mutation-sensitive).
const AURA_CHARGE_PER_SECOND := 35.0
const AURA_IDLE_DECAY_PER_SECOND := 4.0
const AURA_HIT_INTERRUPT_LOSS := 20.0
const CHARGE_MOVE_MULT := 0.42
const GRAB_MASH_ESCAPE := 1.0
const GRAB_MASH_PER_PRESS := 0.28
const TECH_WINDOW_SEC := 0.12
const SHIELD_REGEN_PER_SECOND := 14.0
const STALE_DECAY := 0.12
const STALE_FLOOR := 0.55
const DEFAULT_AIR_ACCEL := 1400.0
const DEFAULT_TRACTION := 1800.0
const GRAB_RANGE_PX := 70.0

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

## Apply directional influence during hitstun/launch. Stick axes in [-1,1].
static func apply_di(launch: Vector2, stick_x: float, stick_y: float, strength: String = "medium") -> Vector2:
	if strength == "light":
		return launch
	var influence := DI_BASE
	match strength:
		"heavy":
			influence = DI_HEAVY
		"launch", "super":
			influence = DI_LAUNCH
	var out := launch
	if absf(stick_x) > 0.2:
		out.x += stick_x * influence * maxf(absf(launch.x), 4.0)
	if absf(stick_y) > 0.2:
		# Up reduces vertical launch magnitude slightly; down steepens.
		if stick_y < 0.0:
			out.y += stick_y * influence * 0.6 * maxf(absf(launch.y), 3.0)
		else:
			out.y += stick_y * influence * 0.4 * maxf(absf(launch.y), 3.0)
	return out

static func di_strength_for_kb(kb_mag: float, damage: float) -> String:
	if kb_mag > 18.0 or damage >= 14.0:
		return "launch"
	if kb_mag > 12.0 or damage >= 8.0:
		return "heavy"
	if kb_mag > 6.0:
		return "medium"
	return "light"

static func short_hop_velocity(full_jump: float) -> float:
	return full_jump * SHORT_HOP_MULT

static func landing_lag_seconds(from_aerial: bool, from_fast_fall: bool, move_override: float = -1.0) -> float:
	if move_override > 0.0:
		return move_override
	if from_fast_fall:
		return LANDING_LAG_FAST_FALL
	if from_aerial:
		return LANDING_LAG_AERIAL
	return LANDING_LAG_NORMAL


static func stale_multiplier(repeat_count: int) -> float:
	return maxf(STALE_FLOOR, 1.0 - STALE_DECAY * float(maxi(0, repeat_count)))


static func combo_decay(combo_count: int) -> float:
	if combo_count <= 1:
		return 1.0
	return maxf(0.62, 1.0 - 0.06 * float(combo_count - 1))


static func shield_decay_per_second(profile: Dictionary) -> float:
	return float(profile.get("decayPerSecond", 18.0))


static func tech_window_seconds() -> float:
	return TECH_WINDOW_SEC
