extends CharacterBody2D
class_name ImpactDummy

signal dummy_hit(hit_info: Dictionary)
signal dummy_ko

@export var launch_damping: float = 7.0
@export var blast_zones_path: NodePath

var damage_percent: float = 0.0
var blast_zones: BlastZones

func _ready() -> void:
	blast_zones = get_node_or_null(blast_zones_path)

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, launch_damping * delta * 100.0)
	velocity.y += FighterController.GRAVITY * delta
	move_and_slide()
	if blast_zones != null and blast_zones.validate_fighter(self):
		dummy_ko.emit()

func receive_hit(hit_info: Dictionary) -> void:
	damage_percent += float(hit_info.get("damage", 0.0))
	velocity = hit_info.get("launch_velocity", Vector2.ZERO)
	dummy_hit.emit(hit_info)
