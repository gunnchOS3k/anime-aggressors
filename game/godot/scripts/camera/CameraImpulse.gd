extends Node
class_name CameraImpulse

@export var decay: float = 8.0
var offset_velocity: Vector2 = Vector2.ZERO

func add_impulse(impulse: Vector2) -> void:
	offset_velocity += impulse

func sample(delta: float) -> Vector2:
	var out := offset_velocity * delta
	offset_velocity = offset_velocity.move_toward(Vector2.ZERO, decay * delta * 100.0)
	return out
