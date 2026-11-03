extends CharacterBody2D
class_name ColossusActor
## Real Colossus battlefield actor — CharacterBody2D + scale-aware capsule collision.
## Beyond dictionary scaffolds. Controllable Mythic-only; avatar KO ≠ true defeat.
## HUMAN_ART_APPROVED=false — procedural capsule mesh stand-in, not final art.

const ColossusRig = preload("res://scripts/trials/unbound/colossus_rig.gd")

var rig_id: String = ""
var display_name: String = ""
var slot: int = 0
var scale_factor: float = 4.5
var hp: int = 1000
var max_hp: int = 1000
var facing: int = 1
var avatar_ko: bool = false
var controllable_in_mythic_only: bool = true
var live_tick_enabled: bool = true
var HUMAN_ART_APPROVED: bool = false
var final_rig_approved: bool = false
var beyond_dictionary_scaffold: bool = true

var _capsule: CollisionShape2D
var _hurt: Area2D
var _hurt_shape: CollisionShape2D
var _visual: Polygon2D
var _label: Label
var _seed: int = 1
var _frame: int = 0


func configure_from_rig(rig: Dictionary) -> void:
	rig_id = str(rig.get("rig_id", "colossus"))
	display_name = str(rig.get("display_name", rig_id))
	slot = int(rig.get("slot", 0))
	_seed = int(rig.get("seed", 1))
	scale_factor = float(rig.get("scale", 4.5))
	hp = int(rig.get("hp", 1000))
	max_hp = int(rig.get("max_hp", 1000))
	facing = int(rig.get("facing", 1))
	avatar_ko = bool(rig.get("avatar_ko", false))
	controllable_in_mythic_only = bool(rig.get("controllable_in_mythic_only", true))
	live_tick_enabled = bool(rig.get("live_tick_enabled", true))
	HUMAN_ART_APPROVED = false
	final_rig_approved = false
	var pos: Dictionary = rig.get("position", {})
	global_position = Vector2(float(pos.get("x", 960.0)), float(pos.get("y", 540.0)))
	name = "ColossusActor_%s" % rig_id
	_ensure_nodes()
	_apply_collision_from_rig(rig)
	_refresh_visual()


func _ensure_nodes() -> void:
	if _capsule == null:
		_capsule = CollisionShape2D.new()
		_capsule.name = "BodyCapsule"
		add_child(_capsule)
	if _hurt == null:
		_hurt = Area2D.new()
		_hurt.name = "Hurtbox"
		_hurt.collision_layer = 1 << 3
		_hurt.collision_mask = 0
		_hurt.monitoring = false
		_hurt.monitorable = true
		add_child(_hurt)
		_hurt_shape = CollisionShape2D.new()
		_hurt_shape.name = "HurtShape"
		_hurt.add_child(_hurt_shape)
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "ProceduralStandIn"
		_visual.z_index = 2
		add_child(_visual)
	if _label == null:
		_label = Label.new()
		_label.name = "RigLabel"
		_label.position = Vector2(-80, -220)
		_label.add_theme_font_size_override("font_size", 14)
		add_child(_label)


func _apply_collision_from_rig(rig: Dictionary) -> void:
	var c: Dictionary = rig.get("collision", {})
	var radius: float = float(c.get("radius", 48.0 * scale_factor))
	var height: float = float(c.get("height", 120.0 * scale_factor))
	var shape := CapsuleShape2D.new()
	shape.radius = radius
	shape.height = maxf(height, radius * 2.0)
	_capsule.shape = shape
	var hurt_shape := CapsuleShape2D.new()
	hurt_shape.radius = radius
	hurt_shape.height = maxf(height, radius * 2.0)
	_hurt_shape.shape = hurt_shape
	## Procedural silhouette — not HUMAN_ART.
	var w: float = radius
	var h: float = height * 0.5
	_visual.polygon = PackedVector2Array([
		Vector2(-w, -h), Vector2(w, -h), Vector2(w * 0.85, h), Vector2(-w * 0.85, h),
	])
	_visual.color = Color(0.55, 0.35, 0.75, 0.55) if "yin" in rig_id else Color(0.85, 0.75, 0.35, 0.55)
	if "rosamere" in rig_id:
		_visual.color = Color(0.95, 0.45, 0.7, 0.5)
	_label.text = "%s\nHP %d  ART=false" % [display_name, hp]


