extends CharacterBody2D
class_name FighterController

signal attack_requested(move_kind: String)
signal special_requested

const RUN_SPEED := 420.0
const DASH_SPEED := 680.0
const AIR_DRIFT := 320.0
const JUMP_VELOCITY := -760.0
const DOUBLE_JUMP_VELOCITY := -700.0
const GRAVITY := 2100.0
const FAST_FALL_GRAVITY := 3300.0
const COYOTE_TIME := 0.09
const JUMP_BUFFER := 0.10
const MAX_AIR_JUMPS := 1

@export var fighter_stats: FighterStats
@export var player_slot: FighterInput.PlayerSlot = FighterInput.PlayerSlot.P1
@export var facing: int = 1
@export var dash_duration: float = 0.12
@export var run_threshold: float = 0.60
@export var fast_fall_threshold: float = 0.55

var input_reader: FighterInput
var state_machine: FighterStateMachine
var aura_charge: AuraCharge

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var air_jumps_used: int = 0

var attack_timer: float = 0.0
var special_timer: float = 0.0
var damage_percent: float = 0.0

var hitbox: Hitbox
var hurtbox: Hurtbox
var animation_driver: FighterAnimationDriver

func _ready() -> void:
	if fighter_stats == null:
		fighter_stats = FighterStats.new("ember-vale")

	input_reader = get_node_or_null("FighterInput")
	if input_reader == null:
		input_reader = FighterInput.new()
		input_reader.player_slot = player_slot
		add_child(input_reader)

	state_machine = get_node_or_null("FighterStateMachine")
	if state_machine == null:
		state_machine = FighterStateMachine.new()
		add_child(state_machine)

	aura_charge = get_node_or_null("AuraCharge")
	if aura_charge == null:
		aura_charge = AuraCharge.new()
		add_child(aura_charge)

	hitbox = get_node_or_null("Hitbox") as Hitbox
	hurtbox = get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox != null:
		hurtbox.owner_fighter = self
		hurtbox.team_id = 1 if player_slot == FighterInput.PlayerSlot.P1 else 2
	if hitbox != null:
		hitbox.owner_fighter = self
		hitbox.team_id = hurtbox.team_id if hurtbox != null else 1
		hitbox.deactivate()

	animation_driver = get_node_or_null("FighterAnimationDriver") as FighterAnimationDriver

func receive_hit(hit_info: Dictionary) -> void:
	damage_percent += float(hit_info.get("damage", 0.0))
	var launch: Vector2 = hit_info.get("launch_velocity", Vector2.ZERO)
	velocity = launch
	var stun := float(hit_info.get("hitstun", 0.15))
	state_machine.transition_to(FighterStateMachine.State.HITSTUN)
	await get_tree().create_timer(stun).timeout
	if state_machine.current_state == FighterStateMachine.State.HITSTUN:
		state_machine.transition_to(FighterStateMachine.State.IDLE)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_handle_combat_states(delta)
	_handle_input(delta)
	_apply_gravity(delta)
	_move_and_slide()
	_update_landing_state()
	_update_motion_state()

func _update_timers(delta: float) -> void:
	coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	special_timer = maxf(0.0, special_timer - delta)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
		air_jumps_used = 0

	if input_reader.is_jump_just_pressed():
		jump_buffer_timer = JUMP_BUFFER

func _handle_input(delta: float) -> void:
	var move_axis := input_reader.get_move_axis()
	if absf(move_axis) > 0.05:
		facing = 1 if move_axis > 0.0 else -1

	if _can_accept_actions():
		if input_reader.is_attack_just_pressed():
			_begin_attack()
			return
		if input_reader.is_special_just_pressed():
			_begin_special()
			return

	if _can_move():
		_handle_horizontal_motion(move_axis, delta)
		_handle_jump_logic()
	else:
		velocity.x = move_toward(velocity.x, 0.0, RUN_SPEED * delta * 5.0)

	if input_reader.is_shield_pressed() and is_on_floor() and _can_accept_actions():
		state_machine.transition_to(FighterStateMachine.State.SHIELD)

	if input_reader.is_aura_pressed() and _can_accept_actions():
		state_machine.transition_to(FighterStateMachine.State.AURA_CHARGE)
		aura_charge.start_charging()
	else:
		aura_charge.stop_charging()

func _handle_horizontal_motion(move_axis: float, delta: float) -> void:
	var run_mod := fighter_stats.get_movement_modifier("run")
	var dash_mod := fighter_stats.get_movement_modifier("dash")
	var air_mod := fighter_stats.get_movement_modifier("air")
	var on_floor := is_on_floor()

	if on_floor:
		if absf(move_axis) > run_threshold and dash_timer <= 0.0 and signf(move_axis) == facing:
			dash_timer = dash_duration
			state_machine.transition_to(FighterStateMachine.State.DASH)

		if dash_timer > 0.0:
			velocity.x = facing * DASH_SPEED * dash_mod
		else:
			velocity.x = move_toward(velocity.x, move_axis * RUN_SPEED * run_mod, RUN_SPEED * delta * 8.0)
			if absf(move_axis) < 0.1:
				state_machine.transition_to(FighterStateMachine.State.IDLE)
			elif absf(velocity.x) > RUN_SPEED * 0.65:
				state_machine.transition_to(FighterStateMachine.State.RUN)
			else:
				state_machine.transition_to(FighterStateMachine.State.WALK)
	else:
		velocity.x = move_toward(velocity.x, move_axis * AIR_DRIFT * air_mod, AIR_DRIFT * delta * 3.0)

