extends Node
class_name FighterStateMachine
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _CombatMath = preload("res://scripts/combat/combat_math.gd")

signal state_changed(from_state: String, to_state: String)

var current_state: String = _FighterStates.IDLE
var previous_state: String = _FighterStates.IDLE
var state_frame: int = 0
var state_time: float = 0.0
var _fighter
var landing_lag: float = 0.08
var dodge_recovery: float = 0.12
var dodge_invuln: float = 0.10

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
	return not _FighterStates.locks_movement(current_state) and _fighter != null and _fighter.controls_enabled

func can_attack() -> bool:
	return not _FighterStates.locks_actions(current_state) and _fighter != null and _fighter.controls_enabled

func _on_enter(state: String) -> void:
	if _fighter == null:
		return
	match state:
		_FighterStates.SHIELD_START, _FighterStates.SHIELD_HOLD:
			_fighter.shielding = true
		_FighterStates.SHIELD_BREAK:
			_fighter.shielding = false
			_fighter.shield_health = 0.0
		_FighterStates.DODGE_ACTIVE, _FighterStates.AIR_DODGE:
			_fighter.invincible = true
		_FighterStates.AURA_READY:
			_fighter.aura = 100.0
		_FighterStates.GRAB_HOLD:
			if _fighter.grabbed_target:
				_fighter.grabbed_target.grabbed_by = _fighter
		_FighterStates.KO:
			_fighter.velocity = Vector2.ZERO
		_FighterStates.RESPAWN:
			_fighter.invincible = true
		_FighterStates.JUMP_SQUAT:
			_fighter.velocity.x *= 0.85
		_FighterStates.LEDGE_HANG:
			_fighter.velocity = Vector2.ZERO
			_fighter.invincible = true
		_FighterStates.LEDGE_GETUP:
			_fighter.invincible = true

func _on_update(state: String, delta: float) -> void:
	if _fighter == null:
		return
	match state:
		_FighterStates.JUMP_SQUAT:
			if state_frame >= _CombatMath.JUMP_SQUAT_FRAMES:
				_fighter.complete_jump_squat()
		_FighterStates.SHIELD_HOLD:
			_fighter.shield_health = maxf(0.0, _fighter.shield_health - 8.0 * delta)
		_FighterStates.AURA_CHARGE:
			if not _fighter.is_aura_input_held():
				_fighter.state_machine.enter(_FighterStates.AURA_READY if _fighter.aura >= 100.0 else _FighterStates.IDLE)
		_FighterStates.SHIELD_STUN:
			if state_time > 0.25:
				_fighter.state_machine.enter(_FighterStates.IDLE)
		_FighterStates.DODGE_RECOVERY, _FighterStates.AIR_DODGE:
			var rec := dodge_recovery
			if state == _FighterStates.AIR_DODGE:
				rec = _CombatMath.AIR_DODGE_RECOVERY
			if state_time > dodge_invuln:
				_fighter.invincible = false
			if state_time > rec:
				_fighter.invincible = false
				_fighter.state_machine.enter(_FighterStates.IDLE if _fighter.is_on_floor() else _FighterStates.FALL)
		_FighterStates.HITSTUN:
			_fighter.apply_hitstun_di(delta)
			if state_time > _fighter.hitstun_remaining:
				_fighter.state_machine.enter(_FighterStates.IDLE if _fighter.is_on_floor() else _FighterStates.FALL)
		_FighterStates.HURT_LIGHT:
			_fighter.apply_hitstun_di(delta)
			if state_time > 0.06:
				if _fighter.hitstun_remaining > 0.04:
					_fighter.state_machine.enter(_FighterStates.HITSTUN)
				elif _fighter.is_on_floor():
					_fighter.state_machine.enter(_FighterStates.IDLE)
				else:
					_fighter.state_machine.enter(_FighterStates.FALL)
		_FighterStates.HURT_HEAVY:
			_fighter.apply_hitstun_di(delta)
			if state_time > 0.12:
				if _fighter.hitstun_remaining > 0.08:
					_fighter.state_machine.enter(_FighterStates.HITSTUN)
				elif _fighter.is_on_floor():
					_fighter.state_machine.enter(_FighterStates.IDLE)
				else:
					_fighter.state_machine.enter(_FighterStates.FALL)
		_FighterStates.LAUNCHED:
			_fighter.apply_hitstun_di(delta)
			if _fighter.is_on_floor() and _fighter.velocity.y >= 0:
				_fighter.begin_landing(true, absf(_fighter.velocity.y) > 400.0)
		_FighterStates.TUMBLE:
			_fighter.apply_hitstun_di(delta)
			if state_time > 0.35:
				_fighter.state_machine.enter(_FighterStates.FALL)
		_FighterStates.LAND:
			if state_time > landing_lag:
				_fighter.state_machine.enter(_FighterStates.IDLE)
		_FighterStates.GRAB_WHIFF:
			if state_time > 0.3:
				_fighter.state_machine.enter(_FighterStates.IDLE)
		_FighterStates.GRAB_HOLD:
			if state_time > 2.0:
				_fighter.execute_throw()
		_FighterStates.ATTACK_RECOVERY, _FighterStates.SPECIAL_RECOVERY, _FighterStates.AURA_BURST_RECOVERY:
			if state_time > 0.12:
				_fighter.state_machine.enter(_FighterStates.IDLE)
		_FighterStates.SHIELD_BREAK:
			if state_time > 0.4:
				_fighter.shield_health = float(_fighter.data.get("shieldProfile", {}).get("maxHealth", 100))
				_fighter.state_machine.enter(_FighterStates.IDLE)
		_FighterStates.LEDGE_HANG:
			_fighter.tick_ledge_hang(delta)
		_FighterStates.LEDGE_GETUP:
			if state_time > 0.16:
				_fighter.invincible = false
				_fighter.state_machine.enter(_FighterStates.IDLE)
