extends RefCounted
class_name AttackTrailFactory

static func spawn_trail(socket: Node3D, color: Color, trail_kind: String = "default_arc") -> void:
	if socket == null:
		return
	var trail := GPUParticles3D.new()
	trail.one_shot = true
	trail.amount = 12
	trail.lifetime = 0.18
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.04
	mat.direction = Vector3(1, 0, 0) if trail_kind != "uppercut_arc" else Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.8
	mat.initial_velocity_max = 2.4
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.04
	mat.scale_max = 0.10
	mat.color = color
	trail.process_material = mat
	trail.emitting = true
	socket.add_child(trail)
