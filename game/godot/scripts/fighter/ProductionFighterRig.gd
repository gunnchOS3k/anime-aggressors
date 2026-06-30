extends Node2D
class_name ProductionFighterRig

## Production-proxy volumetric fighter rig (SubViewport + MeshInstance3D + toon materials).

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
	"left_leg": "left_upper_leg",
	"right_leg": "right_upper_leg",
	"torso": "chest",
}

func _ready() -> void:
	_setup_viewport()
	ProductionFighterFactory.build_rig(rig_root, fighter_id, limbs, sockets, self)

func configure(fighter: String) -> void:
	fighter_id = fighter
	if rig_root != null:
		for child in rig_root.get_children():
			child.queue_free()
		limbs.clear()
		sockets.clear()
		ProductionFighterFactory.build_rig(rig_root, fighter_id, limbs, sockets, self)

func _setup_viewport() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(220, 280)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.55
	camera.position = Vector3(0.12, 1.08, 4.4)
	camera.rotation_degrees = Vector3(-10, 0, 0)
	viewport.add_child(camera)

	rig_root = Node3D.new()
	rig_root.name = "RigRoot"
	viewport.add_child(rig_root)

	display = Sprite2D.new()
	display.texture = viewport.get_texture()
	display.position = Vector2(0, -58)
	display.scale = Vector2(1.45, 1.45)
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
			node.rotation.z = lerp_angle(node.rotation.z, float(transform_data["rotation"]), blend)
		if transform_data.has("position"):
			var pos: Vector2 = transform_data["position"]
			node.position = node.position.lerp(Vector3(pos.x * 0.01, -pos.y * 0.01, node.position.z), blend)
		if transform_data.has("scale"):
			var sc: Vector2 = transform_data["scale"]
			node.scale = node.scale.lerp(Vector3(sc.x, sc.y, sc.x), blend)

func get_socket_global_position(socket_name: String) -> Vector2:
	var socket: Node3D = sockets.get(socket_name)
	var offset := Vector2(0, -44)
	if socket != null:
		offset = Vector2(socket.position.x * 88.0, -socket.position.y * 88.0 - 40.0)
	match socket_name:
		"right_hand_socket", "right_fist", "weapon_socket", "weapon_tip":
			offset = Vector2(40, -56)
		"left_hand_socket", "left_fist":
			offset = Vector2(-40, -56)
		"right_foot_socket", "right_foot":
			offset = Vector2(22, 12)
		"left_foot_socket", "left_foot":
			offset = Vector2(-22, 12)
	var dir := 1.0 if scale.x >= 0.0 else -1.0
	return global_position + Vector2(offset.x * dir, offset.y)

func set_facing(direction: int) -> void:
	scale.x = absf(scale.x) * float(direction)

func play_victory() -> void:
	if sockets.has("right_hand_socket"):
		var hand: Node3D = sockets["right_hand_socket"]
		hand.rotation.z = -1.2

func play_hit_spark(at_socket: String) -> void:
	var socket: Node3D = sockets.get(at_socket, sockets.get("right_hand_socket"))
	if socket != null:
		HitSparkFactory.spawn(socket, FighterAppearance.get_style(fighter_id)["glow"])
