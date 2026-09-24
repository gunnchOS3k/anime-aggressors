extends RefCounted
class_name SpectacleA11y

## A11y toggles. Gameplay outcome identical.

static func apply(reduce_camera: bool, reduce_flash: bool, reduce_particles: bool, reduce_secondary: bool) -> Dictionary:
	var gs = null
	if Engine.get_main_loop() != null:
		gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.training_camera_enabled = not reduce_camera
		gs.training_vfx_enabled = not reduce_particles
	var juice = null
	if Engine.get_main_loop() != null:
		juice = Engine.get_main_loop().root.get_node_or_null("/root/JuiceEventBus")
	if juice != null and juice.has_method("set_accessibility"):
		juice.set_accessibility(reduce_flash, reduce_camera, reduce_particles)
	return {
		"reduce_camera_movement": reduce_camera,
		"reduce_flashes": reduce_flash,
		"reduce_particles": reduce_particles,
		"reduce_secondary_motion": reduce_secondary,
		"stronger_silhouette_outlines": reduce_particles,
		"audio_dynamic_range": reduce_flash,
		"gameplay_identical": true,
	}
