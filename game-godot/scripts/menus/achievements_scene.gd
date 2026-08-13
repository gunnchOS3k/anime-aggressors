extends "res://scripts/ui/console_menu_base.gd"

## Achievement browser with completion percent. Hidden entries stay ??? until unlocked.

var _status: Label
var _list: VBoxContainer


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Achievements"
	_build()
	_refresh()


func _build() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "VBox"
		add_child(vbox)
	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 360)
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(280, 56)
	back.pressed.connect(on_back)
	vbox.add_child(back)


func _refresh() -> void:
	var runtime := get_node_or_null("/root/AchievementRuntime")
	if runtime == null:
		_status.text = "Achievement runtime unavailable."
		return
	_status.text = "Completion %.0f%%  •  %d / %d unlocked  •  offline save" % [
		float(runtime.completion_percent()),
		int(runtime.unlocked_count()),
		int(runtime.catalog_count()),
	]
	for child in _list.get_children():
		child.queue_free()
	for entry in runtime.browser_entries():
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var mark := "[x]" if bool(entry.get("unlocked", false)) else "[ ]"
		var when := str(entry.get("unlocked_at", ""))
		var stamp := ("  •  " + when) if not when.is_empty() else ""
		row.text = "%s %s  (%.0f%%)\n%s%s" % [
			mark,
			str(entry.get("title", "")),
			float(entry.get("percent", 0.0)),
			str(entry.get("description", "")),
			stamp,
		]
		_list.add_child(row)


func on_back() -> void:
	SceneRouter.go("main_menu")
