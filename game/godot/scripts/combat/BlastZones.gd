extends Node2D
class_name BlastZones

signal exited_blast_zone(target: Node2D)

@export var left_x: float = -1400.0
@export var right_x: float = 1400.0
@export var top_y: float = -900.0
@export var bottom_y: float = 900.0

func is_out_of_bounds(point: Vector2) -> bool:
	return point.x < left_x or point.x > right_x or point.y < top_y or point.y > bottom_y

func validate_fighter(fighter: Node2D) -> bool:
	if fighter == null:
		return false
	if is_out_of_bounds(fighter.global_position):
		exited_blast_zone.emit(fighter)
		return true
	return false
