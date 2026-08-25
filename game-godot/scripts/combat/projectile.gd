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
var _trail: Line2D = null
var _core: Polygon2D = null
var _glow: Polygon2D = null
var _impact_flash: float = 0.0

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
	monitoring = true
	collision_layer = 8
	collision_mask = 6
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func uses_intentional_visual() -> bool:
	return _visual != null and is_instance_valid(_visual) and _visual.visible and (debug_rect == null or not debug_rect.visible)


func _build_intentional_visual(base_col: Color, size: Vector2) -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = Node2D.new()
	_visual.name = "IntentionalProjectileVisual"
	add_child(_visual)

	var scale_m := 1.0
	match projectile_tier:
		"projectile_medium":
			scale_m = 1.35
		"projectile_full":
			scale_m = 1.75
		_:
			scale_m = 1.0

	# Wave018: roster-wide intentional silhouettes (not moving-rectangle primary).
	var glow_poly := _fighter_tier_poly(fighter_id, projectile_tier, size.x * 0.95 * scale_m, size.y * 0.75 * scale_m, true)
	var core_poly := _fighter_tier_poly(fighter_id, projectile_tier, size.x * 0.55 * scale_m, size.y * 0.45 * scale_m, false)
	_glow = Polygon2D.new()
	_glow.name = "Glow"
	_glow.color = Color(base_col.r, base_col.g, base_col.b, 0.30)
	_glow.polygon = glow_poly
	_visual.add_child(_glow)

	_core = Polygon2D.new()
	_core.name = "Core"
	_core.color = Color(
		minf(1.0, base_col.r * 1.15),
		minf(1.0, base_col.g * 1.05),
		minf(1.0, base_col.b * 0.85),
		0.95
	)
	_core.polygon = core_poly
	_visual.add_child(_core)

	_trail = Line2D.new()
	_trail.name = "Trail"
	var trail_w := maxf(3.0, size.y * 0.35 * scale_m)
	match projectile_tier:
		"projectile_medium":
			trail_w *= 1.25
		"projectile_full":
			trail_w *= 1.55
	_trail.width = trail_w
	_trail.default_color = Color(base_col.r, base_col.g * 0.7, base_col.b * 0.4, 0.55)
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	_visual.add_child(_trail)
	# Spawn flash ring — denser for full charge
	var ring := Polygon2D.new()
	ring.name = "SpawnFlash"
	ring.color = Color(1.0, 0.85, 0.45, 0.65 if projectile_tier != "projectile_full" else 0.85)
	ring.polygon = _ring_poly(size.x * (0.8 if projectile_tier != "projectile_full" else 1.15) * scale_m)
	_visual.add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "modulate:a", 0.0, 0.18)
	tw.tween_callback(ring.queue_free)
	if projectile_tier == "projectile_full":
		var corona := Polygon2D.new()
		corona.name = "FullCorona"
		corona.color = Color(base_col.r, base_col.g, base_col.b, 0.35)
		corona.polygon = _ring_poly(size.x * 1.4 * scale_m)
		_visual.add_child(corona)


func _ember_poly(w: float, h: float) -> PackedVector2Array:
	# Teardrop / ember silhouette — not a rectangle.
	return PackedVector2Array([
		Vector2(-w * 0.55, 0.0),
		Vector2(-w * 0.15, -h * 0.55),
		Vector2(w * 0.35, -h * 0.35),
		Vector2(w * 0.65, 0.0),
		Vector2(w * 0.35, h * 0.35),
		Vector2(-w * 0.15, h * 0.55),
	])


func _tier_poly(tier: String, w: float, h: float, glow: bool) -> PackedVector2Array:
	return _fighter_tier_poly(fighter_id, tier, w, h, glow)


func _fighter_tier_poly(fid: String, tier: String, w: float, h: float, glow: bool) -> PackedVector2Array:
	match fid:
		"rook-ironside":
			return _rook_poly(tier, w, h)
		"juno-spark":
			return _juno_poly(tier, w, h)
		"kaia-windrow":
			return _kaia_poly(tier, w, h)
		"nix-calder":
			return _nix_poly(tier, w, h)
		"orion-vell":
			return _orion_poly(tier, w, h, glow)
		"vesper-nyx":
			return _vesper_poly(tier, w, h)
		_:
			# Ember Vale default family (Wave016/017)
			return _ember_tier_poly(tier, w, h, glow)


