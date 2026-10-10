extends Area2D
class_name AAProjectile

## Area2D projectile with aura-scaled behavior and HitResolver routing.
## Wave016: Ember (and lane-colored) projectiles use intentional silhouettes —
## DebugRect ColorRect is never the player-facing primary.

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
var projectile_tier: String = "projectile_tap"
var _visual: Node2D = null
var _renderer: Node2D
var _flight_slot := -1
var _emission_distance := 0.0
var _visual_extent := 40.0
var _elemental_audio: Node
var _environment_sounded := false

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
	projectile_tier = str(cfg.get("projectile_tier", move_data.get("projectile_tier", "projectile_tap")))
	damage = float(cfg.get("damage", move_data.get("damage", 8.0)))
	var angle_deg: float = cfg.get("angle_deg", 0.0)
	var facing: int = owner_node.facing if owner_node and "facing" in owner_node else 1
	if owner_node and "attack_direction" in owner_node and int(owner_node.attack_direction) != 0:
		facing = int(owner_node.attack_direction)
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
	elif collision and collision.shape is RectangleShape2D:
		(collision.shape as RectangleShape2D).size = size
	# Never present ColorRect as primary art (closes TASTE-001 / Wave016 Golden Slice).
	if debug_rect:
		debug_rect.visible = false
		debug_rect.modulate.a = 0.0
	_build_intentional_visual(cfg.get("color", Color(1.0, 0.45, 0.12, 0.95)), size)
	_elemental_audio = preload("res://scripts/audio/elemental_performance.gd").new()
	_elemental_audio.name = "ElementalProjectileAudio"
	_elemental_audio.fighter_id = fighter_id
	add_child(_elemental_audio)
	_elemental_audio.play("projectile_launch",.65 if projectile_tier == "projectile_tap" else 1.0)
	_elemental_audio.start_travel()
	monitoring = true
	collision_layer = 8
	collision_mask = 6
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func uses_intentional_visual() -> bool:
	return _visual != null and is_instance_valid(_visual) and _visual.visible and (debug_rect == null or not debug_rect.visible)


func _build_intentional_visual(_base_col: Color, size: Vector2) -> void:
	_visual = Node2D.new(); _visual.name="OriginalSpectralProjectile";add_child(_visual)
	_renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(self)
	_visual_extent=maxf(36.0,size.length()*1.5)*(1.5 if projectile_tier == "projectile_full" else 1.2 if projectile_tier == "projectile_medium" else 1.0)
	if _renderer != null:
		_flight_slot=_renderer.emit_effect(fighter_id,3,global_position,direction,_visual_extent,-1.0)
		_renderer.emit_effect(fighter_id,9,global_position,direction,_visual_extent*1.3,.18)

func _deliver_hit(target: Node) -> void:
	if not active or target == null or target == owner_fighter:
		return
	if not target.has_method("receive_hit"):
		return
	var id := str(target.get_instance_id())
	if hit_targets.has(id):
		return
	hit_targets[id] = true
	var hit_move := move_data.duplicate(true)
	hit_move["damage"] = damage
	hit_move["_from_projectile"] = true
	hit_move["_contact_world"] = global_position
	var resolver = null
	if owner_fighter != null and "hit_resolver" in owner_fighter:
		resolver = owner_fighter.hit_resolver
	var confirmed: Dictionary = {}
	if resolver != null and resolver.has_method("resolve"):
		confirmed = resolver.resolve(owner_fighter, target, hit_move, owner_fighter.damage_percent if "damage_percent" in owner_fighter else 0.0)
	if not confirmed.is_empty():
		projectile_hit.emit(target, confirmed)
	if behavior != "beam":
		_expire()


func _on_body_entered(body: Node) -> void:
	if body != owner_fighter and not body.has_method("receive_hit") and not _environment_sounded:
		_environment_sounded = true
		if _renderer != null: _renderer.emit_effect(fighter_id,0,global_position,direction,_visual_extent*1.4,.25,"environment:"+str(get_instance_id()))
	_deliver_hit(body)


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	_deliver_hit(area.get_parent())

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
	if _renderer != null:
		_renderer.update_slot(_flight_slot,global_position,direction,_visual_extent)
		_emission_distance += speed/SIM_FPS
		var spacing := 18.0 if _renderer.option("reduced_particles") else 7.0
		if _emission_distance >= spacing:
			_emission_distance=0
			_renderer.emit_effect(fighter_id,3 if fighter_id == "juno-spark" else 4,global_position-direction.normalized()*10.0,direction,_visual_extent*.65,.20)
	if frame_count >= lifetime_frames:
		_expire()

func _expire() -> void:
	if not active: return
	preload("res://scripts/audio/elemental_performance.gd").one_shot(fighter_id,"projectile_dissipate",get_parent(),.5)
	if _renderer != null:
		_renderer.stop_slot(_flight_slot)
		_flight_slot=-1
		_renderer.emit_effect(fighter_id,5,global_position,direction,_visual_extent,.22)
	active = false
	set_deferred("monitoring", false)
	projectile_expired.emit()
	queue_free()

func set_debug_visible(v: bool) -> void:
	debug_visible = v
	# DebugRect remains available for engineers; never auto-shown as player art.
	if debug_rect:
		debug_rect.visible = v

func _exit_tree() -> void:
	if is_instance_valid(_renderer): _renderer.stop_slot(_flight_slot)
