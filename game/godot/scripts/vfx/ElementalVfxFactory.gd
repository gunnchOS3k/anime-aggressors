extends RefCounted
class_name ElementalVfxFactory

static func attach_aura(owner: Node, fighter_id: String, socket: Node3D) -> void:
	if socket == null:
		return
	var style := FighterAppearance.get_style(fighter_id)
	var particles := GPUParticles3D.new()
	particles.name = "AuraParticles"
	particles.amount = 24
	particles.lifetime = 0.6
	particles.explosiveness = 0.0
	particles.local_coords = true
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.18
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3(0, -0.4, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.10
	mat.color = style.get("glow", Color.WHITE)
	particles.process_material = mat
	particles.emitting = true
	socket.add_child(particles)

static func spawn_hit_spark(parent: Node3D, color: Color) -> void:
	var spark := GPUParticles3D.new()
	spark.one_shot = true
	spark.amount = 16
	spark.lifetime = 0.25
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.05
	mat.spread = 180.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = color
	spark.process_material = mat
	spark.emitting = true
	parent.add_child(spark)
