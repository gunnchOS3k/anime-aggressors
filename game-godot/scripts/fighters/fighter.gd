extends CharacterBody2D
class_name AAFighter

signal damaged(amount: float, total: float)
signal koed()
signal respawned()
signal hit_landed(info: Dictionary)
signal grab_event(info: Dictionary)
signal state_changed(state: String)

const GRAVITY := 1800.0
const FAST_FALL_MULT := 1.45
const EDGE_MARGIN := 28.0

@export var slot: int = 1
@export var fighter_id: String = "ember-vale"
@export var is_cpu: bool = false
@export var facing: int = 1
@export var dummy_mode: String = "cpu"

var data: Dictionary = {}
var move_manifest: Dictionary = {}
var damage_percent: float = 0.0
var stocks: int = 3
var aura: float = 0.0
var shield_health: float = 100.0
var air_jumps_left: int = 1
var invincible: bool = false
var shielding: bool = false
var controls_enabled: bool = true
var spawn_point: Vector2 = Vector2.ZERO
var combo_count: int = 0
var hitstun_remaining: float = 0.0
var grabbed_target: AAFighter = null
var grabbed_by: AAFighter = null
var platform_half_width: float = 400.0
var platform_center_x: float = 0.0

var state_machine: FighterStateMachine
var move_runner: MoveRunner
var hit_resolver: HitResolver
var projectile_spawner: ProjectileSpawner
var combat_feedback: CombatFeedback
var cpu: CpuController
var animator: FighterAnimator

@onready var body: ColorRect = $Body
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var label: Label = $NameLabel
@onready var hitbox_debug: ColorRect = $HitboxDebug
@onready var hurtbox_debug: ColorRect = $HurtboxDebug
@onready var aura_vfx: ColorRect = $AuraVfx
@onready var grab_range_debug: ColorRect = $GrabRangeDebug

var _hitstop: float = 0.0
var _current_move: Dictionary = {}
var _pending_attack_cmd: String = ""
var _last_state: String = ""
var _aura_sfx_hook: bool = false
var _last_hit_result: Dictionary = {}
var _last_knockback: Vector2 = Vector2.ZERO
var _last_shield_damage: float = 0.0
var _last_element_effect: String = ""
var _throw_direction: String = ""
var _jab_chain: int = 0
var _show_grab_range: bool = false
var _show_projectile_boxes: bool = false

func _ready() -> void:
	add_to_group("fighters")
	state_machine = FighterStateMachine.new()
	add_child(state_machine)
	state_machine.setup(self)
	state_machine.state_changed.connect(_on_state_changed)
	move_runner = MoveRunner.new()
	add_child(move_runner)
	move_runner.active_frames_tick.connect(_on_move_active)
	move_runner.move_ended.connect(_on_move_ended)
	move_runner.phase_changed.connect(_on_phase_changed)
	hit_resolver = HitResolver.new()
	add_child(hit_resolver)
	projectile_spawner = ProjectileSpawner.new()
	add_child(projectile_spawner)
	projectile_spawner.setup(self)
	combat_feedback = CombatFeedback.new()
	add_child(combat_feedback)
	hit_resolver.combat_feedback = combat_feedback
	cpu = CpuController.new()
	animator = FighterAnimator.new()
	add_child(animator)
	if body:
		animator.setup(self, body)
	facing = 1 if slot == 1 else -1
	_setup_shapes()
	if hitbox_debug:
		hitbox_debug.visible = false
		hitbox_debug.add_to_group("hitbox_debug")
	if hurtbox_debug:
		hurtbox_debug.visible = false
		hurtbox_debug.add_to_group("hurtbox_debug")
	if aura_vfx:
		aura_vfx.visible = false
	if grab_range_debug:
		grab_range_debug.visible = false
		grab_range_debug.size = Vector2(70, 36)
		grab_range_debug.color = Color(0.2, 0.8, 1.0, 0.25)

func get_aura() -> float:
	return aura

func get_aura_level() -> int:
	return AuraScaler.aura_level(aura)

