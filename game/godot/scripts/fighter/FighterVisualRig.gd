extends Node2D
class_name FighterVisualRig

@export var root_path: NodePath
@export var hips_path: NodePath
@export var torso_path: NodePath
@export var head_path: NodePath
@export var left_arm_path: NodePath
@export var right_arm_path: NodePath
@export var left_leg_path: NodePath
@export var right_leg_path: NodePath
@export var left_foot_path: NodePath
@export var right_foot_path: NodePath
@export var element_aura_path: NodePath

var limbs: Dictionary = {}

func _ready() -> void:
	_cache_limb_nodes()

func _cache_limb_nodes() -> void:
	limbs = {
		"root": get_node_or_null(root_path),
		"hips": get_node_or_null(hips_path),
		"torso": get_node_or_null(torso_path),
		"head": get_node_or_null(head_path),
		"left_arm": get_node_or_null(left_arm_path),
		"right_arm": get_node_or_null(right_arm_path),
		"left_leg": get_node_or_null(left_leg_path),
		"right_leg": get_node_or_null(right_leg_path),
		"left_foot": get_node_or_null(left_foot_path),
		"right_foot": get_node_or_null(right_foot_path),
		"element_aura": get_node_or_null(element_aura_path)
	}

func apply_pose(pose: Dictionary, blend: float = 1.0) -> void:
	for limb_name in pose.keys():
		var target: Node2D = limbs.get(limb_name)
		if target == null:
			continue
		var transform_data: Dictionary = pose[limb_name]
		if transform_data.has("position"):
			target.position = target.position.lerp(transform_data["position"], blend)
		if transform_data.has("rotation"):
			target.rotation = lerp_angle(target.rotation, float(transform_data["rotation"]), blend)
		if transform_data.has("scale"):
			target.scale = target.scale.lerp(transform_data["scale"], blend)
		if transform_data.has("modulate"):
			target.modulate = target.modulate.lerp(transform_data["modulate"], blend)
