extends RigidBody2D
class_name KineticBat

signal bat_impacted(force: float)

@export var impulse_scale: float = 1.0

func apply_hit(hit_info: Dictionary) -> void:
	var launch_velocity: Vector2 = hit_info.get("launch_velocity", Vector2.ZERO)
	var impulse := launch_velocity * mass * impulse_scale
	apply_impulse(impulse)
	bat_impacted.emit(launch_velocity.length())
