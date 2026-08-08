extends "res://scripts/ui/console_menu_base.gd"

## Team stocks mode entry (2v2 ruleset digitally represented as team-attack stocks bout).

@onready var status_label: Label = get_node_or_null("%Status") as Label


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Team Mode"
	_ensure_ui()
	_refresh()


func _ensure_ui() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	if vbox.get_node_or_null("Status") == null:
		var s := Label.new()
		s.name = "Status"
		s.unique_name_in_owner = true
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size = Vector2(420, 100)
		vbox.add_child(s)
		status_label = s
	if vbox.get_node_or_null("StartBtn") == null:
		var start := Button.new()
		start.name = "StartBtn"
		start.text = "Start Team Bout"
		start.custom_minimum_size = Vector2(280, 64)
		start.pressed.connect(_on_start)
		vbox.add_child(start)
		var back := Button.new()
		back.name = "BackBtn"
		back.text = "Back"
		back.custom_minimum_size = Vector2(280, 56)
		back.pressed.connect(on_back)
		vbox.add_child(back)


func _refresh() -> void:
	if status_label:
		status_label.text = "2v2 stocks ruleset (team_attack toggle in Ruleset).\nP1 human vs CPU ally-pressure bout.\nGeometry: PROCEDURAL_FINAL launch stages."


func _on_start() -> void:
	GameState.begin_team_mode()
	SceneRouter.go("ruleset")


func on_back() -> void:
	GameState.team_mode = false
	GameState.mode = "versus"
	SceneRouter.go("mode_select")
