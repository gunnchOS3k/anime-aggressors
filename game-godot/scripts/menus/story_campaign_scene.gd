extends "res://scripts/ui/console_menu_base.gd"

var _status: Label
var _body: Label
var _route_picker: OptionButton
var _replay_picker: OptionButton
var _action: Button


func _ready() -> void:
	super._ready()
	GameState.mode = "versus"
	_build_ui()
	_refresh()
	_action.grab_focus()


func _build_ui() -> void:
	var host := VBoxContainer.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.offset_left = 48
	host.offset_top = 64
	host.offset_right = -48
	host.offset_bottom = -48
	host.add_theme_constant_override("separation", 12)
	add_child(host)
	_route_picker = OptionButton.new()
	_route_picker.name = "RoutePicker"
	for route in CampaignRuntime.campaign.get("routes", []):
		_route_picker.add_item(str(route["title"]))
		var index := _route_picker.item_count - 1
		_route_picker.set_item_metadata(index, str(route["id"]))
		_route_picker.set_item_disabled(index, not CampaignRuntime.route_available(str(route["id"])))
	_route_picker.item_selected.connect(func(index: int):
		CampaignRuntime.select_route(str(_route_picker.get_item_metadata(index)))
		_refresh())
	host.add_child(_route_picker)
	var presentation := OptionButton.new()
	presentation.add_item("Female presentation")
	presentation.add_item("Male presentation")
	presentation.select(1 if CampaignRuntime.progress["presentation"] == "male" else 0)
	presentation.item_selected.connect(func(index: int):
		var previous: String = CampaignRuntime.progress["presentation"]
		CampaignRuntime.progress["presentation"] = "male" if index == 1 else "female"
		if not CampaignRuntime.save_progress():
			CampaignRuntime.progress["presentation"] = previous
		_refresh())
	host.add_child(presentation)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.add_child(_status)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.add_child(_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	host.add_child(row)
	_action = _button(row, "Play Encounter", _on_action)
	_button(row, "Resume Save", _on_continue)
	_button(row, "New Campaign", _on_new_game)
	_button(row, "Next Route", _on_next_route)
	_button(row, "Back", on_back)
	_replay_picker = OptionButton.new()
	_replay_picker.name = "ChapterReplayPicker"
	host.add_child(_replay_picker)
	_button(host, "Replay Selected Encounter", _on_replay)
	var watch_row := HBoxContainer.new()
	host.add_child(watch_row)
	var watch_picker := OptionButton.new()
	watch_picker.name = "CampaignVariationPicker"
	for route in CampaignRuntime.campaign.get("routes", []):
		if route.get("id") == "sevenfold-convergence":
			continue
		watch_picker.add_item(str(route["watch_title"]))
		watch_picker.set_item_metadata(watch_picker.item_count - 1, str(route["id"]))
		if route.get("id") == "kaia-windrow":
			watch_picker.select(watch_picker.item_count - 1)
	watch_row.add_child(watch_picker)
	_button(watch_row, "Watch Campaign Preview", func():
		CampaignRuntime.watch_route_id = str(watch_picker.get_item_metadata(watch_picker.selected))
		CampaignRuntime.watch_presentation = str(CampaignRuntime.progress["presentation"])
		SceneRouter.go("ova"))
	var notice := Label.new()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.text = "V1 candidate · Draft adaptation · Story and art await owner review."
	if CampaignRuntime.route_review_enabled():
		notice.text += "\nOpening routes are accessible for review; Gray and cosmic unlocks require completed campaigns."
	host.add_child(notice)


func _button(row: Node, text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(160, 48)
	button.pressed.connect(handler)
	row.add_child(button)
	return button


func _refresh() -> void:
	var id: String = CampaignRuntime.progress["selected_route"]
	var route: Dictionary = CampaignRuntime.route_data(id)
	var node: Dictionary = CampaignRuntime.current_node()
	if title_label:
		title_label.text = route.get("title", "Story")
	for index in range(_route_picker.item_count):
		var route_id := str(_route_picker.get_item_metadata(index))
		_route_picker.set_item_disabled(index, not CampaignRuntime.route_available(route_id))
		if route_id == id:
			_route_picker.select(index)
	var entry: Dictionary = CampaignRuntime.progress["routes"][id]
	_status.text = "%s\nChapters completed: %d · Allies recruited: %d · Essences: %d" % [
		node.get("title", ""), entry["completed"].size(), entry["recruited"].size(), entry["essence"]]
	_body.text = str(node.get("body", node.get("block_reason", "")))
	if not CampaignRuntime.last_error.is_empty():
		_body.text += "\n" + CampaignRuntime.last_error
	_action.disabled = node.is_empty() or not bool(node.get("implemented", false))
	if entry["complete"]:
		_status.text = "Route complete · Six perspectives integrated"
		_body.text = "Choose another Prismatic Route." if id != "sevenfold-convergence" else "Sevenfold Convergence complete. Yin and Yang are playable."
		if not entry.get("earned", false): _body.text = "Review run complete. Earned Story unlocks require ordinary playable encounters."
	_action.text = "Continue Scene" if node.get("kind") == "INTERACTIVE_DIALOGUE" else "Play Encounter"
	_replay_picker.clear()
	for chapter in route.get("nodes", []):
		if str(chapter["id"]) in entry["completed"] and chapter.get("kind") == "STORY_BATTLE":
			_replay_picker.add_item(str(chapter["title"]))
			_replay_picker.set_item_metadata(_replay_picker.item_count - 1, str(chapter["id"]))
	_replay_picker.disabled = _replay_picker.item_count == 0


func _on_new_game() -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Start a new campaign? This replaces saved Story progress."
	confirm.confirmed.connect(func():
		CampaignRuntime.reset_campaign()
		_refresh())
	confirm.visibility_changed.connect(func():
		if not confirm.visible:
			confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()


func _on_continue() -> void:
	CampaignRuntime.load_progress()
	_refresh()


func _on_action() -> void:
	if CampaignRuntime.current_node().get("kind") == "INTERACTIVE_DIALOGUE":
		CampaignRuntime.acknowledge_scene()
		_refresh()
	elif CampaignRuntime.begin_encounter():
		SceneRouter.go("battle")
	else:
		_refresh()


func _on_replay() -> void:
	if _replay_picker.item_count > 0 and CampaignRuntime.begin_encounter(str(_replay_picker.get_item_metadata(_replay_picker.selected))):
		SceneRouter.go("battle")


func on_back() -> void:
	CampaignRuntime.abandon_encounter()
	SceneRouter.go("main_menu")


func _on_next_route() -> void:
	for route in CampaignRuntime.campaign["routes"]:
		var id: String = route["id"]
		if CampaignRuntime.route_available(id) and not CampaignRuntime.progress["routes"][id]["complete"]:
			CampaignRuntime.select_route(id)
			_refresh()
			return