func configure(id: String, player_slot: int, cpu_flag: bool, stock_count: int, spawn: Vector2) -> void:
	fighter_id = id
	slot = player_slot
	is_cpu = cpu_flag
	stocks = stock_count
	spawn_point = spawn
	data = DataLoader.load_fighter(id)
	move_manifest = DataLoader.load_moves(id)
	shield_health = float(data.get("shieldProfile", {}).get("maxHealth", 100))
	cpu.setup(self, GameState.cpu_level if is_cpu else 2)
	if body and data.has("color"):
		body.color = Color(data.get("color"))
	if label:
		label.text = data.get("displayName", id)
	if aura_vfx and data.has("auraColor"):
		aura_vfx.color = Color(data.get("auraColor"))
		aura_vfx.color.a = 0.35

func get_weight() -> float:
	return float(data.get("weight", 100))

func get_damage_dealt_mult() -> float:
	return float(data.get("damageDealt_mult", data.get("damageDealtMult", 1.0)))

func get_run_speed() -> float:
	return float(data.get("runSpeed", 280))

func get_dash_speed() -> float:
	return float(data.get("dashSpeed", 420))

func get_air_speed() -> float:
	return float(data.get("airSpeed", 220))

func get_jump_strength() -> float:
	return float(data.get("jumpStrength", 620))

func get_fall_speed() -> float:
	return float(data.get("fallSpeed", 1800))

func tick_combat_frame() -> void:
	if _hitstop > 0.0:
		return
	move_runner.tick_sim_frame()
	projectile_spawner.tick_all()
	_sync_attack_phase_state()

func _physics_process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta
		return
	state_machine.update(delta)
	if grabbed_by != null:
		global_position = grabbed_by.global_position + Vector2(24 * grabbed_by.facing, -8)
		velocity = Vector2.ZERO
		return
	if state_machine.current_state in [FighterStates.HITSTUN, FighterStates.LAUNCHED, FighterStates.TUMBLE, FighterStates.HURT_LIGHT, FighterStates.HURT_HEAVY]:
		velocity.y += get_fall_speed() * delta
		move_and_slide()
		_check_edge()
		return
	if is_cpu or dummy_mode == "cpu":
		cpu.tick(delta, _find_opponent())
	elif dummy_mode != "idle":
		_dummy_tick(delta)
	if controls_enabled:
		_apply_movement(delta)
		_handle_actions()
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 8.0)
	move_and_slide()
	_sync_motion_state()
	_check_edge()
	if animator:
		animator.play_for_state(state_machine.current_state)

func _apply_movement(delta: float) -> void:
	if not state_machine.can_move():
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 8.0)
		return
	var axis := _read_axis()
	if not is_on_floor():
		var ff := FAST_FALL_MULT if velocity.y > 80 and not _read_jump_held() else 1.0
		velocity.y += get_fall_speed() * ff * delta
	else:
		air_jumps_left = int(data.get("maxJumps", 2)) - 1
		if velocity.y > 0:
			velocity.y = 0.0
	if absf(axis) > 0.1:
		facing = 1 if axis > 0 else -1
		var spd := get_run_speed()
		if absf(axis) > 0.75 and is_on_floor():
			spd = get_dash_speed()
			state_machine.enter(FighterStates.DASH)
		else:
			state_machine.enter(FighterStates.RUN if absf(velocity.x) > spd * 0.5 else FighterStates.WALK)
		velocity.x = axis * spd
		if body:
			body.scale.x = absf(body.scale.x) * facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, get_run_speed() * delta * 8.0)
		if is_on_floor() and not FighterStates.is_attack_state(state_machine.current_state):
			if absf(velocity.x) < 10.0:
				state_machine.enter(FighterStates.IDLE)
	if _read_jump_pressed():
		if is_on_floor():
			velocity.y = -get_jump_strength()
			state_machine.enter(FighterStates.JUMP)
		elif air_jumps_left > 0:
			velocity.y = -get_jump_strength() * 0.9
			air_jumps_left -= 1
			state_machine.enter(FighterStates.DOUBLE_JUMP)

