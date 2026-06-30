extends RefCounted
class_name HitSparkFactory

static func spawn(socket: Node3D, color: Color) -> void:
	if socket == null:
		return
	ElementalVfxFactory.spawn_hit_spark(socket, color)
	ImpactFlash.pulse(socket, color)
