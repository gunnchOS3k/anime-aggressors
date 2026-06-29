extends Area2D
class_name Hitbox

signal hit_connected(hitbox: Hitbox, hurtbox: Hurtbox)

@export var owner_fighter: Node
@export var move_type: MoveDefinition.MoveType = MoveDefinition.MoveType.JAB
@export var damage: float = 5.0
@export var knockback_angle_deg: float = 38.0
@export var base_knockback: float = 140.0
@export var knockback_growth: float = 1.2
@export var team_id: int = 0
@export var active: bool = false:
	set(value):
		active = value
		monitoring = value

var already_hit: Dictionary = {}

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = active

func activate() -> void:
	active = true
	monitoring = true
	already_hit.clear()

func deactivate() -> void:
	active = false
	monitoring = false
	already_hit.clear()

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	var hurtbox := area as Hurtbox
	if hurtbox == null:
		return
	if hurtbox.team_id == team_id:
		return
	if already_hit.has(hurtbox.get_instance_id()):
		return
	already_hit[hurtbox.get_instance_id()] = true
	hit_connected.emit(self, hurtbox)
