extends CharacterBody2D
class_name AAFighter

signal damaged(amount: float, total: float)
signal koed()
signal respawned()
signal hit_landed(info: Dictionary)

const GRAVITY := 1800.0
const FAST_FALL_MULT := 1.45

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
var spawn_point: Vector2 = Vector2.ZERO
var combo_count: int = 0

var state_machine: FighterStateMachine
var move_runner: MoveRunner
var hit_resolver: HitResolver

@onready var body: ColorRect = $Body
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var label: Label = $NameLabel
@onready var hitbox_debug: ColorRect = $HitboxDebug

var _cpu_timer: float = 0.0
var _hitstop: float = 0.0
var _current_move: Dictionary = {}

func _ready() -> void:
	add_to_group("fighters")
	state_machine = FighterStateMachine.new()
	add_child(state_machine)
	move_runner = MoveRunner.new()
	add_child(move_runner)
	move_runner.active_frames_tick.connect(_on_move_active)
	move_runner.move_ended.connect(_on_move_ended)
	hit_resolver = HitResolver.new()
	add_child(hit_resolver)
	facing = 1 if slot == 1 else -1
	_setup_shapes()
	if hitbox_debug:
		hitbox_debug.visible = false
		hitbox_debug.add_to_group("hitbox_debug")

func configure(id: String, player_slot: int, cpu: bool, stock_count: int, spawn: Vector2) -> void:
	fighter_id = id
	slot = player_slot
	is_cpu = cpu
	stocks = stock_count
	spawn_point = spawn
	data = DataLoader.load_fighter(id)
	move_manifest = DataLoader.load_moves(id)
	shield_health = float(data.get("shieldProfile", {}).get("maxHealth", 100))
	if body and data.has("color"):
		body.color = Color(data.get("color"))
	if label:
		var tag := ""
		if data.get("productionStatus", "") in ["placeholder", "proxy"]:
			tag = " *"
		label.text = data.get("displayName", id) + tag

func get_weight() -> float:
	return float(data.get("weight", 100))

func get_damage_dealt_mult() -> float:
	return float(data.get("damageDealtMult", 1.0))

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

func _physics_process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta
		return
	state_machine.update(delta)
	move_runner.tick()
	if state_machine.current_state in [FighterStates.HITSTUN, FighterStates.LAUNCHED, FighterStates.TUMBLE]:
		velocity.y += get_fall_speed() * delta
		move_and_slide()
		return
	if is_cpu or dummy_mode != "idle":
		_cpu_tick(delta)
	_apply_movement(delta)
	_handle_actions()
	move_and_slide()
	_sync_motion_state()

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
		if is_on_floor():
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
	if not state_machine.can_attack():
		return
	if _read_shield() and is_on_floor():
		state_machine.enter(FighterStates.SHIELD_HOLD)
		shield_health = minf(float(data.get("shieldProfile", {}).get("maxHealth", 100)), shield_health + 20.0 * get_physics_process_delta_time())
		return
	if state_machine.current_state == FighterStates.SHIELD_HOLD:
		state_machine.enter(FighterStates.IDLE)
	if _read_dodge_pressed():
		_start_dodge()
	if _read_grab_pressed():
		_start_move("grab")
	if _read_attack_pressed():
		var cmd := "attack_air_neutral" if not is_on_floor() else ("attack_heavy" if _read_axis() > 0.5 else "attack_neutral")
		_start_move_by_command(cmd)
	if _read_special_pressed():
		_start_move_by_command("special_neutral")
	if _read_aura_charge():
		state_machine.enter(FighterStates.AURA_CHARGE)
		aura = minf(100.0, aura + 35.0 * get_physics_process_delta_time())
	if _read_aura_burst() and aura >= 100.0:
		_start_move_by_command("aura_burst")

func _start_move_by_command(cmd: String) -> void:
	var m := DataLoader.find_move_by_input(move_manifest, cmd, not is_on_floor())
	if m.is_empty():
		return
	_start_move_dict(m)

func _start_move(move_id: String) -> void:
	var m := DataLoader.find_move(move_manifest, move_id)
	if not m.is_empty():
		_start_move_dict(m)

