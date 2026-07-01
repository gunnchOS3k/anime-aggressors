extends Control

@onready var p1_label: Label = %P1Label
@onready var p2_label: Label = %P2Label
@onready var stage_label: Label = %StageLabel

func _ready() -> void:
	var p1: Dictionary = GameState.load_fighter(GameState.p1_fighter_id)
	var p2: Dictionary = GameState.load_fighter(GameState.p2_fighter_id)
	var stage: Dictionary = GameState.load_stage(GameState.stage_id)
	if p1_label:
		p1_label.text = p1.get("displayName", "P1")
	if p2_label:
		p2_label.text = p2.get("displayName", "P2") + (" (CPU)" if GameState.p2_is_cpu else "")
	if stage_label:
		stage_label.text = stage.get("displayName", GameState.stage_id)
	await get_tree().create_timer(2.0).timeout
	SceneRouter.go("battle")
