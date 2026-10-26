extends "res://scripts/ui/console_menu_base.gd"
## Direct trusted-LAN host-authoritative input bridge. Guest rendering/rollback
## remain unfinished; the guest status view is explicitly not a battle view.
var _status: Label
var _address: LineEdit
var _start: Button

func _ready() -> void:
	super._ready()
	title_label.text = "Direct LAN (development)"
	var box := get_node("VBox")
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(520, 165)
	_status.text = "One host BattleScene + one remote guest input seat. Trusted LAN only. Guest battle rendering and combat rollback remain unfinished."
	box.add_child(_status)
	_address = LineEdit.new()
	_address.placeholder_text = "Host LAN address; UDP 27834"
	_address.text = "127.0.0.1"
	box.add_child(_address)
	for item in [["Host direct LAN", _host], ["Join direct LAN", _join], ["Back", on_back]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(420, 48)
		button.pressed.connect(item[1])
		box.add_child(button)
	_start = Button.new()
	_start.text = "Start host BattleScene"
	_start.custom_minimum_size = Vector2(420, 48)
	_start.pressed.connect(func(): LanSession.start_match())
	box.add_child(_start)
	focus_default()

func _host() -> void:
	var error := LanSession.host()
	_status.text = LanSession.status if error == OK else "Listen failed: " + error_string(error)

func _join() -> void:
	var error := LanSession.join(_address.text.strip_edges())
	_status.text = LanSession.status if error == OK else "Connect failed: " + error_string(error)

func _process(_delta: float) -> void:
	if _start == null: return
	_start.disabled = LanSession.role != "host" or LanSession.guest_id == 0 or LanSession._bound_once
	if LanSession.role.is_empty(): return
	_status.text = LanSession.status
	if LanSession.role == "guest" and LanSession.latest.has("actors"):
		for actor in LanSession.latest.actors:
			_status.text += "\nP%d %s (%s): %.1f%% | shield %.1f/%.1f | aura %.1f | %s" % [actor.slot, actor.fighter, actor.body, actor.damage, actor.shield, actor.shield_max, actor.aura, actor.state]

func on_back() -> void:
	LanSession.stop()
	SceneRouter.go("mode_select")
