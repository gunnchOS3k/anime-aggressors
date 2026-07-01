extends RefCounted
class_name VfxTimeline

static func queue_trail(fighter: FighterController, data: MoveChoreographyData) -> void:
	if fighter == null or fighter.visual_rig == null:
		return
	var style := FighterAppearance.get_style(fighter.fighter_stats.fighter_id)
	var socket: Node3D = fighter.visual_rig.sockets.get(data.vfx_socket)
	if socket == null:
		socket = fighter.visual_rig.sockets.get("right_hand")
	if socket != null:
		AttackTrailFactory.spawn_trail(socket, style["glow"])

static func spawn_hit_spark(fighter: FighterController, socket_name: String = "hit_spark_center") -> void:
	if fighter?.visual_rig != null:
		fighter.visual_rig.play_hit_spark(socket_name)
