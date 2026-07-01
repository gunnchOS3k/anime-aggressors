extends CharacterBody2D
class_name AAFighter

signal damaged(amount: float, total: float)
signal koed()
signal respawned()

const BASE_RUN := 280.0
const BASE_JUMP := -620.0
const BASE_AIR := 220.0
const GRAVITY := 1800.0
const FAST_FALL := 2600.0

@export var slot: int = 1
@export var fighter_id: String = "ember-vale"
@export var is_cpu: bool = false
@export var facing: int = 1

var data: Dictionary = {}
var damage_percent: float = 0.0
var stocks: int = 3
var air_jumps_left: int = 1
var invincible: bool = false
var shielding: bool = false
var dodging: bool = false
var attack_cooldown: float = 0.0
var hitstun: float = 0.0
var last_attack_damage: float = 8.0
var last_attack_kb: float = 1.0
var spawn_point: Vector2 = Vector2.ZERO

@onready var body: ColorRect = $Body
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var label: Label = $NameLabel

var _cpu_timer: float = 0.0

func configure(id: String, player_slot: int, cpu: bool, stock_count: int, spawn: Vector2) -> void:
	fighter_id = id
	slot = player_slot
	is_cpu = cpu
	stocks = stock_count
	spawn_point = spawn
	data = GameState.load_fighter(id)
	if body and data.has("color"):
		body.color = Color(data.color)
	if label:
		label.text = data.get("displayName", id)

func _ready() -> void:
	facing = 1 if slot == 1 else -1
	if body:
		body.scale.x = facing
	_setup_shapes()

func _setup_shapes() -> void:
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape and body_shape.shape == null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 48)
		body_shape.shape = rect
	var hurt_shape := get_node_or_null("Hurtbox/HurtShape") as CollisionShape2D
	if hurt_shape and hurt_shape.shape == null:
		var rect2 := RectangleShape2D.new()
		rect2.size = Vector2(40, 48)
		hurt_shape.shape = rect2
	var hit_shape := get_node_or_null("Hitbox/HitShape") as CollisionShape2D
	if hit_shape and hit_shape.shape == null:
		var rect3 := RectangleShape2D.new()
		rect3.size = Vector2(36, 40)
		hit_shape.shape = rect3

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hitstun = maxf(0.0, hitstun - delta)
	if hitstun > 0.0:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	var axis := 0.0
	if is_cpu:
		axis = _cpu_axis(delta)
	else:
		axis = _read_axis()

	if not is_on_floor():
		velocity.y += (FAST_FALL if velocity.y > 120.0 and _read_down() else GRAVITY) * delta
	else:
		air_jumps_left = 1
		velocity.y = 0.0

	var speed_mult := float(data.get("speed", 100)) / 100.0
	if absf(axis) > 0.1:
		facing = 1 if axis > 0 else -1
		velocity.x = axis * BASE_RUN * speed_mult
		if body:
			body.scale.x = absf(body.scale.x) * facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, BASE_RUN * delta * 6.0)

	if _read_jump_pressed() and is_on_floor():
		var jump_mult := float(data.get("jump", 100)) / 100.0
		velocity.y = BASE_JUMP * jump_mult
	elif _read_jump_pressed() and not is_on_floor() and air_jumps_left > 0:
		var jump_mult := float(data.get("jump", 100)) / 100.0
		velocity.y = BASE_JUMP * 0.9 * jump_mult
		air_jumps_left -= 1

	if _read_attack_pressed() and attack_cooldown <= 0.0:
		_begin_attack()
	if _read_special_pressed() and attack_cooldown <= 0.0:
		_begin_special()
	shielding = _read_shield() and is_on_floor()
	if _read_dodge_pressed() and attack_cooldown <= 0.0:
		_begin_dodge()
	if _read_grab_pressed():
		pass # placeholder grab

	move_and_slide()

func _read_axis() -> float:
	var left := "p%d_left" % slot
	var right := "p%d_right" % slot
	return Input.get_action_strength(right) - Input.get_action_strength(left)

func _read_down() -> bool:
	return Input.is_action_pressed("p%d_down" % slot)

func _read_jump_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_jump" % slot)

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

func _begin_attack() -> void:
	attack_cooldown = 0.35
	last_attack_damage = 8.0
	last_attack_kb = 1.0
	_activate_hitbox(0.12)

func _begin_special() -> void:
	attack_cooldown = 0.55
	last_attack_damage = 14.0
	last_attack_kb = 1.35
	_activate_hitbox(0.18)

func _begin_dodge() -> void:
	dodging = true
	invincible = true
	velocity.x = facing * 360.0
	await get_tree().create_timer(0.18).timeout
	dodging = false
	invincible = false

func _activate_hitbox(duration: float) -> void:
	if hitbox == null:
		return
	hitbox.monitoring = true
	hitbox.position = Vector2(42 * facing, -8)
	await get_tree().create_timer(duration).timeout
	hitbox.monitoring = false

func receive_hit(attacker: AAFighter, damage: float, kb_scale: float) -> void:
	if invincible or shielding:
		return
	damage_percent += damage
	damaged.emit(damage, damage_percent)
	var weight := float(data.get("weight", 100))
	var kb := (damage + damage_percent * 0.12) * kb_scale * (100.0 / weight)
	var dir := signf(global_position.x - attacker.global_position.x)
	if dir == 0:
		dir = attacker.facing
	velocity = Vector2(dir * kb * 8.0, -kb * 6.0)
	hitstun = 0.25

func reset_fighter() -> void:
	damage_percent = 0.0
	velocity = Vector2.ZERO
	global_position = spawn_point
	invincible = true
	get_tree().create_timer(1.5).timeout.connect(func():
		invincible = false
		respawned.emit()
	, CONNECT_ONE_SHOT)

func lose_stock() -> void:
	stocks -= 1
	koed.emit()
	if stocks > 0:
		reset_fighter()

func _cpu_axis(delta: float) -> void:
	_cpu_timer -= delta
	var target := get_parent().get_node_or_null("Fighter2")
	if target == null:
		return
	var dx := target.global_position.x - global_position.x
	if _cpu_timer <= 0.0:
		_cpu_timer = 0.4 + randf() * 0.6
		if absf(dx) < 70.0 and randf() < 0.35 + GameState.cpu_level * 0.1:
			if randf() < 0.5:
				_begin_attack()
			else:
				_begin_special()
		elif randf() < 0.2 and is_on_floor():
			velocity.y = BASE_JUMP * float(data.get("jump", 100)) / 100.0
	return clampf(dx / 120.0, -1.0, 1.0)
