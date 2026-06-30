extends RefCounted
class_name FighterAnimationStateMachine

## Canonical animation state ids for the vertical slice (mirrors FighterAnimationStates).

const STATES := [
	"idle", "walk", "run", "dash",
	"jump_start", "jump_rise", "double_jump", "fall", "fast_fall", "land",
	"neutral_attack_startup", "neutral_attack_active", "neutral_attack_recovery",
	"side_attack_startup", "side_attack_active", "side_attack_recovery",
	"up_attack", "down_attack",
	"neutral_special", "side_special", "up_special", "down_special",
	"aura_charge_loop",
	"hitstun_light", "hitstun_heavy", "launch_tumble", "ko", "victory", "defeat",
]

static func has_state(state_id: String) -> bool:
	return state_id in STATES

static func from_combat_state(combat_state: int) -> String:
	return FighterAnimationState.from_state(combat_state)
