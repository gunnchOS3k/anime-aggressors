extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Mode Select"

func _on_versus_pressed() -> void:
	GameState.mode = "versus"
	GameState.arcade_active = false
	SceneRouter.go("ruleset")

func _on_training_pressed() -> void:
	GameState.mode = "training"
	GameState.arcade_active = false
	SceneRouter.go_training()

func _on_arcade_pressed() -> void:
	GameState.mode = "arcade"
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	SceneRouter.go("arcade")

func _on_tutorial_pressed() -> void:
	GameState.mode = "tutorial"
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	SceneRouter.go_tutorial()

func _on_hazards_pressed() -> void:
	GameState.mode = "hazards"
	SceneRouter.go_hazards()

func on_back() -> void:
	SceneRouter.go("main_menu")
