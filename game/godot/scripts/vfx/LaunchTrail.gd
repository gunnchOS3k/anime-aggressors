extends RefCounted
class_name LaunchTrail

static func attach(fighter: Node2D, color: Color) -> void:
	var trail := CPUParticles2D.new()
	trail.amount = 16
	trail.lifetime = 0.35
	trail.one_shot = false
	trail.emitting = true
	trail.gravity = Vector2(0, 40)
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 5.0
	trail.color = color
	fighter.add_child(trail)
