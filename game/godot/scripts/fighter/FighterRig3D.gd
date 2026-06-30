extends Node2D
class_name FighterRig3D

## Stylized volumetric fighter rig rendered via SubViewport + MeshInstance3D parts.

@export var fighter_id: String = "ember-vale"

var viewport: SubViewport
var display: Sprite2D
var rig_root: Node3D
var camera: Camera3D
var limbs: Dictionary = {}
var sockets: Dictionary = {}

const LIMB_ALIASES := {
	"left_arm": "left_upper_arm",
	"right_arm": "right_upper_arm",
	"left_leg": "left_thigh",
	"right_leg": "right_thigh",
}

func _ready() -> void:
	_setup_viewport()
	FighterRigFactory.build_rig(rig_root, fighter_id, limbs, sockets, self)

func configure(fighter: String) -> void:
	fighter_id = fighter
	if rig_root != null:
		for child in rig_root.get_children():
			child.queue_free()
		limbs.clear()
		sockets.clear()
		FighterRigFactory.build_rig(rig_root, fighter_id, limbs, sockets, self)

func _setup_viewport() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(192, 240)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.35
	camera.position = Vector3(0.15, 1.05, 4.2)
	camera.rotation_degrees = Vector3(-8, 0, 0)
	viewport.add_child(camera)

	rig_root = Node3D.new()
	rig_root.name = "RigRoot"
	viewport.add_child(rig_root)

	display = Sprite2D.new()
	display.texture = viewport.get_texture()
	display.position = Vector2(0, -52)
	display.scale = Vector2(1.35, 1.35)
	add_child(display)

func apply_pose(pose: Dictionary, blend: float = 1.0) -> void:
	for limb_name in pose.keys():
		var target_name: String = String(LIMB_ALIASES.get(limb_name, limb_name))
		var node: Node3D = limbs.get(target_name)
		if node == null:
			node = limbs.get(limb_name)
		if node == null:
			continue
		var transform_data: Dictionary = pose[limb_name]
		if transform_data.has("rotation"):
			var rot := float(transform_data["rotation"])
			node.rotation.z = lerp_angle(node.rotation.z, rot, blend)
		if transform_data.has("position"):
			var pos: Vector2 = transform_data["position"]
			var target_pos := Vector3(pos.x * 0.01, -pos.y * 0.01, 0.0)
			node.position = node.position.lerp(target_pos, blend)
		if transform_data.has("scale"):
			var sc: Vector2 = transform_data["scale"]
			var target_scale := Vector3(sc.x, sc.y, sc.x)
			node.scale = node.scale.lerp(target_scale, blend)

func get_socket_global_position(socket_name: String) -> Vector2:
	var offset := Vector2(0, -40)
	match socket_name:
		"right_fist", "weapon_tip":
			offset = Vector2(36, -52)
		"left_fist":
			offset = Vector2(-36, -52)
		"right_foot":
			offset = Vector2(20, 10)
		"left_foot":
			offset = Vector2(-20, 10)
		"chest_aura", "aura_socket":
			offset = Vector2(0, -44)
	var dir := 1.0 if scale.x >= 0.0 else -1.0
	return global_position + Vector2(offset.x * dir, offset.y)

func set_facing(direction: int) -> void:
	scale.x = absf(scale.x) * float(direction)
