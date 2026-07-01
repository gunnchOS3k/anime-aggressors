extends Control
class_name CharacterSelect

signal battle_selection_confirmed(p1_fighter_id: String, p2_fighter_id: String)
signal derby_selection_confirmed(single_fighter_id: String)

enum Mode { BATTLE, DERBY }

@export var mode: Mode = Mode.BATTLE
@export var p1_index: int = 0
@export var p2_index: int = 1

var fighter_ids: PackedStringArray = []
var p1_label: Label
var p2_label: Label

func _ready() -> void:
	fighter_ids = FighterRoster.get_ids()
	if fighter_ids.is_empty():
		fighter_ids = PackedStringArray(["ember-vale"])
	var ember_idx := fighter_ids.find("ember-vale")
	var juno_idx := fighter_ids.find("juno-spark")
	p1_index = ember_idx if ember_idx >= 0 else 0
	p2_index = juno_idx if juno_idx >= 0 else clampi(p2_index, 0, fighter_ids.size() - 1)
	p1_index = clampi(p1_index, 0, fighter_ids.size() - 1)
	p2_index = clampi(p2_index, 0, fighter_ids.size() - 1)
	_build_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(120, 80)
	add_child(panel)

	var title := Label.new()
	title.text = "Choose Your Derby Fighter" if mode == Mode.DERBY else "Select Fighters"
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)

	p1_label = Label.new()
	p1_label.name = "P1Label"
	panel.add_child(p1_label)

	p2_label = Label.new()
	p2_label.name = "P2Label"
	panel.add_child(p2_label)

	var row := HBoxContainer.new()
	var prev := Button.new()
	prev.text = "◀ Prev"
	prev.pressed.connect(func(): cycle_player(FighterInput.PlayerSlot.P1, -1); _refresh_labels())
	var next := Button.new()
	next.text = "Next ▶"
	next.pressed.connect(func(): cycle_player(FighterInput.PlayerSlot.P1, 1); _refresh_labels())
	var confirm := Button.new()
	confirm.text = "Continue to Derby" if mode == Mode.DERBY else "Continue"
	confirm.pressed.connect(confirm_selection)
	row.add_child(prev)
	row.add_child(next)
	row.add_child(confirm)
	panel.add_child(row)

	var gate := Label.new()
	gate.name = "ContentGateLabel"
	gate.add_theme_font_size_override("font_size", 11)
	gate.modulate = Color(1, 0.5, 0.4)
	panel.add_child(gate)

	if mode != Mode.DERBY:
		var p2row := HBoxContainer.new()
		var p2prev := Button.new()
		p2prev.text = "P2 ◀"
		p2prev.pressed.connect(func(): cycle_player(FighterInput.PlayerSlot.P2, -1); _refresh_labels())
		var p2next := Button.new()
		p2next.text = "P2 ▶"
		p2next.pressed.connect(func(): cycle_player(FighterInput.PlayerSlot.P2, 1); _refresh_labels())
		p2row.add_child(p2prev)
		p2row.add_child(p2next)
		panel.add_child(p2row)

	_refresh_labels()

func _refresh_labels() -> void:
	if p1_label != null:
		var data := FighterRoster.get_fighter(fighter_ids[p1_index])
		p1_label.text = "P1: %s (%s)" % [data.get("name", fighter_ids[p1_index]), data.get("element", "")]
	if p2_label != null:
		if mode == Mode.DERBY:
			p2_label.visible = false
		else:
			p2_label.visible = true
			var data2 := FighterRoster.get_fighter(fighter_ids[p2_index])
			p2_label.text = "P2: %s (%s)" % [data2.get("name", fighter_ids[p2_index]), data2.get("element", "")]
	_update_content_gate()

func _update_content_gate() -> void:
	var gate := get_node_or_null("VBoxContainer/ContentGateLabel") as Label
	if gate == null:
		for child in get_children():
			gate = child.find_child("ContentGateLabel", true, false) as Label
			if gate != null:
				break
	if gate == null:
		return
	var missing: Array[String] = []
	for id in [fighter_ids[p1_index], fighter_ids[p2_index] if mode != Mode.DERBY else fighter_ids[p1_index]]:
		if not FighterAssetContract.has_production_glb(id):
			missing.append(id)
	if missing.is_empty():
		gate.text = ""
	else:
		gate.text = "%s — missing GLB: %s" % [
			FighterAssetContract.DEBUG_FALLBACK_LABEL,
			", ".join(missing),
		]

func set_mode(new_mode: Mode) -> void:
	mode = new_mode

func cycle_player(player: FighterInput.PlayerSlot, direction: int) -> void:
	if fighter_ids.is_empty():
		return
	if player == FighterInput.PlayerSlot.P1:
		p1_index = _wrap_index(p1_index + direction)
	else:
		p2_index = _wrap_index(p2_index + direction)

func confirm_selection() -> void:
	if mode == Mode.DERBY:
		derby_selection_confirmed.emit(fighter_ids[p1_index])
		return
	var p1 := fighter_ids[p1_index]
	var p2 := fighter_ids[p2_index]
	if p1 == p2 and fighter_ids.size() > 1:
		p2_index = _wrap_index(p2_index + 1)
		p2 = fighter_ids[p2_index]
	battle_selection_confirmed.emit(p1, p2)

func get_current_selection(player: FighterInput.PlayerSlot) -> String:
	if fighter_ids.is_empty():
		return ""
	return fighter_ids[p1_index] if player == FighterInput.PlayerSlot.P1 else fighter_ids[p2_index]

func _wrap_index(value: int) -> int:
	if fighter_ids.is_empty():
		return 0
	return posmod(value, fighter_ids.size())
