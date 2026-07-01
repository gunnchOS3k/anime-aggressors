extends Node
class_name FighterStateMachine

signal state_changed(from_state: String, to_state: String)

var current_state: String = FighterStates.IDLE
var previous_state: String = FighterStates.IDLE
var state_frame: int = 0
var state_time: float = 0.0
var owner: AAFighter

func setup(fighter: AAFighter) -> void:
	owner = fighter

func enter(state: String) -> void:
	if state == current_state:
		return
	previous_state = current_state
	current_state = state
	state_frame = 0
	state_time = 0.0
	state_changed.emit(previous_state, current_state)
	_on_enter(state)

func update(delta: float) -> void:
	state_time += delta
	state_frame += 1
	_on_update(current_state, delta)

func can_move() -> bool:
	return not FighterStates.locks_movement(current_state) and owner != null and owner.controls_enabled

func can_attack() -> bool:
	return not FighterStates.locks_actions(current_state) and owner != null and owner.controls_enabled

func _on_enter(state: String) -> void:
	if owner == null:
		return
	match state:
		FighterStates.SHIELD_START, FighterStates.SHIELD_HOLD:
			owner.shielding = true
		FighterStates.SHIELD_BREAK:
			owner.shielding = false
			owner.shield_health = 0.0
		FighterStates.DODGE_ACTIVE:
			owner.invincible = true
		FighterStates.AURA_READY:
			owner.aura = 100.0
		FighterStates.GRAB_HOLD:
			if owner.grabbed_target:
				owner.grabbed_target.grabbed_by = owner
		FighterStates.KO:
			owner.velocity = Vector2.ZERO
		FighterStates.RESPAWN:
			owner.invincible = true

func _on_update(state: String, delta: float) -> void:
	if owner == null:
		return
	match state:
		FighterStates.SHIELD_HOLD:
			owner.shield_health = maxf(0.0, owner.shield_health - 8.0 * delta)
		FighterStates.AURA_CHARGE:
			if not owner.is_aura_input_held():
				owner.state_machine.enter(FighterStates.AURA_READY if owner.aura >= 100.0 else FighterStates.IDLE)
		FighterStates.SHIELD_STUN:
			if state_time > 0.25:
				owner.state_machine.enter(FighterStates.IDLE)
		FighterStates.DODGE_RECOVERY:
			if state_time > 0.12:
				owner.invincible = false
				owner.state_machine.enter(FighterStates.IDLE)
		FighterStates.HITSTUN:
			if state_time > owner.hitstun_remaining:
				owner.state_machine.enter(FighterStates.IDLE)
		FighterStates.LAUNCHED:
			if owner.is_on_floor() and owner.velocity.y >= 0:
				owner.state_machine.enter(FighterStates.TUMBLE if owner.velocity.length() > 120 else FighterStates.LAND)
		FighterStates.TUMBLE:
			if state_time > 0.35:
				owner.state_machine.enter(FighterStates.FALL)
		FighterStates.LAND:
			if state_time > 0.08:
				owner.state_machine.enter(FighterStates.IDLE)
		FighterStates.GRAB_WHIFF:
			if state_time > 0.3:
				owner.state_machine.enter(FighterStates.IDLE)
		FighterStates.GRAB_HOLD:
			if state_time > 2.0:
				owner.execute_throw()
		FighterStates.ATTACK_RECOVERY, FighterStates.SPECIAL_RECOVERY, FighterStates.AURA_BURST_RECOVERY:
			if state_time > 0.12:
				owner.state_machine.enter(FighterStates.IDLE)
		FighterStates.SHIELD_BREAK:
			if state_time > 0.4:
				owner.shield_health = float(owner.data.get("shieldProfile", {}).get("maxHealth", 100))
				owner.state_machine.enter(FighterStates.IDLE)
