extends Control
class_name VersusScreen

signal versus_finished

var p1_id: String = ""
var p2_id: String = ""
var stage_id: String = "skyline-arena"

func show_matchup(p1: String, p2: String, stage: String = "skyline-arena") -> void:
	p1_id = p1
	p2_id = p2
	stage_id = stage
	visible = true
	_build_ui()
	await get_tree().create_timer(2.0).timeout
	visible = false
	versus_finished.emit()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(300, 220)
	add_child(panel)

	var vs := Label.new()
	var n1 := FighterRoster.get_fighter(p1_id).get("name", p1_id)
	var n2 := FighterRoster.get_fighter(p2_id).get("name", p2_id)
	vs.text = "%s  VS  %s" % [n1, n2]
	vs.add_theme_font_size_override("font_size", 36)
	panel.add_child(vs)

	var stage := Label.new()
	stage.text = stage_id.replace("-", " ").capitalize()
	stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(stage)
