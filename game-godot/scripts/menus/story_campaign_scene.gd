extends "res://scripts/ui/console_menu_base.gd"

signal _scene_settled

var _status: Label
var _body: Label
var _route_picker: OptionButton
var _replay_picker: OptionButton
var _action: Button
var _back_button: Button
var _stop_scene: Button
var _chapter_controls: Array[BaseButton] = []
var _scene_pending := false
var _scene_request := 0
var _scene_notice := ""
var _scene_replay: AcceptDialog
var _replay_generation := -1


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
	_chapter_controls.append(_route_picker)
	for route in CampaignRuntime.campaign.get("routes", []):
		_route_picker.add_item(str(route["title"]))
		var index := _route_picker.item_count - 1
		_route_picker.set_item_metadata(index, str(route["id"]))
		_route_picker.set_item_disabled(index, not CampaignRuntime.route_available(str(route["id"])))
	_route_picker.item_selected.connect(func(index: int):
		if _scene_pending: return
		_scene_notice = ""
		CampaignRuntime.select_route(str(_route_picker.get_item_metadata(index)))
		_refresh())
	host.add_child(_route_picker)
	var presentation := OptionButton.new()
	_chapter_controls.append(presentation)
	presentation.add_item("Female presentation")
	presentation.add_item("Male presentation")
	presentation.select(1 if CampaignRuntime.progress["presentation"] == "male" else 0)
	presentation.item_selected.connect(func(index: int):
		if _scene_pending: return
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
	_back_button = _button(row, "Back", on_back)
	_stop_scene = _button(row, "Stop Scene", _on_stop_scene)
	_replay_picker = OptionButton.new()
	_chapter_controls.append(_replay_picker)
	_replay_picker.name = "ChapterReplayPicker"
	host.add_child(_replay_picker)
	_button(host, "Replay Selected Encounter", _on_replay)
	var watch_row := HBoxContainer.new()
	host.add_child(watch_row)
	var watch_picker := OptionButton.new()
	_chapter_controls.append(watch_picker)
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
		if _scene_pending: return
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
	_chapter_controls.append(button)
	return button


func _refresh() -> void:
	for control in _chapter_controls:
		if control != _back_button and control != _stop_scene:
			control.disabled = _scene_pending
	_stop_scene.visible = _scene_pending
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
	if not _scene_notice.is_empty(): _body.text += "\n" + _scene_notice
	if not CampaignRuntime.last_error.is_empty():
		_body.text += "\n" + CampaignRuntime.last_error
	_action.disabled = _scene_pending or node.is_empty() or not bool(node.get("implemented", false))
	if entry["complete"]:
		_status.text = "Route complete · Six perspectives integrated"
		_body.text = "Choose another Prismatic Route." if id != "sevenfold-convergence" else "Sevenfold Convergence complete. Yin and Yang are playable."
		if not entry.get("earned", false): _body.text = "Review run complete. Earned Story unlocks require ordinary playable encounters."
	_action.text = "Continue Scene" if node.get("kind") == "INTERACTIVE_DIALOGUE" else "Play Encounter"
	_replay_picker.clear()
	for chapter in route.get("nodes", []):
		if str(chapter["id"]) in entry["completed"]:
			_replay_picker.add_item(str(chapter["title"]))
			_replay_picker.set_item_metadata(_replay_picker.item_count - 1, str(chapter["id"]))
	_replay_picker.disabled = _scene_pending or _replay_picker.item_count == 0


func _on_new_game() -> void:
	if _scene_pending: return
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = "Start a new campaign? This replaces saved Story progress."
	confirm.confirmed.connect(func():
		if _scene_pending: return
		CampaignRuntime.reset_campaign()
		_refresh())
	confirm.visibility_changed.connect(func():
		if not confirm.visible:
			confirm.queue_free())
	add_child(confirm)
	confirm.popup_centered()


func _on_continue() -> void:
	if _scene_pending: return
	CampaignRuntime.load_progress()
	_refresh()


func _on_action() -> void:
	if _scene_pending or _action.disabled: return
	_scene_notice = ""
	if CampaignRuntime.current_node().get("kind") == "INTERACTIVE_DIALOGUE":
		var route_id: String = CampaignRuntime.progress["selected_route"]
		var node_id: String = CampaignRuntime.current_node()["id"]
		_scene_request += 1
		var request := _scene_request
		_scene_pending = true
		_refresh()
		StoryDialogue.begin(node_id,"scene")
		var generation: int = StoryDialogue._generation
		for event in ["scene_start","scene_turn","scene_resolution"]: StoryDialogue.fire(event)
		if StoryDialogue.is_busy():
			StoryDialogue.sequence_finished.connect(_on_scene_sequence_finished)
			await _scene_settled
			if StoryDialogue.sequence_finished.is_connected(_on_scene_sequence_finished):
				StoryDialogue.sequence_finished.disconnect(_on_scene_sequence_finished)
		if request != _scene_request or not is_inside_tree(): return
		_scene_pending = false
		if generation == StoryDialogue._generation:
			CampaignRuntime.acknowledge_scene(node_id, route_id)
		_refresh()
	elif CampaignRuntime.begin_encounter():
		SceneRouter.go("battle")
	else:
		_refresh()


func _on_replay() -> void:
	if _scene_pending: return
	if _replay_picker.item_count == 0: return
	var selected := str(_replay_picker.get_item_metadata(_replay_picker.selected))
	for chapter in CampaignRuntime.route_data(str(CampaignRuntime.progress["selected_route"]))["nodes"]:
		if chapter["id"] == selected and chapter["kind"] == "INTERACTIVE_DIALOGUE":
			var review := AcceptDialog.new()
			review.name = "StorySceneReplay"
			review.title = str(chapter["title"]) + " · Draft Story replay"
			review.dialog_text = "Read-only draft transcript. Dialogue plays with the subtitle controls."
			var scroll := ScrollContainer.new(); scroll.custom_minimum_size=Vector2(880,360)
			var transcript := Label.new(); transcript.text=StoryDialogue.transcript(selected)
			transcript.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;transcript.custom_minimum_size.x=840
			transcript.add_theme_font_size_override("font_size",23)
			scroll.add_child(transcript);review.add_child(scroll)
			StoryDialogue.begin(selected,"replay")
			for event in ["scene_start","scene_turn","scene_resolution"]: StoryDialogue.fire(event)
			_scene_replay = review
			_replay_generation = StoryDialogue._generation
			_scene_pending = true
			# Replay owns its presentation only. It cannot acknowledge a chapter
			# or leave a stale close callback able to cancel the next scene.
			review.confirmed.connect(_close_scene_replay.bind(review, _replay_generation))
			review.canceled.connect(_close_scene_replay.bind(review, _replay_generation))
			add_child(review)
			_refresh()
			review.popup_centered(Vector2i(960, 450))
			return # Presentation only: no acknowledgment, receipt or save write.
	if CampaignRuntime.begin_encounter(selected):
		SceneRouter.go("battle")


func on_back() -> void:
	_discard_scene_replay()
	_scene_request += 1
	_scene_pending = false
	StoryDialogue.cancel()
	_scene_settled.emit()
	CampaignRuntime.abandon_encounter()
	SceneRouter.go("main_menu")


func _on_next_route() -> void:
	if _scene_pending: return
	var id := CampaignRuntime.next_incomplete_route_id()
	if id.is_empty():
		return
	CampaignRuntime.select_route(id)
	_refresh()


func _on_stop_scene() -> void:
	if not _scene_pending: return
	if is_instance_valid(_scene_replay):
		_close_scene_replay(_scene_replay, _replay_generation)
		return
	_scene_request += 1
	_scene_pending = false
	StoryDialogue.cancel()
	_scene_settled.emit()
	_scene_notice = "Scene stopped. Continue Scene restarts it from the beginning."
	_refresh()
	_action.grab_focus()


func _exit_tree() -> void:
	_discard_scene_replay()
	if _scene_pending:
		_scene_request += 1
		_scene_pending = false
		StoryDialogue.cancel()
		_scene_settled.emit()


func _on_scene_sequence_finished() -> void:
	_scene_settled.emit()


func _close_scene_replay(review: AcceptDialog, generation: int) -> void:
	if review != _scene_replay: return
	_scene_replay = null
	_replay_generation = -1
	if generation == StoryDialogue._generation: StoryDialogue.cancel()
	if is_instance_valid(review): review.queue_free()
	_scene_pending = false
	_scene_notice = "Read-only replay closed. Story progress is unchanged."
	if is_inside_tree():
		_refresh()
		_action.grab_focus()


func _discard_scene_replay() -> void:
	# Called before route teardown; any queued dialog callback is now stale.
	var review := _scene_replay
	_scene_replay = null
	_replay_generation = -1
	if is_instance_valid(review): review.queue_free()
