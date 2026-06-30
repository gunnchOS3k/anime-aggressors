extends RefCounted
class_name ImpactFlash

static func pulse(socket: Node3D, color: Color) -> void:
	if socket == null:
		return
	var flash := OmniLight3D.new()
	flash.light_color = color
	flash.light_energy = 2.5
	flash.omni_range = 0.6
	socket.add_child(flash)
	var tween := socket.create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.12)
	tween.tween_callback(flash.queue_free)
