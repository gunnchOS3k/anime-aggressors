extends RefCounted
class_name FighterStates

const FPS := 60.0

const IDLE := "idle"
const WALK := "walk"
const RUN := "run"
const DASH := "dash"
const SKID := "skid"
const TURNAROUND := "turnaround"
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
const DODGE_START := "dodge_start"
const DODGE_ACTIVE := "dodge_active"
const DODGE_RECOVERY := "dodge_recovery"
const GRAB_STARTUP := "grab_startup"
const GRAB_ACTIVE := "grab_active"
const GRAB_WHIFF := "grab_whiff"
const GRAB_HOLD := "grab_hold"
const THROW_STARTUP := "throw_startup"
const THROW_RELEASE := "throw_release"
const AURA_CHARGE := "aura_charge"
const AURA_READY := "aura_ready"
const AURA_BURST_STARTUP := "aura_burst_startup"
const AURA_BURST_ACTIVE := "aura_burst_active"
const AURA_BURST_RECOVERY := "aura_burst_recovery"
const HURT_LIGHT := "hurt_light"
const HURT_HEAVY := "hurt_heavy"
const HITSTOP := "hitstop"
const HITSTUN := "hitstun"
const LAUNCHED := "launched"
const TUMBLE := "tumble"
const EDGE_WARNING := "edge_warning"
const LEDGE_TEETER := "ledge_teeter"
const KO := "ko"
const RESPAWN := "respawn"
const VICTORY := "victory"
const DEFEAT := "defeat"

static func all_states() -> Array[String]:
	return [
		IDLE, WALK, RUN, DASH, SKID, TURNAROUND, JUMP_SQUAT, JUMP, DOUBLE_JUMP, FALL, FAST_FALL, LAND,
		ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY,
		SPECIAL_STARTUP, SPECIAL_ACTIVE, SPECIAL_RECOVERY,
		SHIELD_START, SHIELD_HOLD, SHIELD_STUN, SHIELD_BREAK,
		DODGE_START, DODGE_ACTIVE, DODGE_RECOVERY,
		GRAB_STARTUP, GRAB_ACTIVE, GRAB_WHIFF, GRAB_HOLD, THROW_STARTUP, THROW_RELEASE,
		AURA_CHARGE, AURA_READY, AURA_BURST_STARTUP, AURA_BURST_ACTIVE, AURA_BURST_RECOVERY,
		HURT_LIGHT, HURT_HEAVY, HITSTOP, HITSTUN, LAUNCHED, TUMBLE,
		EDGE_WARNING, LEDGE_TEETER, KO, RESPAWN, VICTORY, DEFEAT,
	]

static func is_attack_state(s: String) -> bool:
	return s in [
		ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY,
		SPECIAL_STARTUP, SPECIAL_ACTIVE, SPECIAL_RECOVERY,
		AURA_BURST_STARTUP, AURA_BURST_ACTIVE, AURA_BURST_RECOVERY,
		THROW_STARTUP, THROW_RELEASE,
	]

static func is_hurt_state(s: String) -> bool:
	return s in [HURT_LIGHT, HURT_HEAVY, HITSTOP, HITSTUN, LAUNCHED, TUMBLE, SHIELD_STUN, SHIELD_BREAK]

static func locks_movement(s: String) -> bool:
	return is_attack_state(s) or is_hurt_state(s) or s in [
		SHIELD_HOLD, SHIELD_START, GRAB_HOLD, GRAB_STARTUP, GRAB_ACTIVE,
		AURA_CHARGE, AURA_BURST_STARTUP, AURA_BURST_ACTIVE, AURA_BURST_RECOVERY,
		KO, RESPAWN, GRAB_WHIFF,
	]

static func locks_actions(s: String) -> bool:
	return locks_movement(s) or s in [DODGE_ACTIVE, DODGE_START, HITSTOP]

static func animation_for_state(s: String) -> String:
	match s:
		WALK, RUN: return "walk"
		DASH: return "dash"
		JUMP, JUMP_SQUAT, DOUBLE_JUMP: return "jump"
		FALL, FAST_FALL, TUMBLE: return "fall"
		LAND: return "land"
		ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY: return "jab"
		SPECIAL_STARTUP, SPECIAL_ACTIVE, SPECIAL_RECOVERY: return "special"
		SHIELD_START, SHIELD_HOLD, SHIELD_STUN: return "shield"
		DODGE_START, DODGE_ACTIVE: return "dash"
		GRAB_STARTUP, GRAB_ACTIVE, GRAB_HOLD: return "grab"
		THROW_STARTUP, THROW_RELEASE: return "throw"
		AURA_CHARGE, AURA_READY: return "aura_charge"
		AURA_BURST_STARTUP, AURA_BURST_ACTIVE, AURA_BURST_RECOVERY: return "aura_burst"
		HURT_LIGHT: return "hurt_light"
		HURT_HEAVY, HITSTUN: return "hurt_heavy"
		LAUNCHED: return "launched"
		KO: return "ko"
		VICTORY: return "victory"
		DEFEAT: return "defeat"
		EDGE_WARNING, LEDGE_TEETER: return "idle"
		_: return "idle"