func _handle_actions() -> void:
	if _pending_attack_cmd != "":
		_start_move_by_command(_pending_attack_cmd)
		_pending_attack_cmd = ""
	if not state_machine.can_attack():
		return
	if state_machine.current_state == FighterStates.GRAB_HOLD:
		_throw_direction = ThrowResolver.read_throw_direction(self)
		if grab_range_debug:
			grab_range_debug.visible = _show_grab_range
		if _read_attack_pressed() or _read_grab_pressed():
			execute_throw()
		return
	if is_aura_input_held():
		if aura < 100.0:
			state_machine.enter(FighterStates.AURA_CHARGE)
			aura = minf(100.0, aura + 35.0 * get_physics_process_delta_time())
			_set_aura_vfx(true)
		else:
			state_machine.enter(FighterStates.AURA_READY)
			_set_aura_vfx(true)
	elif state_machine.current_state in [FighterStates.AURA_CHARGE, FighterStates.AURA_READY]:
		state_machine.enter(FighterStates.IDLE)
		_set_aura_vfx(false)
	if _read_aura_burst() and aura >= 100.0:
		_start_move_by_command("aura_burst")
		return
	if _read_shield() and is_on_floor() and not is_aura_input_held():
		if state_machine.current_state != FighterStates.SHIELD_HOLD:
			state_machine.enter(FighterStates.SHIELD_START)
		state_machine.enter(FighterStates.SHIELD_HOLD)
		shielding = true
		shield_health = minf(float(data.get("shieldProfile", {}).get("maxHealth", 100)), shield_health + 20.0 * get_physics_process_delta_time())
		return
	if state_machine.current_state in [FighterStates.SHIELD_HOLD, FighterStates.SHIELD_START]:
		shielding = false
		state_machine.enter(FighterStates.IDLE)
	if _read_dodge_pressed():
		_start_dodge()
	if _read_grab_pressed():
		_start_move("grab")
	if _read_attack_pressed():
		if aura >= 100.0:
			_start_move_by_command("aura_burst")
			return
		var cmd := _resolve_attack_command()
		_start_move_by_command(cmd)
	if _read_special_pressed() and not is_aura_input_held():
		_start_move_by_command(_resolve_special_command())

func _start_move(move_id: String) -> void:
	var m := DataLoader.find_move(move_manifest, move_id)
	if not m.is_empty():
		_start_move_dict(m)

func _resolve_attack_command() -> String:
	if not is_on_floor():
		var axis := _read_axis()
		var up := _read_up()
		var down := _read_down()
		if up: return "attack_air_up"
		if down: return "attack_air_down"
		if absf(axis) > 0.3: return "attack_air_forward"
		return "attack_air_neutral"
	var axis := _read_axis()
	var up := _read_up()
	var down := _read_down()
	if absf(axis) > 0.75 and is_on_floor():
		return "attack_dash"
	if up: return "attack_up"
	if down: return "attack_down"
	if absf(axis) > 0.3: return "attack_forward"
	if absf(axis) > 0.5: return "attack_heavy"
	if _jab_chain == 0: return "attack_neutral"
	if _jab_chain == 1: return "attack_neutral"
	return "attack_neutral"

func _resolve_special_command() -> String:
	var up := _read_up()
	var down := _read_down()
	var axis := _read_axis()
	if up: return "special_up"
	if down: return "special_down"
	if absf(axis) > 0.3: return "special_forward"
	return "special_neutral"

func is_aura_input_held() -> bool:
	return Input.is_action_pressed("p%d_special" % slot) and Input.is_action_pressed("p%d_shield" % slot)

func queue_attack_command(cmd: String) -> void:
	_pending_attack_cmd = cmd

