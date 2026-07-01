extends Control
class_name StageSelect

signal stage_confirmed(stage_id: String)

var stages: PackedStringArray = PackedStringArray(["skyline-arena"])
var selected_index: int = 0
var _label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.position = Vector2(280, 180)
	add_child(panel)

	var title := Label.new()
	title.text = "Select Stage"
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)

	_label = Label.new()
	panel.add_child(_label)

	var row := HBoxContainer.new()
	var prev := Button.new()
	prev.text = "◀"
	prev.pressed.connect(func(): _cycle(-1))
	var next := Button.new()
	next.text = "▶"
	next.pressed.connect(func(): _cycle(1))
	var confirm := Button.new()
	confirm.text = "Continue"
	confirm.pressed.connect(func(): stage_confirmed.emit(stages[selected_index]))
	row.add_child(prev)
	row.add_child(next)
	row.add_child(confirm)
	panel.add_child(row)
	_refresh()

func _cycle(dir: int) -> void:
	selected_index = posmod(selected_index + dir, stages.size())
	_refresh()

func _refresh() -> void:
	if _label != null:
		_label.text = stages[selected_index].replace("-", " ").capitalize()
