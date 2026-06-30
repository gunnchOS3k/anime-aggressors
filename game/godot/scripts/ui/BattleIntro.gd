extends CanvasLayer
class_name BattleIntro

signal intro_finished

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 42)
	add_child(_label)
	visible = false

func play(stage_name: String = "Skyline Arena") -> void:
	visible = true
	_label.text = stage_name
	await get_tree().create_timer(1.2).timeout
	_label.text = "Ready..."
	await get_tree().create_timer(0.8).timeout
	_label.text = "Fight!"
	await get_tree().create_timer(0.6).timeout
	visible = false
	intro_finished.emit()
