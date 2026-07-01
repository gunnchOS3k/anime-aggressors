extends Node
class_name FighterStateMachine

signal state_changed(from_state: String, to_state: String)

var current_state: String = FighterStates.IDLE
var previous_state: String = FighterStates.IDLE
var state_frame: int = 0
var state_time: float = 0.0

func enter(state: String) -> void:
	if state == current_state:
		return
	previous_state = current_state
	current_state = state
	state_frame = 0
	state_time = 0.0
	state_changed.emit(previous_state, current_state)
	_on_enter(state)

func _on_enter(state: String) -> void:
	pass

func update(delta: float) -> void:
	state_time += delta
	state_frame += 1
	_on_update(current_state, delta)

func _on_update(_state: String, _delta: float) -> void:
	pass

func can_move() -> bool:
	return not FighterStates.is_attack_state(current_state) and not FighterStates.is_hurt_state(current_state) and current_state not in [FighterStates.SHIELD_HOLD, FighterStates.AURA_CHARGE, FighterStates.KO, FighterStates.RESPAWN]

func can_attack() -> bool:
	return current_state in [FighterStates.IDLE, FighterStates.WALK, FighterStates.RUN, FighterStates.FALL, FighterStates.JUMP, FighterStates.DOUBLE_JUMP]
