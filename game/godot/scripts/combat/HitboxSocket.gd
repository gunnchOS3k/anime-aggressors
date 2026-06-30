extends Node2D
class_name HitboxSocket

@export var socket_name: String = "right_fist"
@export var hitbox_path: NodePath

var rig: FighterRig3D

func _ready() -> void:
	rig = get_parent() as FighterRig3D

func sync_hitbox() -> void:
	if rig == null:
		return
	var hitbox := get_node_or_null(hitbox_path) as Area2D
	if hitbox == null:
		return
	hitbox.global_position = rig.get_socket_global_position(socket_name)