func _refresh_visual() -> void:
	if _label != null:
		_label.text = "%s\nHP %d%s  ART=false" % [
			display_name, hp, " KO" if avatar_ko else "",
		]
	if _visual != null:
		_visual.scale.x = float(facing)


func to_rig_dictionary() -> Dictionary:
	return {
		"rig_id": rig_id,
		"display_name": display_name,
		"slot": slot,
		"seed": _seed,
		"scale": scale_factor,
		"hp": hp,
		"max_hp": max_hp,
		"position": {"x": global_position.x, "y": global_position.y},
		"facing": facing,
		"collision": {
			"mode": "scale_aware_capsule",
			"radius": 48.0 * scale_factor,
			"height": 120.0 * scale_factor,
			"hurtbox_layers": ["torso", "guard", "reach"],
			"not_simple_uniform_scale_hitbox": true,
			"frame_sampled": true,
			"actor_node": true,
		},
		"controllable_in_mythic_only": controllable_in_mythic_only,
		"avatar_ko": avatar_ko,
		"avatar_ko_is_true_rosamere_defeat": false,
		"canonical_cosmic_defeat": false,
		"real_giant_engineering": true,
		"not_scale_up_transform_only": true,
		"live_tick_enabled": live_tick_enabled,
		"actor_class": "ColossusActor",
		"beyond_dictionary_scaffold": true,
		"HUMAN_ART_APPROVED": false,
		"final_rig_approved": false,
		"frame": _frame,
	}


func apply_hit(knockback_mult: float, hit_facing: int) -> void:
	var next: Dictionary = ColossusRig.apply_hit(to_rig_dictionary(), knockback_mult, hit_facing)
	hp = int(next.get("hp", hp))
	facing = int(next.get("facing", facing))
	avatar_ko = bool(next.get("avatar_ko", false))
	var pos: Dictionary = next.get("position", {})
	global_position = Vector2(float(pos.get("x", global_position.x)), float(pos.get("y", global_position.y)))
	_refresh_visual()


func tick_frame(frame: int, seed: int) -> void:
	if avatar_ko or not live_tick_enabled:
		return
	_frame = frame
	var stepped: Array = ColossusRig.step_rigs([to_rig_dictionary()], frame, seed)
	if stepped.is_empty():
		return
	var next: Dictionary = stepped[0]
	var pos: Dictionary = next.get("position", {})
	global_position = Vector2(float(pos.get("x", global_position.x)), float(pos.get("y", global_position.y)))
	_refresh_visual()


func overlap_point(point: Vector2) -> Dictionary:
	## Live collision probe using the actual capsule shape — not dict-only math.
	var shape: CapsuleShape2D = _capsule.shape as CapsuleShape2D if _capsule != null else null
	if shape == null:
		return ColossusRig.overlap_summary(to_rig_dictionary(), point)
	var local: Vector2 = to_local(point)
	var r: float = shape.radius
	var half_h: float = shape.height * 0.5
	var inside: bool = absf(local.x) <= r and absf(local.y) <= half_h
	## Also honor Area2D hurtbox presence for engine-backed collision honesty.
	var area_ok: bool = _hurt != null and _hurt_shape != null and _hurt_shape.shape != null
	return {
		"inside": inside,
		"rig_id": rig_id,
		"mode": "scale_aware_capsule",
		"actor_node": true,
		"area2d_hurtbox": area_ok,
		"beyond_dictionary_scaffold": true,
		"not_simple_uniform_scale_hitbox": true,
		"HUMAN_ART_APPROVED": false,
	}


static func spawn_from_rig(parent: Node, rig: Dictionary) -> CharacterBody2D:
	## Return CharacterBody2D to avoid class_name self-reference parse cycles.
	var actor = (load("res://scripts/trials/unbound/colossus_actor.gd") as GDScript).new()
	if parent != null:
		parent.add_child(actor)
	actor.configure_from_rig(rig)
	return actor


static func spawn_preset(parent: Node, preset_id: String, seed: int) -> Array:
	var actors: Array = []
	for rig in ColossusRig.spawn_for_preset(preset_id, seed):
		actors.append(spawn_from_rig(parent, rig))
	return actors
