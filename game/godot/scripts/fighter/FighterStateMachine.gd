extends Node
class_name FighterStateMachine

signal state_changed(previous_state: int, new_state: int)

enum State {
	IDLE,
	WALK,
	RUN,
	DASH,
	JUMP,
	DOUBLE_JUMP,
	FALL,
	FAST_FALL,
	LAND,
	ATTACK_STARTUP,
	ATTACK_ACTIVE,
	ATTACK_RECOVERY,
	SPECIAL_STARTUP,
	SPECIAL_ACTIVE,
	SPECIAL_RECOVERY,
	AURA_CHARGE,
	HITSTOP,
	HITSTUN,
	TUMBLE,
	LAUNCHED,
	SHIELD,
	DODGE,
	KO,
	VICTORY,
	DEFEAT
}

const STATE_LABELS := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.RUN: "run",
	State.DASH: "dash",
	State.JUMP: "jump",
	State.DOUBLE_JUMP: "double_jump",
	State.FALL: "fall",
	State.FAST_FALL: "fast_fall",
	State.LAND: "land",
	State.ATTACK_STARTUP: "attack_startup",
	State.ATTACK_ACTIVE: "attack_active",
	State.ATTACK_RECOVERY: "attack_recovery",
	State.SPECIAL_STARTUP: "special_startup",
	State.SPECIAL_ACTIVE: "special_active",
	State.SPECIAL_RECOVERY: "special_recovery",
	State.AURA_CHARGE: "aura_charge",
	State.HITSTOP: "hitstop",
	State.HITSTUN: "hitstun",
	State.TUMBLE: "tumble",
	State.LAUNCHED: "launched",
	State.SHIELD: "shield",
	State.DODGE: "dodge",
	State.KO: "ko",
	State.VICTORY: "victory",
	State.DEFEAT: "defeat"
}

@export var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var state_time: float = 0.0

func _physics_process(delta: float) -> void:
	state_time += delta

func transition_to(next_state: State) -> void:
	if current_state == next_state:
		return
	previous_state = current_state
	current_state = next_state
	state_time = 0.0
	state_changed.emit(previous_state, current_state)

func is_state(state: State) -> bool:
	return current_state == state

func is_grounded_state() -> bool:
	return current_state in [State.IDLE, State.WALK, State.RUN, State.DASH, State.LAND, State.SHIELD]

func is_attacking() -> bool:
	return current_state in [State.ATTACK_STARTUP, State.ATTACK_ACTIVE, State.ATTACK_RECOVERY]

func is_specialing() -> bool:
	return current_state in [State.SPECIAL_STARTUP, State.SPECIAL_ACTIVE, State.SPECIAL_RECOVERY]

func get_state_name() -> String:
	return STATE_LABELS.get(current_state, "unknown")
