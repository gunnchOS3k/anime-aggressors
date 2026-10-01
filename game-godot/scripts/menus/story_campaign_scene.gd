extends "res://scripts/ui/console_menu_base.gd"

const _Campaign = preload("res://scripts/story/green_between_campaign.gd")

var _progress: Dictionary = {}
var _status: Label
var _body: Label


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "The Green Between"
	_progress = _Campaign.load_progress()
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var host := VBoxContainer.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.offset_left = 48
	host.offset_top = 36
	host.offset_right = -48
	host.offset_bottom = -36
	host.add_theme_constant_override("separation", 12)
	add_child(host)
	var epithet := Label.new()
	epithet.text = "Kaia Windrow — The Skyflow Duelist"
	host.add_child(epithet)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.add_child(_status)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.add_child(_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	host.add_child(row)
	_button(row, "New Game", _on_new_game)
	_button(row, "Continue", _on_continue)
	_button(row, "Advance", _on_advance)
	_button(row, "Back", _on_back_pressed)


func _button(row: Node, label: String, handler: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(160, 48)
	button.pressed.connect(handler)
	row.add_child(button)


func _refresh() -> void:
	var list: Array = _Campaign.nodes()
	var index := clampi(int(_progress.get("node_index", 0)), 0, maxi(list.size() - 1, 0))
	var node: Dictionary = list[index] if not list.is_empty() else {}
	_status.text = "Node %d/%d — %s\nEssence %s · Rook First Loss %s · Story Yin/Yang locked" % [
		index + 1,
		list.size(),
		str(node.get("title", "")),
		str(_progress.get("essence", 0)),
		"canonical" if bool(_progress.get("rook_first_loss_canonical", false)) else "not yet",
	]
	_body.text = str(node.get("body", "DRAFT_NARRATIVE_COPY"))


func _on_new_game() -> void:
	_progress = _Campaign.new_progress()
	_Campaign.save_progress(_progress)
	_refresh()


func _on_continue() -> void:
	_progress = _Campaign.load_progress()
	_refresh()


func _on_advance() -> void:
	_progress = _Campaign.advance(_progress)
	_Campaign.save_progress(_progress)
	_refresh()


func _on_back_pressed() -> void:
	SceneRouter.go("main_menu")