func _handle_jump_logic() -> void:
	if jump_buffer_timer <= 0.0:
		return

	var jump_mod := fighter_stats.get_movement_modifier("jump")
	if coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY * jump_mod
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		state_machine.transition_to(FighterStateMachine.State.JUMP)
		return

	if not is_on_floor() and air_jumps_used < MAX_AIR_JUMPS:
		velocity.y = DOUBLE_JUMP_VELOCITY * jump_mod
		air_jumps_used += 1
		jump_buffer_timer = 0.0
		state_machine.transition_to(FighterStateMachine.State.DOUBLE_JUMP)

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var gravity_scale := GRAVITY
	if velocity.y > fast_fall_threshold * 100.0 and input_reader.is_jump_pressed() == false:
		gravity_scale = FAST_FALL_GRAVITY
		state_machine.transition_to(FighterStateMachine.State.FAST_FALL)
	elif velocity.y > 0.0 and not state_machine.is_state(FighterStateMachine.State.FAST_FALL):
		state_machine.transition_to(FighterStateMachine.State.FALL)
	velocity.y += gravity_scale * delta

func _update_landing_state() -> void:
	if is_on_floor() and state_machine.current_state in [
		FighterStateMachine.State.FALL,
		FighterStateMachine.State.FAST_FALL,
		FighterStateMachine.State.JUMP,
		FighterStateMachine.State.DOUBLE_JUMP
	]:
		state_machine.transition_to(FighterStateMachine.State.LAND)

func _update_motion_state() -> void:
	if state_machine.current_state in [FighterStateMachine.State.ATTACK_STARTUP, FighterStateMachine.State.ATTACK_ACTIVE, FighterStateMachine.State.ATTACK_RECOVERY]:
		return
	if state_machine.current_state in [FighterStateMachine.State.SPECIAL_STARTUP, FighterStateMachine.State.SPECIAL_ACTIVE, FighterStateMachine.State.SPECIAL_RECOVERY]:
		return
	if state_machine.current_state == FighterStateMachine.State.AURA_CHARGE:
		return

	if not is_on_floor():
		if velocity.y < 0.0 and state_machine.current_state not in [FighterStateMachine.State.JUMP, FighterStateMachine.State.DOUBLE_JUMP]:
			state_machine.transition_to(FighterStateMachine.State.JUMP)
		return

	if absf(velocity.x) < 18.0:
		state_machine.transition_to(FighterStateMachine.State.IDLE)
	elif absf(velocity.x) >= RUN_SPEED * 0.70:
		state_machine.transition_to(FighterStateMachine.State.RUN)
	else:
		state_machine.transition_to(FighterStateMachine.State.WALK)

func _can_move() -> bool:
	return state_machine.current_state not in [
		FighterStateMachine.State.HITSTOP,
		FighterStateMachine.State.HITSTUN,
		FighterStateMachine.State.TUMBLE,
		FighterStateMachine.State.LAUNCHED,
		FighterStateMachine.State.KO,
		FighterStateMachine.State.VICTORY,
		FighterStateMachine.State.DEFEAT
	]

func _can_accept_actions() -> bool:
	return _can_move() and not state_machine.is_attacking() and not state_machine.is_specialing()

func _begin_attack() -> void:
	var move_data := MoveDefinition.get_move(MoveDefinition.MoveType.JAB)
	attack_timer = move_data["startup"] + move_data["active"] + move_data["recovery"]
	state_machine.transition_to(FighterStateMachine.State.ATTACK_STARTUP)
	attack_requested.emit("jab")

func _begin_special() -> void:
	var move_data := MoveDefinition.get_move(MoveDefinition.MoveType.SPECIAL)
	special_timer = move_data["startup"] + move_data["active"] + move_data["recovery"]
	state_machine.transition_to(FighterStateMachine.State.SPECIAL_STARTUP)
	special_requested.emit()
	aura_charge.consume_small_burst()

func _handle_combat_states(delta: float) -> void:
	if state_machine.current_state == FighterStateMachine.State.AURA_CHARGE:
		aura_charge.tick(delta)
		return

	if attack_timer > 0.0:
		var move_data := MoveDefinition.get_move(MoveDefinition.MoveType.JAB)
		var startup := float(move_data["startup"])
		var active := float(move_data["active"])
		var elapsed := (startup + active + float(move_data["recovery"])) - attack_timer
		if elapsed < startup:
			state_machine.transition_to(FighterStateMachine.State.ATTACK_STARTUP)
		elif elapsed < startup + active:
			state_machine.transition_to(FighterStateMachine.State.ATTACK_ACTIVE)
			if hitbox != null:
				hitbox.activate()
		else:
			state_machine.transition_to(FighterStateMachine.State.ATTACK_RECOVERY)
			if hitbox != null:
				hitbox.deactivate()
	elif state_machine.is_attacking():
		if hitbox != null:
			hitbox.deactivate()
		state_machine.transition_to(FighterStateMachine.State.IDLE)

	if special_timer > 0.0:
		var move_data := MoveDefinition.get_move(MoveDefinition.MoveType.SPECIAL)
		var startup := float(move_data["startup"])
		var active := float(move_data["active"])
		var elapsed := (startup + active + float(move_data["recovery"])) - special_timer
		if elapsed < startup:
			state_machine.transition_to(FighterStateMachine.State.SPECIAL_STARTUP)
		elif elapsed < startup + active:
			state_machine.transition_to(FighterStateMachine.State.SPECIAL_ACTIVE)
		else:
			state_machine.transition_to(FighterStateMachine.State.SPECIAL_RECOVERY)
	elif state_machine.is_specialing():
		state_machine.transition_to(FighterStateMachine.State.IDLE)
