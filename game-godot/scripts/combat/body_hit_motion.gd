extends RefCounted
## Shared, pure launch/reaction policy. Damage and contact remain owned by
## HitResolver/Fighter. No side effects, timers, physics or balance overrides.
const MathRules = preload("res://scripts/combat/combat_math.gd")
const States = preload("res://scripts/fighters/fighter_states.gd")

static func resolve(launch: Vector2, applied_damage: float, stick_x: float, stick_y: float, hitstop_frames: int) -> Dictionary:
	var strength := MathRules.di_strength_for_kb(launch.length(), applied_damage)
	var directed := MathRules.apply_di(launch, stick_x, stick_y, strength)
	var state: String = States.LAUNCHED if directed.length() > 14.0 else States.HURT_HEAVY if applied_damage >= 8.0 else States.HURT_LIGHT
	return {"velocity":directed, "di_strength":strength, "hitstun":MathRules.hitstun_seconds(directed.length()),
		"hitstop":MathRules.frames_to_seconds(hitstop_frames), "state":state}