func _start_move_by_command(cmd: String) -> void:
	var m: Dictionary = {}
	if cmd == "attack_neutral" and is_on_floor():
		match _jab_chain:
			0: m = DataLoader.find_move(move_manifest, "jab_1")
			1: m = DataLoader.find_move(move_manifest, "jab_2")
			_: m = DataLoader.find_move(move_manifest, "jab_finisher")
		if not m.is_empty():
			if _jab_chain < 2:
				_jab_chain += 1
			else:
				_jab_chain = 0
	else:
		m = DataLoader.find_move_by_input(move_manifest, cmd, not is_on_floor())
	if m.is_empty():
		return
	_start_move_dict(m)

func _start_move_dict(m: Dictionary) -> void:
	_current_move = AuraScaler.apply_to_move(m, aura)
	move_runner.start_move(_current_move, self)
	var mid := str(m.get("move_id", ""))
	var mt := str(m.get("move_type", "melee"))
	if mid == "grab" or mt == "grab":
		state_machine.enter(FighterStates.GRAB_STARTUP)
	elif mt == "throw" or mid.begins_with("throw_"):
		state_machine.enter(FighterStates.THROW_STARTUP)
	elif mid == "aura_burst" or mt == "burst":
		aura = 0.0
		_set_aura_vfx(false)
		state_machine.enter(FighterStates.AURA_BURST_STARTUP)
	elif mt == "projectile" or str(m.get("input_command", "")).begins_with("special"):
		state_machine.enter(FighterStates.SPECIAL_STARTUP)
	else:
		state_machine.enter(FighterStates.ATTACK_STARTUP)

func _start_dodge() -> void:
	state_machine.enter(FighterStates.DODGE_START)
	state_machine.enter(FighterStates.DODGE_ACTIVE)
	invincible = true
	velocity.x = facing * get_dash_speed()
	state_machine.enter(FighterStates.DODGE_RECOVERY)

func _on_move_active(move: Dictionary) -> void:
	var mid := str(move.get("move_id", ""))
	var mt := str(move.get("move_type", "melee"))
	if mid == "grab" or mt == "grab":
		state_machine.enter(FighterStates.GRAB_ACTIVE)
		_try_grab_connect()
		return
	if mt == "throw" or mid.begins_with("throw_"):
		state_machine.enter(FighterStates.THROW_RELEASE)
	if mt == "projectile" or move.has("projectile"):
		projectile_spawner.spawn_from_move(_current_move, aura)
		state_machine.enter(FighterStates.SPECIAL_ACTIVE)
		return
	var sm := move.get("self_movement", {})
	if sm is Dictionary and (sm.get("x", 0) != 0 or sm.get("y", 0) != 0):
		velocity += Vector2(float(sm.get("x", 0)) * facing, float(sm.get("y", 0)))
	hitbox.monitoring = true
	_update_hitbox_from_move(move)
	if mt == "burst" or mid == "aura_burst":
		state_machine.enter(FighterStates.AURA_BURST_ACTIVE)
	elif str(move.get("input_command", "")).begins_with("special") or mt in ["field", "trap", "movement"]:
		state_machine.enter(FighterStates.SPECIAL_ACTIVE)
	else:
		state_machine.enter(FighterStates.ATTACK_ACTIVE)

func _try_grab_connect() -> void:
	var opp := _find_opponent()
	if opp == null or not opp is AAFighter:
		state_machine.enter(FighterStates.GRAB_WHIFF)
		grab_event.emit({"result": "whiff"})
		return
	if opp.invincible or opp.grabbed_by != null:
		state_machine.enter(FighterStates.GRAB_WHIFF)
		grab_event.emit({"result": "whiff", "reason": "invuln"})
		return
	var dist := absf(opp.global_position.x - global_position.x)
	if dist > 70.0:
		state_machine.enter(FighterStates.GRAB_WHIFF)
		grab_event.emit({"result": "whiff", "reason": "range"})
		return
	grabbed_target = opp
	opp.grabbed_by = self
	state_machine.enter(FighterStates.GRAB_HOLD)
	opp.state_machine.enter(FighterStates.GRAB_HOLD)
	grab_event.emit({"result": "success", "target": opp.fighter_id})

