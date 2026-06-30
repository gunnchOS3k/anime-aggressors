extends Control
class_name BattleResults

signal rematch_requested
signal character_select_requested
signal main_menu_requested

var winner_id: String = ""
var p1_damage: float = 0.0
var p2_damage: float = 0.0

func show_results(winner: String, p1: FighterController, p2: FighterController) -> void:
	winner_id = winner
	p1_damage = p1.damage_percent if p1 != null else 0.0
	p2_damage = p2.damage_percent if p2 != null else 0.0
	visible = true
	_build_ui()
	if p1 != null and p1.fighter_stats.fighter_id == winner and p1.visual_rig != null:
		p1.visual_rig.play_victory()
	if p2 != null and p2.fighter_stats.fighter_id == winner and p2.visual_rig != null:
		p2.visual_rig.play_victory()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(280, 180)
	add_child(panel)

	var title := Label.new()
	var data := FighterRoster.get_fighter(winner_id)
	title.text = "WINNER: %s" % data.get("name", winner_id)
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)

	var stats := Label.new()
	stats.text = "Damage — P1: %.0f%%  P2: %.0f%%" % [p1_damage, p2_damage]
	panel.add_child(stats)

	var rematch := Button.new()
	rematch.text = "Rematch"
	rematch.pressed.connect(func(): rematch_requested.emit())
	panel.add_child(rematch)

	var select := Button.new()
	select.text = "Character Select"
	select.pressed.connect(func(): character_select_requested.emit())
	panel.add_child(select)

	var menu := Button.new()
	menu.text = "Main Menu"
	menu.pressed.connect(func(): main_menu_requested.emit())
	panel.add_child(menu)