func _start_move_dict(m: Dictionary) -> void:
	_current_move = m
	move_runner.start_move(m, self)
	var is_special := str(m.get("input_command", "")).begins_with("special") or m.get("move_id") == "aura_burst"
	state_machine.enter(FighterStates.SPECIAL_STARTUP if is_special else FighterStates.ATTACK_STARTUP)

func _start_dodge() -> void:
	invincible = true
	state_machine.enter(FighterStates.DODGE)
	velocity.x = facing * get_dash_speed()
	get_tree().create_timer(0.16).timeout.connect(func(): invincible = false, CONNECT_ONE_SHOT)

func _on_move_active(move: Dictionary) -> void:
	state_machine.enter(FighterStates.ATTACK_ACTIVE if not str(move.get("input_command","")).begins_with("special") else FighterStates.SPECIAL_ACTIVE)
	hitbox.monitoring = true
	_update_hitbox_from_move(move)

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
	if invincible:
		return
	if state_machine.current_state == FighterStates.SHIELD_HOLD:
		shield_health -= info.get("shield_damage", 3.0)
		state_machine.enter(FighterStates.SHIELD_STUN if shield_health <= 0 else FighterStates.SHIELD_HOLD)
		return
	var dmg: float = info.get("damage", 0.0)
	damage_percent += dmg
	damaged.emit(dmg, damage_percent)
	var launch: Vector2 = info.get("launch", Vector2.ZERO)
	velocity = launch
	_hitstop = CombatMath.frames_to_seconds(info.get("hitstop_frames", 3))
	var kb_mag := launch.length()
	state_machine.enter(FighterStates.LAUNCHED if kb_mag > 14 else FighterStates.HITSTUN)
	hit_landed.emit(info)
	if attacker is AAFighter:
		attacker.combo_count += 1

func reset_fighter() -> void:
	damage_percent = 0.0
	aura = 0.0
	combo_count = 0
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

func reset_position() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO

func set_debug_visible(v: bool) -> void:
	if hitbox_debug:
		hitbox_debug.visible = v

func _on_move_ended(_move_id: String) -> void:
	hitbox.monitoring = false
	if state_machine.current_state in [FighterStates.ATTACK_ACTIVE, FighterStates.ATTACK_STARTUP]:
		state_machine.enter(FighterStates.ATTACK_RECOVERY)
	elif state_machine.current_state in [FighterStates.SPECIAL_ACTIVE, FighterStates.SPECIAL_STARTUP]:
		state_machine.enter(FighterStates.SPECIAL_RECOVERY)
	else:
		state_machine.enter(FighterStates.IDLE)

func _sync_motion_state() -> void:
	if not is_on_floor() and state_machine.current_state not in [FighterStates.JUMP, FighterStates.DOUBLE_JUMP, FighterStates.ATTACK_STARTUP, FighterStates.SPECIAL_STARTUP]:
		if velocity.y > 0:
			state_machine.enter(FighterStates.FALL)

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

func _read_aura_charge() -> bool:
	return Input.is_action_pressed("p%d_special" % slot) and Input.is_action_pressed("p%d_shield" % slot)

func _read_aura_burst() -> bool:
	return Input.is_action_just_pressed("p%d_attack" % slot) and aura >= 100.0

func _cpu_tick(delta: float) -> void:
	if not is_cpu and dummy_mode == "idle":
		return
	_cpu_timer -= delta
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
			if absf(dx) < 90 and _cpu_timer <= 0:
				_start_move_by_command("attack_neutral")
				_cpu_timer = 0.5
		"cpu", _:
			if _cpu_timer <= 0:
				_cpu_timer = 0.35 + randf() * 0.5
				if absf(dx) < 80 and randf() < 0.4:
					_start_move_by_command("attack_neutral" if randf() < 0.6 else "special_neutral")
				elif is_on_floor() and randf() < 0.15:
					velocity.y = -get_jump_strength()

func _find_opponent() -> Node2D:
	var parent := get_parent()
	if parent == null:
		return null
	for c in parent.get_children():
		if c != self and c is AAFighter:
			return c
	return null