func execute_throw() -> void:
	if grabbed_target == null:
		return
	var target := grabbed_target
	grabbed_target = null
	target.grabbed_by = null
	var direction := ThrowResolver.read_throw_direction(self)
	_throw_direction = direction
	state_machine.enter(FighterStates.THROW_STARTUP)
	var throw_move := ThrowResolver.resolve_throw(self, target, move_manifest, direction)
	ThrowResolver.apply_victim_offset(self, target, throw_move)
	_start_move_dict(throw_move)
	target.state_machine.enter(FighterStates.HITSTUN)
	hit_resolver.resolve(self, target, throw_move, damage_percent)
	grab_event.emit({"result": "throw", "target": target.fighter_id, "direction": direction})

func _update_hitbox_from_move(move: Dictionary) -> void:
	var boxes: Array = move.get("hitboxes", [])
	if boxes.is_empty():
		return
	var hb: Dictionary = boxes[0]
	hitbox.position = Vector2(hb.get("offset_x", 36) * facing, hb.get("offset_y", -8))
	if hitbox_debug:
		hitbox_debug.size = Vector2(hb.get("width", 40), hb.get("height", 32))
		hitbox_debug.position = hitbox.position - hitbox_debug.size / 2.0

func receive_hit(attacker: Node, info: Dictionary) -> void:
	if invincible or grabbed_by != null:
		return
	if str(info.get("move_id", "")) == "grab":
		return
	_last_hit_result = info.duplicate(true)
	_last_knockback = info.get("launch", Vector2.ZERO)
	_last_shield_damage = float(info.get("shield_damage", 0.0))
	_last_element_effect = str(info.get("element", info.get("element_effect", "")))
	if state_machine.current_state == FighterStates.SHIELD_HOLD or shielding:
		var sdmg: float = info.get("shield_damage", info.get("damage", 0.0) * 0.8)
		shield_health -= sdmg
		info["blocked"] = true
		hit_landed.emit(info)
		if shield_health <= 0.0:
			shielding = false
			state_machine.enter(FighterStates.SHIELD_BREAK)
			shield_health = 0.0
		else:
			state_machine.enter(FighterStates.SHIELD_STUN)
		return
	var dmg: float = info.get("damage", 0.0)
	if state_machine.current_state == FighterStates.AURA_CHARGE:
		aura = maxf(0.0, aura - 20.0)
		_set_aura_vfx(false)
	damage_percent += dmg
	damaged.emit(dmg, damage_percent)
	var launch: Vector2 = info.get("launch", Vector2.ZERO)
	velocity = launch
	hitstun_remaining = CombatMath.hitstun_seconds(launch.length())
	_hitstop = CombatMath.frames_to_seconds(info.get("hitstop_frames", 3))
	if attacker is AAFighter:
		attacker._hitstop = _hitstop * 0.5
		attacker.combo_count += 1
	var heavy := dmg >= 8.0 or launch.length() > 14.0
	if launch.length() > 14.0:
		state_machine.enter(FighterStates.LAUNCHED)
	elif heavy:
		state_machine.enter(FighterStates.HURT_HEAVY)
	else:
		state_machine.enter(FighterStates.HURT_LIGHT)
	hit_landed.emit(info)

func reset_fighter() -> void:
	damage_percent = 0.0
	aura = 0.0
	combo_count = 0
	grabbed_target = null
	grabbed_by = null
	shield_health = float(data.get("shieldProfile", {}).get("maxHealth", 100))
	velocity = Vector2.ZERO
	global_position = spawn_point
	invincible = true
	state_machine.enter(FighterStates.RESPAWN)
	get_tree().create_timer(1.2).timeout.connect(func():
		invincible = false
		state_machine.enter(FighterStates.IDLE)
		respawned.emit()
	, CONNECT_ONE_SHOT)

func lose_stock() -> void:
	stocks -= 1
	state_machine.enter(FighterStates.KO)
	koed.emit()
	if stocks > 0:
		reset_fighter()

