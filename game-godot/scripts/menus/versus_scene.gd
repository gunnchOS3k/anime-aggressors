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
		var cpu_tag := ""
		if GameState.p2_is_cpu:
			cpu_tag = " (CPU L%d)" % GameState.cpu_level
		p2_label.text = p2.get("displayName", "P2") + cpu_tag
	if stage_label:
		var stage_name: String = str(stage.get("displayName", GameState.stage_id))
		if GameState.arcade_active or GameState.mode == "arcade":
			stage_name = "Arcade %d/%d — %s" % [
				GameState.arcade_index + 1,
				GameState.ARCADE_LADDER.size(),
				stage_name,
			]
		stage_label.text = stage_name
	await get_tree().create_timer(2.0).timeout
	SceneRouter.go("battle")
