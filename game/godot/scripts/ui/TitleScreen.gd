extends Control
class_name TitleScreen

signal start_pressed
signal derby_pressed

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(320, 200)
	add_child(panel)

	var title := Label.new()
	title.text = "Anime Aggressors"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var sub := Label.new()
	sub.text = "Create your fighter. Pick your element. Launch your rivals."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(sub)

	var battle := Button.new()
	battle.text = "Normal Battle"
	battle.pressed.connect(func(): start_pressed.emit())
	panel.add_child(battle)

	var derby := Button.new()
	derby.text = "Impact Dummy Derby"
	derby.pressed.connect(func(): derby_pressed.emit())
	panel.add_child(derby)
