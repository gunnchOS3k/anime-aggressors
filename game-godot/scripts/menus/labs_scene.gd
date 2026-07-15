extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Labs / Experimental"

func on_back() -> void:
	SceneRouter.go("main_menu")
