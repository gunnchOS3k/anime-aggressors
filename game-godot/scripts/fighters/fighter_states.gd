extends RefCounted
class_name FighterStates

## Full-scope fighter state labels (visible in debug HUD).

const IDLE := "idle"
const WALK := "walk"
const RUN := "run"
const DASH := "dash"
const SKID := "skid"
const JUMP_SQUAT := "jump_squat"
const JUMP := "jump"
const DOUBLE_JUMP := "double_jump"
const FALL := "fall"
const FAST_FALL := "fast_fall"
const LAND := "land"
const ATTACK_STARTUP := "attack_startup"
const ATTACK_ACTIVE := "attack_active"
const ATTACK_RECOVERY := "attack_recovery"
const SPECIAL_STARTUP := "special_startup"
const SPECIAL_ACTIVE := "special_active"
const SPECIAL_RECOVERY := "special_recovery"
const SHIELD_START := "shield_start"
const SHIELD_HOLD := "shield_hold"
const SHIELD_STUN := "shield_stun"
const SHIELD_BREAK := "shield_break"
const DODGE := "dodge"
const GRAB_STARTUP := "grab_startup"
const GRAB_ACTIVE := "grab_active"
const GRAB_WHIFF := "grab_whiff"
const THROW := "throw"
const AURA_CHARGE := "aura_charge"
const AURA_READY := "aura_ready"
const AURA_BURST := "aura_burst"
const HURT_LIGHT := "hurt_light"
const HURT_HEAVY := "hurt_heavy"
const HITSTOP := "hitstop"
const HITSTUN := "hitstun"
const LAUNCHED := "launched"
const TUMBLE := "tumble"
const LEDGE := "ledge"
const KO := "ko"
const RESPAWN := "respawn"
const VICTORY := "victory"
const DEFEAT := "defeat"

static func all_states() -> Array[String]:
	return [
		IDLE, WALK, RUN, DASH, SKID, JUMP_SQUAT, JUMP, DOUBLE_JUMP, FALL, FAST_FALL, LAND,
		ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY,
		SPECIAL_STARTUP, SPECIAL_ACTIVE, SPECIAL_RECOVERY,
		SHIELD_START, SHIELD_HOLD, SHIELD_STUN, SHIELD_BREAK, DODGE,
		GRAB_STARTUP, GRAB_ACTIVE, GRAB_WHIFF, THROW,
		AURA_CHARGE, AURA_READY, AURA_BURST,
		HURT_LIGHT, HURT_HEAVY, HITSTOP, HITSTUN, LAUNCHED, TUMBLE, LEDGE,
		KO, RESPAWN, VICTORY, DEFEAT,
	]

static func is_attack_state(s: String) -> bool:
	return s in [ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY, SPECIAL_STARTUP, SPECIAL_ACTIVE, SPECIAL_RECOVERY, AURA_BURST]

static func is_hurt_state(s: String) -> bool:
	return s in [HURT_LIGHT, HURT_HEAVY, HITSTOP, HITSTUN, LAUNCHED, TUMBLE, SHIELD_STUN]