func reset_damage() -> void:
	damage_percent = 0.0
	combo_count = 0

func reset_position() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	grabbed_target = null
	grabbed_by = null

func fill_aura() -> void:
	aura = 100.0
	state_machine.enter(FighterStates.AURA_READY)

func clear_aura() -> void:
	aura = 0.0
	_set_aura_vfx(false)
	if state_machine.current_state in [FighterStates.AURA_CHARGE, FighterStates.AURA_READY]:
		state_machine.enter(FighterStates.IDLE)

func set_debug_hitboxes(v: bool) -> void:
	if hitbox_debug:
		hitbox_debug.visible = v

func set_debug_hurtboxes(v: bool) -> void:
	if hurtbox_debug:
		hurtbox_debug.visible = v

func set_debug_visible(v: bool) -> void:
	set_debug_hitboxes(v)
	set_debug_hurtboxes(v)

func set_debug_projectiles(v: bool) -> void:
	_show_projectile_boxes = v
	projectile_spawner.set_debug_visible(v)

func set_debug_grab_range(v: bool) -> void:
	_show_grab_range = v
	if grab_range_debug:
		grab_range_debug.visible = v and state_machine.current_state == FighterStates.GRAB_HOLD

func debug_combat_summary() -> Dictionary:
	return {
		"aura_level": get_aura_level(),
		"projectile_count": projectile_spawner.count(),
		"throw_direction": _throw_direction,
		"last_hit_result": _last_hit_result.get("move_id", "—"),
		"hitstop_frames": int(_hitstop / CombatMath.frames_to_seconds(1)) if _hitstop > 0 else 0,
		"knockback_vector": _last_knockback,
		"shield_damage": _last_shield_damage,
		"element_effect": _last_element_effect,
		"combo_count": combo_count,
		"cancel_window": move_runner.in_cancel_window if move_runner else false,
	}

func _on_move_ended(_move_id: String) -> void:
	hitbox.monitoring = false
	var s := state_machine.current_state
	if s in [FighterStates.GRAB_ACTIVE, FighterStates.GRAB_STARTUP] and grabbed_target == null:
		state_machine.enter(FighterStates.GRAB_WHIFF)
	elif s in [FighterStates.ATTACK_ACTIVE, FighterStates.ATTACK_STARTUP]:
		state_machine.enter(FighterStates.ATTACK_RECOVERY)
	elif s in [FighterStates.SPECIAL_ACTIVE, FighterStates.SPECIAL_STARTUP]:
		state_machine.enter(FighterStates.SPECIAL_RECOVERY)
	elif s in [FighterStates.AURA_BURST_ACTIVE, FighterStates.AURA_BURST_STARTUP]:
		state_machine.enter(FighterStates.AURA_BURST_RECOVERY)
	elif s in [FighterStates.THROW_RELEASE, FighterStates.THROW_STARTUP]:
		state_machine.enter(FighterStates.IDLE)
	else:
		state_machine.enter(FighterStates.IDLE)

func _on_phase_changed(phase: String) -> void:
	match phase:
		"startup":
			pass
		"active":
			pass
		"recovery":
			if state_machine.current_state == FighterStates.ATTACK_ACTIVE:
				state_machine.enter(FighterStates.ATTACK_RECOVERY)
			elif state_machine.current_state == FighterStates.SPECIAL_ACTIVE:
				state_machine.enter(FighterStates.SPECIAL_RECOVERY)

func _sync_attack_phase_state() -> void:
	if not move_runner.active:
		return
	match move_runner.phase:
		"startup":
			if state_machine.current_state in [FighterStates.ATTACK_STARTUP, FighterStates.SPECIAL_STARTUP, FighterStates.AURA_BURST_STARTUP, FighterStates.GRAB_STARTUP, FighterStates.THROW_STARTUP]:
				pass
		"active":
			pass
		"recovery":
			if state_machine.current_state in [FighterStates.ATTACK_ACTIVE, FighterStates.SPECIAL_ACTIVE, FighterStates.AURA_BURST_ACTIVE]:
				pass

