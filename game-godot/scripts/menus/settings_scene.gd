extends "res://scripts/ui/console_menu_base.gd"

@onready var touch_mode_label: Label = %TouchModeValue

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Settings"
	_refresh_touch_label()

func _on_touch_mode_pressed() -> void:
	TouchInputManager.cycle_touch_mode()
	_refresh_touch_label()

func _refresh_touch_label() -> void:
	if touch_mode_label:
		touch_mode_label.text = TouchInputManager.touch_mode_label()

func on_back() -> void:
	if TouchInputManager.should_show_touch():
		SceneRouter.go("mobile_playtest")
	else:
		SceneRouter.go("main_menu")
