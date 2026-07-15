extends Node
class_name FighterStateMachine

signal state_changed(from_state: String, to_state: String)

var current_state: String = FighterStates.IDLE
var previous_state: String = FighterStates.IDLE
var state_frame: int = 0
var state_time: float = 0.0
var _fighter

func setup(fighter) -> void:
	_fighter = fighter

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
	return not FighterStates.locks_movement(current_state) and _fighter != null and _fighter.controls_enabled

func can_attack() -> bool:
	return not FighterStates.locks_actions(current_state) and _fighter != null and _fighter.controls_enabled

func _on_enter(state: String) -> void:
	if _fighter == null:
		return
	match state:
		FighterStates.SHIELD_START, FighterStates.SHIELD_HOLD:
			_fighter.shielding = true
		FighterStates.SHIELD_BREAK:
			_fighter.shielding = false
			_fighter.shield_health = 0.0
		FighterStates.DODGE_ACTIVE:
			_fighter.invincible = true
		FighterStates.AURA_READY:
			_fighter.aura = 100.0
		FighterStates.GRAB_HOLD:
			if _fighter.grabbed_target:
				_fighter.grabbed_target.grabbed_by = _fighter
		FighterStates.KO:
			_fighter.velocity = Vector2.ZERO
		FighterStates.RESPAWN:
			_fighter.invincible = true

func _on_update(state: String, delta: float) -> void:
	if _fighter == null:
		return
	match state:
		FighterStates.SHIELD_HOLD:
			_fighter.shield_health = maxf(0.0, _fighter.shield_health - 8.0 * delta)
		FighterStates.AURA_CHARGE:
			if not _fighter.is_aura_input_held():
				_fighter.state_machine.enter(FighterStates.AURA_READY if _fighter.aura >= 100.0 else FighterStates.IDLE)
		FighterStates.SHIELD_STUN:
			if state_time > 0.25:
				_fighter.state_machine.enter(FighterStates.IDLE)
		FighterStates.DODGE_RECOVERY:
			if state_time > 0.12:
				_fighter.invincible = false
				_fighter.state_machine.enter(FighterStates.IDLE)
		FighterStates.HITSTUN:
			if state_time > _fighter.hitstun_remaining:
				_fighter.state_machine.enter(FighterStates.IDLE if _fighter.is_on_floor() else FighterStates.FALL)
		FighterStates.HURT_LIGHT:
			if state_time > 0.06:
				if _fighter.hitstun_remaining > 0.04:
					_fighter.state_machine.enter(FighterStates.HITSTUN)
				elif _fighter.is_on_floor():
					_fighter.state_machine.enter(FighterStates.IDLE)
				else:
					_fighter.state_machine.enter(FighterStates.FALL)
		FighterStates.HURT_HEAVY:
			if state_time > 0.12:
				if _fighter.hitstun_remaining > 0.08:
					_fighter.state_machine.enter(FighterStates.HITSTUN)
				elif _fighter.is_on_floor():
					_fighter.state_machine.enter(FighterStates.IDLE)
				else:
					_fighter.state_machine.enter(FighterStates.FALL)
		FighterStates.LAUNCHED:
			if _fighter.is_on_floor() and _fighter.velocity.y >= 0:
				_fighter.state_machine.enter(FighterStates.TUMBLE if _fighter.velocity.length() > 120 else FighterStates.LAND)
		FighterStates.TUMBLE:
			if state_time > 0.35:
				_fighter.state_machine.enter(FighterStates.FALL)
		FighterStates.LAND:
			if state_time > 0.08:
				_fighter.state_machine.enter(FighterStates.IDLE)
		FighterStates.GRAB_WHIFF:
			if state_time > 0.3:
				_fighter.state_machine.enter(FighterStates.IDLE)
		FighterStates.GRAB_HOLD:
			if state_time > 2.0:
				_fighter.execute_throw()
		FighterStates.ATTACK_RECOVERY, FighterStates.SPECIAL_RECOVERY, FighterStates.AURA_BURST_RECOVERY:
			if state_time > 0.12:
				_fighter.state_machine.enter(FighterStates.IDLE)
		FighterStates.SHIELD_BREAK:
			if state_time > 0.4:
				_fighter.shield_health = float(_fighter.data.get("shieldProfile", {}).get("maxHealth", 100))
				_fighter.state_machine.enter(FighterStates.IDLE)
