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
const AIR_DODGE := "air_dodge"
const LEDGE_HANG := "ledge_hang"
const LEDGE_GETUP := "ledge_getup"
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
		DODGE_START, DODGE_ACTIVE, DODGE_RECOVERY, AIR_DODGE,
		GRAB_STARTUP, GRAB_ACTIVE, GRAB_WHIFF, GRAB_HOLD, THROW_STARTUP, THROW_RELEASE,
		AURA_CHARGE, AURA_READY, AURA_BURST_STARTUP, AURA_BURST_ACTIVE, AURA_BURST_RECOVERY,
		HURT_LIGHT, HURT_HEAVY, HITSTOP, HITSTUN, LAUNCHED, TUMBLE,
		EDGE_WARNING, LEDGE_TEETER, LEDGE_HANG, LEDGE_GETUP, KO, RESPAWN, VICTORY, DEFEAT,
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
		AURA_BURST_STARTUP, AURA_BURST_ACTIVE, AURA_BURST_RECOVERY,
		KO, RESPAWN, GRAB_WHIFF, JUMP_SQUAT, LAND, LEDGE_HANG, LEDGE_GETUP,
		AIR_DODGE, DODGE_ACTIVE, DODGE_RECOVERY,
	]

static func locks_actions(s: String) -> bool:
	return locks_movement(s) or s in [DODGE_ACTIVE, DODGE_START, AIR_DODGE, HITSTOP, JUMP_SQUAT, LAND]

static func animation_for_state(s: String) -> String:
	## Animation Authority V1 temporary fallbacks (continuity only).
	## Prefer RuntimeMoveResolver exact move/state clips; these are last-resort names.
	match s:
		IDLE: return "idle_primary"
		WALK: return "walk_loop"
		RUN: return "run_loop"
		DASH: return "dash_loop"
		SKID: return "skid"
		TURNAROUND: return "turnaround"
		JUMP_SQUAT: return "jump_squat"
		JUMP: return "jump"
		DOUBLE_JUMP: return "double_jump"
		FALL: return "fall"
		FAST_FALL: return "fast_fall"
		TUMBLE: return "tumble"
		LAND: return "land_soft"
		# Attack/special/throw without move_id must not invent a silent universal jab.
		# Resolver supplies move-specific clips when move_id is present.
		ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY: return "jab_1"
		SPECIAL_STARTUP, SPECIAL_ACTIVE, SPECIAL_RECOVERY: return "neutral_special_projectile"
		SHIELD_START: return "shield_start"
		SHIELD_HOLD: return "shield_hold"
		SHIELD_STUN: return "shield_stun"
		SHIELD_BREAK: return "shield_break"
		DODGE_START, DODGE_ACTIVE, DODGE_RECOVERY: return "spot_dodge"
		AIR_DODGE: return "air_dodge_neutral"
		GRAB_STARTUP: return "grab_startup"
		GRAB_ACTIVE: return "grab_active"
		GRAB_WHIFF: return "grab_whiff"
		GRAB_HOLD: return "grab_hold"
		THROW_STARTUP: return "throw_startup"
		THROW_RELEASE: return "throw_release"
		AURA_CHARGE: return "aura_charge"
		AURA_READY: return "aura_ready"
		AURA_BURST_STARTUP: return "aura_burst_startup"
		AURA_BURST_ACTIVE: return "aura_burst_active"
		AURA_BURST_RECOVERY: return "aura_burst_recovery"
		HURT_LIGHT: return "hurt_light_front"
		HURT_HEAVY: return "hurt_heavy"
		HITSTOP: return "hitstop_pose"
		HITSTUN: return "hitstun_ground"
		LAUNCHED: return "launch_horizontal"
		KO: return "ko"
		RESPAWN: return "respawn"
		VICTORY: return "victory"
		DEFEAT: return "defeat"
		EDGE_WARNING: return "edge_warning"
		LEDGE_TEETER: return "ledge_teeter"
		LEDGE_HANG: return "ledge_hang"
		LEDGE_GETUP: return "ledge_getup"
		_: return "idle_primary"
