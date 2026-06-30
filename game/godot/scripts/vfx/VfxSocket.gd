extends Node3D
class_name VfxSocket

@export var socket_name: String = "right_fist"
@export var element: String = "flame"

func emit_burst() -> void:
	var particles := get_node_or_null("Particles") as GPUParticles3D
	if particles != null:
		particles.restart()
		particles.emitting = true
