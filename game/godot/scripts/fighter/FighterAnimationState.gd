extends RefCounted
class_name FighterAnimationState

const STATE_TO_ANIMATION := {
	FighterStateMachine.State.IDLE: "idle",
	FighterStateMachine.State.WALK: "walk",
	FighterStateMachine.State.RUN: "run",
	FighterStateMachine.State.DASH: "dash",
	FighterStateMachine.State.JUMP: "jump",
	FighterStateMachine.State.DOUBLE_JUMP: "double_jump",
	FighterStateMachine.State.FALL: "fall",
	FighterStateMachine.State.FAST_FALL: "fast_fall",
	FighterStateMachine.State.LAND: "land",
	FighterStateMachine.State.ATTACK_STARTUP: "attack_startup",
	FighterStateMachine.State.ATTACK_ACTIVE: "attack_active",
	FighterStateMachine.State.ATTACK_RECOVERY: "attack_recovery",
	FighterStateMachine.State.SPECIAL_STARTUP: "special_startup",
	FighterStateMachine.State.SPECIAL_ACTIVE: "special_active",
	FighterStateMachine.State.SPECIAL_RECOVERY: "special_recovery",
	FighterStateMachine.State.AURA_CHARGE: "aura_charge",
	FighterStateMachine.State.HITSTOP: "hitstop",
	FighterStateMachine.State.HITSTUN: "hitstun",
	FighterStateMachine.State.TUMBLE: "tumble",
	FighterStateMachine.State.LAUNCHED: "launched",
	FighterStateMachine.State.SHIELD: "shield",
	FighterStateMachine.State.DODGE: "dodge",
	FighterStateMachine.State.KO: "ko",
	FighterStateMachine.State.VICTORY: "victory",
	FighterStateMachine.State.DEFEAT: "defeat"
}

static func from_state(state: int) -> StringName:
	return StringName(STATE_TO_ANIMATION.get(state, "idle"))
