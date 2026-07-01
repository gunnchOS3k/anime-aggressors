extends RefCounted
class_name HitboxTimeline

static func apply_active_frames(fighter: FighterController, data: MoveChoreographyData) -> void:
	if fighter == null or fighter.hitbox == null:
		return
	var socket_name := data.hitbox_socket
	if fighter.visual_rig != null and fighter.visual_rig.sockets.has(socket_name):
		fighter.hitbox.global_position = fighter.visual_rig.get_socket_global_position(socket_name)
	elif fighter.visual_rig != null:
		fighter.hitbox.global_position = fighter.visual_rig.get_socket_global_position("right_hand")

static func socket_at_frame(data: MoveChoreographyData, _frame: int) -> String:
	return data.hitbox_socket
