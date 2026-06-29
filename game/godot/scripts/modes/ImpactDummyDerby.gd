extends Node
class_name ImpactDummyDerby

signal derby_started(fighter_id: String)
signal derby_finished(final_score: float)
signal fighter_required

@export var dummy_path: NodePath
@export var round_time_seconds: float = 45.0

var selected_fighter_id: String = ""
var running: bool = false
var timer: float = 0.0
var score: float = 0.0
var dummy: ImpactDummy

func _ready() -> void:
	dummy = get_node_or_null(dummy_path)
	if dummy != null:
		dummy.dummy_hit.connect(_on_dummy_hit)

func set_selected_fighter(fighter_id: String) -> void:
	selected_fighter_id = fighter_id

func start_derby() -> bool:
	if selected_fighter_id.is_empty():
		fighter_required.emit()
		return false
	running = true
	timer = round_time_seconds
	score = 0.0
	derby_started.emit(selected_fighter_id)
	return true

func _process(delta: float) -> void:
	if not running:
		return
	timer -= delta
	if timer <= 0.0:
		running = false
		derby_finished.emit(score)

func _on_dummy_hit(hit_info: Dictionary) -> void:
	if not running:
		return
	var launch: Vector2 = hit_info.get("launch_velocity", Vector2.ZERO)
	var damage: float = float(hit_info.get("damage", 0.0))
	score += launch.length() * 0.05 + damage * 2.0
