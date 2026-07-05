extends Area2D
class_name AAProjectile

## Area2D projectile with aura-scaled behavior and HitResolver routing.

signal projectile_hit(target: Node, info: Dictionary)
signal projectile_expired()

const SIM_FPS := 60.0

var owner_fighter: Node = null
var fighter_id: String = ""
var move_id: String = ""
var aura_level_at_spawn: int = 0
var team_slot: int = 1
var lifetime_frames: int = 120
var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var behavior: String = "straight"
var move_data: Dictionary = {}
var hit_targets: Dictionary = {}
var frame_count: int = 0
var active: bool = true
var damage: float = 8.0
var debug_visible: bool = false

@onready var debug_rect: ColorRect = $DebugRect
@onready var collision: CollisionShape2D = $CollisionShape2D

func configure(cfg: Dictionary, owner_node: Node) -> void:
	owner_fighter = owner_node
	fighter_id = cfg.get("fighter_id", "")
	move_id = cfg.get("move_id", "")
	aura_level_at_spawn = cfg.get("aura_level", 0)
	team_slot = cfg.get("team_slot", 1)
	lifetime_frames = cfg.get("lifetime_frames", 120)
	speed = cfg.get("speed", 400.0)
	behavior = cfg.get("behavior", "straight")
	move_data = cfg.get("move_data", {})
	damage = float(cfg.get("damage", move_data.get("damage", 8.0)))
	var angle_deg: float = cfg.get("angle_deg", 0.0)
	var facing: int = owner_node.facing if owner_node and "facing" in owner_node else 1
	direction = Vector2(cos(deg_to_rad(angle_deg)), sin(deg_to_rad(angle_deg)))
	if direction.x < 0:
		direction.x *= facing
	else:
		direction = direction.normalized() * Vector2(facing, 1.0).normalized()
		if direction.length() < 0.1:
			direction = Vector2(facing, 0)
	var size: Vector2 = cfg.get("size", Vector2(16, 16))
	if collision and collision.shape == null:
		var rect := RectangleShape2D.new()
		rect.size = size
		collision.shape = rect
	if debug_rect:
		debug_rect.size = size
		debug_rect.position = -size / 2.0
		debug_rect.color = cfg.get("color", Color(0.9, 0.5, 0.2, 0.7))
		debug_rect.visible = debug_visible
	monitoring = true

func tick_sim_frame() -> void:
	if not active:
		return
	frame_count += 1
	match behavior:
		"straight", "beam":
			position += direction * speed / SIM_FPS
		"lob":
			position += direction * speed / SIM_FPS
			direction.y += 800.0 / SIM_FPS
		"boomerang":
			position += direction * speed / SIM_FPS
			if frame_count > lifetime_frames / 2:
				direction = -direction
		"delayed_orb", "trap":
			if frame_count < int(lifetime_frames * 0.3):
				pass
			else:
				position += direction * speed / SIM_FPS * 0.5
		"pull_orb":
			position += direction * speed / SIM_FPS * 0.3
		"shockwave":
			if frame_count <= 4:
				position += direction * speed / SIM_FPS * 0.2
		"curving_blade":
			position += direction * speed / SIM_FPS
			direction = direction.rotated(0.04 * (1 if aura_level_at_spawn >= 2 else -1))
	if frame_count >= lifetime_frames:
		_expire()

func _expire() -> void:
	active = false
	monitoring = false
	projectile_expired.emit()
	queue_free()

func set_debug_visible(v: bool) -> void:
	debug_visible = v
	if debug_rect:
		debug_rect.visible = v

func _on_area_entered(area: Area2D) -> void:
	if not active or owner_fighter == null:
		return
	var target := area.get_parent()
	if target == owner_fighter:
		return
	if not target.has_method("receive_hit"):
		return
	var id := str(target.get_instance_id())
	if hit_targets.has(id):
		return
	hit_targets[id] = true
	var hit_move := move_data.duplicate(true)
	hit_move["damage"] = damage
	if owner_fighter.has_method("hit_resolver"):
		owner_fighter.hit_resolver.resolve(owner_fighter, target, hit_move, owner_fighter.damage_percent if "damage_percent" in owner_fighter else 0.0)
	projectile_hit.emit(target, hit_move)
	if behavior != "beam":
		_expire()
