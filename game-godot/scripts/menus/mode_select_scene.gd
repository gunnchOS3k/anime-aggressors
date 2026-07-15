extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Mode Select"

func _on_versus_pressed() -> void:
	SceneRouter.go("ruleset")

func _on_training_pressed() -> void:
	SceneRouter.go_training()

func on_back() -> void:
	SceneRouter.go("main_menu")
