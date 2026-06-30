extends RefCounted
class_name FighterAnimationStates

const MACHINE_TO_TREE := {
	FighterStateMachine.State.IDLE: "idle",
	FighterStateMachine.State.WALK: "walk",
	FighterStateMachine.State.RUN: "run",
	FighterStateMachine.State.DASH: "dash",
	FighterStateMachine.State.JUMP: "jump_rise",
	FighterStateMachine.State.DOUBLE_JUMP: "double_jump",
	FighterStateMachine.State.FALL: "fall",
	FighterStateMachine.State.FAST_FALL: "fast_fall",
	FighterStateMachine.State.LAND: "land",
	FighterStateMachine.State.ATTACK_STARTUP: "neutral_attack_startup",
	FighterStateMachine.State.ATTACK_ACTIVE: "neutral_attack_active",
	FighterStateMachine.State.ATTACK_RECOVERY: "neutral_attack_recovery",
	FighterStateMachine.State.SPECIAL_STARTUP: "neutral_special",
	FighterStateMachine.State.SPECIAL_ACTIVE: "neutral_special",
	FighterStateMachine.State.SPECIAL_RECOVERY: "neutral_special",
	FighterStateMachine.State.AURA_CHARGE: "aura_charge",
	FighterStateMachine.State.HITSTOP: "hitstun_light",
	FighterStateMachine.State.HITSTUN: "hitstun_heavy",
	FighterStateMachine.State.TUMBLE: "launch_tumble",
	FighterStateMachine.State.LAUNCHED: "launch_tumble",
	FighterStateMachine.State.SHIELD: "shield",
	FighterStateMachine.State.DODGE: "dodge",
	FighterStateMachine.State.KO: "defeat",
	FighterStateMachine.State.VICTORY: "victory",
	FighterStateMachine.State.DEFEAT: "defeat",
}

static func from_machine_state(state: int) -> StringName:
	return StringName(MACHINE_TO_TREE.get(state, "idle"))
