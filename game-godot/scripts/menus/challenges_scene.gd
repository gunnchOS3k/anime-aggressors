extends "res://scripts/ui/console_menu_base.gd"

## Challenge set selector — timed/stock/damage objectives.

var _index: int = 0
var _status: Label


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Challenges"
	_build()


func _build() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(440, 120)
	vbox.add_child(_status)
	for item in [
		["PrevBtn", "Previous", _on_prev],
		["NextBtn", "Next", _on_next],
		["StartBtn", "Start Challenge", _on_start],
		["BackBtn", "Back", on_back],
	]:
		var b := Button.new()
		b.name = item[0]
		b.text = item[1]
		b.custom_minimum_size = Vector2(280, 56)
		b.pressed.connect(item[2])
		vbox.add_child(b)
	_refresh()


func _refresh() -> void:
	var c: Dictionary = GameState.CHALLENGES[_index]
	_status.text = "%s\nObjective: %s  target=%s  time=%ss\nStage: %s" % [
		str(c.name), str(c.objective), str(c.target), str(c.time), str(c.stage),
	]


func _on_prev() -> void:
	_index = (_index - 1 + GameState.CHALLENGES.size()) % GameState.CHALLENGES.size()
	_refresh()


func _on_next() -> void:
	_index = (_index + 1) % GameState.CHALLENGES.size()
	_refresh()


func _on_start() -> void:
	GameState.begin_challenge(_index)
	SceneRouter.go("versus")


func on_back() -> void:
	GameState.mode = "versus"
	SceneRouter.go("mode_select")