func _ember_tier_poly(tier: String, w: float, h: float, glow: bool) -> PackedVector2Array:
	match tier:
		"projectile_medium":
			return PackedVector2Array([
				Vector2(-w * 0.5, 0.0),
				Vector2(-w * 0.1, -h * 0.7),
				Vector2(w * 0.25, -h * 0.25),
				Vector2(w * 0.7, -h * 0.15),
				Vector2(w * 0.45, 0.0),
				Vector2(w * 0.7, h * 0.15),
				Vector2(w * 0.25, h * 0.25),
				Vector2(-w * 0.1, h * 0.7),
			])
		"projectile_full":
			var pts := PackedVector2Array()
			var spikes := 7 if glow else 5
			for i in spikes:
				var a := TAU * float(i) / float(spikes)
				var r := (w if i % 2 == 0 else w * 0.55)
				pts.append(Vector2(cos(a), sin(a)) * r * 0.55)
			return pts
		_:
			return _ember_poly(w, h)


func _rook_poly(tier: String, w: float, h: float) -> PackedVector2Array:
	# Heavy hammer / impact wedge
	match tier:
		"projectile_medium":
			return PackedVector2Array([
				Vector2(-w * 0.55, -h * 0.35), Vector2(w * 0.35, -h * 0.55),
				Vector2(w * 0.65, 0.0), Vector2(w * 0.35, h * 0.55), Vector2(-w * 0.55, h * 0.35),
			])
		"projectile_full":
			return PackedVector2Array([
				Vector2(-w * 0.6, -h * 0.5), Vector2(w * 0.2, -h * 0.7), Vector2(w * 0.75, 0.0),
				Vector2(w * 0.2, h * 0.7), Vector2(-w * 0.6, h * 0.5), Vector2(-w * 0.35, 0.0),
			])
		_:
			return PackedVector2Array([
				Vector2(-w * 0.5, -h * 0.4), Vector2(w * 0.55, -h * 0.25),
				Vector2(w * 0.55, h * 0.25), Vector2(-w * 0.5, h * 0.4),
			])


func _juno_poly(tier: String, w: float, h: float) -> PackedVector2Array:
	# Zigzag bolt
	match tier:
		"projectile_medium":
			return PackedVector2Array([
				Vector2(-w * 0.55, 0.0), Vector2(-w * 0.1, -h * 0.55), Vector2(w * 0.15, -h * 0.1),
				Vector2(w * 0.55, -h * 0.45), Vector2(w * 0.7, 0.0), Vector2(w * 0.55, h * 0.45),
				Vector2(w * 0.15, h * 0.1), Vector2(-w * 0.1, h * 0.55),
			])
		"projectile_full":
			return PackedVector2Array([
				Vector2(-w * 0.65, 0.0), Vector2(-w * 0.2, -h * 0.7), Vector2(w * 0.05, -h * 0.15),
				Vector2(w * 0.45, -h * 0.65), Vector2(w * 0.8, 0.0), Vector2(w * 0.45, h * 0.65),
				Vector2(w * 0.05, h * 0.15), Vector2(-w * 0.2, h * 0.7),
			])
		_:
			return PackedVector2Array([
				Vector2(-w * 0.5, 0.0), Vector2(0.0, -h * 0.45), Vector2(w * 0.2, -h * 0.05),
				Vector2(w * 0.6, -h * 0.35), Vector2(w * 0.35, 0.0), Vector2(w * 0.6, h * 0.35),
				Vector2(w * 0.2, h * 0.05), Vector2(0.0, h * 0.45),
			])


func _kaia_poly(tier: String, w: float, h: float) -> PackedVector2Array:
	# Crescent gale blade
	var amp := 1.15 if tier == "projectile_full" else (1.0 if tier == "projectile_medium" else 0.85)
	return PackedVector2Array([
		Vector2(-w * 0.4 * amp, 0.0),
		Vector2(-w * 0.05, -h * 0.7 * amp),
		Vector2(w * 0.55 * amp, -h * 0.25),
		Vector2(w * 0.35 * amp, 0.0),
		Vector2(w * 0.55 * amp, h * 0.25),
		Vector2(-w * 0.05, h * 0.7 * amp),
	])


