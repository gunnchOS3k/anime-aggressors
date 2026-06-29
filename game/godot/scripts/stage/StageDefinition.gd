extends Resource
class_name StageDefinition

@export var stage_id: String = "training-room"
@export var display_name: String = "Training Room"
@export_file("*.tscn") var scene_path: String = ""
@export var spawn_a: Vector2 = Vector2(-220, -100)
@export var spawn_b: Vector2 = Vector2(220, -100)
@export var blast_left: float = -1450.0
@export var blast_right: float = 1450.0
@export var blast_top: float = -950.0
@export var blast_bottom: float = 950.0
