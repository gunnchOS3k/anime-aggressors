extends Area2D
class_name Hurtbox

signal hurt_received(hit_info: Dictionary)

@export var owner_fighter: Node
@export var team_id: int = 1
@export var invulnerable: bool = false

func can_be_hit() -> bool:
	return not invulnerable

func apply_hit(hit_info: Dictionary) -> void:
	if not can_be_hit():
		return
	hurt_received.emit(hit_info)
