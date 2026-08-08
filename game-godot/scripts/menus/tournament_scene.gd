extends "res://scripts/ui/console_menu_base.gd"

## Tournament rooms (private/dev).

const _TournamentRooms = preload("res://scripts/net/tournament_rooms.gd")

var _status: Label
var _rooms
var _code: String = ""


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Tournament Rooms"
	_rooms = _TournamentRooms.new()
	_build()


func _build() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(480, 120)
	_status.text = "Private/dev tournament rooms — create, join, spectator, seed bracket."
	vbox.add_child(_status)
	for item in [
		["CreateBtn", "Create Room (4)", _on_create],
		["FillBtn", "Fill + Seed Bracket", _on_fill_seed],
		["SpecBtn", "Add Spectator", _on_spec],
		["SelfTestBtn", "Self-Test", _on_self_test],
		["BackBtn", "Back", on_back],
	]:
		var b := Button.new()
		b.name = item[0]
		b.text = item[1]
		b.custom_minimum_size = Vector2(420, 52)
		b.pressed.connect(item[2])
		vbox.add_child(b)


func _on_create() -> void:
	GameState.begin_online_queue("tournament")
	var r: Dictionary = _rooms.create_room("HostLocal", 4)
	_code = str(r.get("room", {}).get("code", ""))
	_status.text = "Created %s" % _code


func _on_fill_seed() -> void:
	if _code == "":
		_on_create()
	_rooms.join_player(_code, "P2")
	_rooms.join_player(_code, "P3")
	_rooms.join_player(_code, "P4")
	var seeded: Dictionary = _rooms.seed_bracket(_code)
	_status.text = "Seeded matches: %s" % str(seeded.get("matches"))


func _on_spec() -> void:
	if _code == "":
		_on_create()
	var s: Dictionary = _rooms.add_spectator(_code, "TourSpec")
	_status.text = "Spectators: %s" % str(s.get("spectators"))


func _on_self_test() -> void:
	var r: Dictionary = _TournamentRooms.digital_self_test()
	_status.text = "Tournament self-test ok=%s matches=%d" % [
		str(r.get("ok")), int(r.get("matches", []).size()),
	]


func on_back() -> void:
	SceneRouter.go("mode_select")