func _sync_motion_state() -> void:
	if not is_on_floor() and state_machine.current_state not in [
		FighterStates.JUMP, FighterStates.DOUBLE_JUMP, FighterStates.ATTACK_STARTUP,
		FighterStates.SPECIAL_STARTUP, FighterStates.AURA_BURST_STARTUP, FighterStates.LAUNCHED,
	]:
		if velocity.y > 0:
			state_machine.enter(FighterStates.FALL if velocity.y < get_fall_speed() * 0.02 else FighterStates.FAST_FALL)

func _check_edge() -> void:
	if not is_on_floor():
		return
	var edge_dist := platform_half_width - absf(global_position.x - platform_center_x)
	if edge_dist < EDGE_MARGIN and absf(velocity.x) > 20.0:
		if signf(velocity.x) == signf(global_position.x - platform_center_x):
			state_machine.enter(FighterStates.EDGE_WARNING)
	elif state_machine.current_state in [FighterStates.EDGE_WARNING, FighterStates.LEDGE_TEETER]:
		state_machine.enter(FighterStates.IDLE if absf(_read_axis()) < 0.1 else FighterStates.WALK)

func _set_aura_vfx(on: bool) -> void:
	if aura_vfx:
		aura_vfx.visible = on
	if on and not _aura_sfx_hook:
		_aura_sfx_hook = true

func _on_state_changed(_from: String, to: String) -> void:
	state_changed.emit(to)

func _setup_shapes() -> void:
	for path in ["CollisionShape2D", "Hurtbox/HurtShape", "Hitbox/HitShape"]:
		var cs := get_node_or_null(path) as CollisionShape2D
		if cs and cs.shape == null:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(40, 48) if "Hit" not in path else Vector2(36, 40)
			cs.shape = rect

func _read_axis() -> float:
	return Input.get_action_strength("p%d_right" % slot) - Input.get_action_strength("p%d_left" % slot)

func _read_jump_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_jump" % slot)

func _read_jump_held() -> bool:
	return Input.is_action_pressed("p%d_jump" % slot)

func _read_attack_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_attack" % slot)

func _read_special_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_special" % slot)

func _read_shield() -> bool:
	return Input.is_action_pressed("p%d_shield" % slot)

func _read_dodge_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_dodge" % slot)

func _read_grab_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_grab" % slot)

func _read_up() -> bool:
	return Input.is_action_pressed("p%d_up" % slot)

func _read_down() -> bool:
	return Input.is_action_pressed("p%d_down" % slot)

func _read_aura_burst() -> bool:
	return Input.is_action_just_pressed("p%d_attack" % slot) and aura >= 100.0

func _release_action(action: String) -> void:
	Input.action_release(action)

func _dummy_tick(delta: float) -> void:
	var target := _find_opponent()
	if target == null:
		return
	var dx := target.global_position.x - global_position.x
	match dummy_mode:
		"shield":
			if not Input.is_action_pressed("p%d_shield" % slot):
				Input.action_press("p%d_shield" % slot)
		"jump":
			if is_on_floor() and randf() < 0.02:
				velocity.y = -get_jump_strength()
		"attack":
			if absf(dx) < 90 and randf() < 0.03:
				_start_move_by_command("attack_neutral")
		"idle":
			pass

func _find_opponent() -> Node2D:
	var parent := get_parent()
	if parent == null:
		return null
	for c in parent.get_children():
		if c != self and c is AAFighter:
			return c
	return null

func input_display() -> String:
	var parts: PackedStringArray = []
	if absf(_read_axis()) > 0.1:
		parts.append("←→" if _read_axis() < 0 else "→")
	if _read_jump_held():
		parts.append("J")
	if _read_attack_pressed():
		parts.append("A")
	if _read_shield():
		parts.append("S")
	if _read_grab_pressed():
		parts.append("G")
	return " ".join(parts) if parts.size() else "—"
