extends Resource
class_name CameraBounds

@export var min_point: Vector2 = Vector2(-2000, -1200)
@export var max_point: Vector2 = Vector2(2000, 1200)

func clamp_position(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, min_point.x, max_point.x),
		clampf(position.y, min_point.y, max_point.y)
	)