func _nix_poly(tier: String, w: float, h: float) -> PackedVector2Array:
	# Crystal shard
	match tier:
		"projectile_full":
			return PackedVector2Array([
				Vector2(-w * 0.35, 0.0), Vector2(0.0, -h * 0.75), Vector2(w * 0.55, -h * 0.2),
				Vector2(w * 0.75, 0.0), Vector2(w * 0.55, h * 0.2), Vector2(0.0, h * 0.75),
			])
		_:
			return PackedVector2Array([
				Vector2(-w * 0.4, 0.0), Vector2(0.0, -h * 0.6), Vector2(w * 0.65, 0.0), Vector2(0.0, h * 0.6),
			])


func _orion_poly(tier: String, w: float, h: float, glow: bool) -> PackedVector2Array:
	# Orbit ring / node cluster
	var pts := PackedVector2Array()
	var n := 10 if glow or tier == "projectile_full" else 8
	var r_outer := w * (0.55 if tier != "projectile_tap" else 0.45)
	var r_inner := r_outer * (0.55 if tier == "projectile_full" else 0.7)
	for i in n:
		var a := TAU * float(i) / float(n)
		var r := r_outer if i % 2 == 0 else r_inner
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _vesper_poly(tier: String, w: float, h: float) -> PackedVector2Array:
	# Asymmetric void sickle
	match tier:
		"projectile_medium":
			return PackedVector2Array([
				Vector2(-w * 0.5, -h * 0.15), Vector2(w * 0.1, -h * 0.65), Vector2(w * 0.7, -h * 0.1),
				Vector2(w * 0.25, 0.05), Vector2(w * 0.55, h * 0.45), Vector2(-w * 0.35, h * 0.25),
			])
		"projectile_full":
			return PackedVector2Array([
				Vector2(-w * 0.6, -h * 0.2), Vector2(0.0, -h * 0.8), Vector2(w * 0.8, -h * 0.15),
				Vector2(w * 0.3, 0.05), Vector2(w * 0.7, h * 0.55), Vector2(-w * 0.4, h * 0.35),
			])
		_:
			return PackedVector2Array([
				Vector2(-w * 0.45, 0.0), Vector2(w * 0.15, -h * 0.55), Vector2(w * 0.6, 0.0),
				Vector2(w * 0.1, h * 0.35),
			])


func _ring_poly(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


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
	var resolver = null
	if owner_fighter != null and "hit_resolver" in owner_fighter:
		resolver = owner_fighter.hit_resolver
	if resolver != null and resolver.has_method("resolve"):
		resolver.resolve(owner_fighter, target, hit_move, owner_fighter.damage_percent if "damage_percent" in owner_fighter else 0.0)
	projectile_hit.emit(target, hit_move)
	_spawn_impact()
	if behavior != "beam":
		_expire()


func _spawn_impact() -> void:
	if _visual == null:
		return
	var burst := Polygon2D.new()
	burst.color = Color(1.0, 0.7, 0.25, 0.85)
	var scale_i := 1.0
	match projectile_tier:
		"projectile_medium":
			scale_i = 1.35
			burst.polygon = _tier_poly(projectile_tier, 26.0, 18.0, false)
		"projectile_full":
			scale_i = 1.8
			burst.polygon = _tier_poly(projectile_tier, 32.0, 24.0, true)
			burst.color = Color(1.0, 0.55, 0.15, 0.9)
		_:
			burst.polygon = _fighter_tier_poly(fighter_id, projectile_tier, 22.0, 16.0, false)
	_visual.add_child(burst)
	var tw := create_tween()
	tw.tween_property(burst, "scale", Vector2(1.8, 1.8) * scale_i, 0.12)
	tw.parallel().tween_property(burst, "modulate:a", 0.0, 0.12)


func _on_body_entered(body: Node) -> void:
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
	if _trail != null:
		var back := -direction.normalized() * (18.0 + float(aura_level_at_spawn) * 4.0)
		_trail.points = PackedVector2Array([back, Vector2.ZERO])
	if _core != null:
		_core.rotation = direction.angle()
	if _glow != null:
		_glow.rotation = direction.angle()
		_glow.modulate.a = 0.22 + 0.08 * sin(float(frame_count) * 0.35)
	if frame_count >= lifetime_frames:
		_expire()

func _expire() -> void:
	active = false
	set_deferred("monitoring", false)
	projectile_expired.emit()
	queue_free()

func set_debug_visible(v: bool) -> void:
	debug_visible = v
	# DebugRect remains available for engineers; never auto-shown as player art.
	if debug_rect:
		debug_rect.visible = v
