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
	SceneRouter.go("arcade")

func on_back() -> void:
	SceneRouter.go("main_menu")
