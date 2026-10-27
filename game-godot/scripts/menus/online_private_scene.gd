extends "res://scripts/ui/console_menu_base.gd"
## Direct trusted-LAN host-authoritative match with guest presentation.
## Prediction/rollback remain unfinished; no guest-local damage authority.
var _status: Label
var _address: LineEdit
var _start: Button
var _fighter_pick: OptionButton
var _body_pick: OptionButton
var _apply_pick: Button
var _choices: Array = []

func _ready() -> void:
	super._ready()
	title_label.text = "Direct LAN (development)"
	var box := get_node("LobbyScroll/VBox")
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(520, 165)
	_status.text = "One host-authoritative BattleScene with synchronized guest presentation. Trusted LAN only. Prediction, rollback and reconnect remain unfinished."
	box.add_child(_status)
	_address = LineEdit.new()
	_address.placeholder_text = "Host LAN address; UDP 27834"
	_address.text = "127.0.0.1"
	box.add_child(_address)
	var pick_label := Label.new()
	pick_label.text = "Your fighter · host=P1 / guest=P2 · signed unlocks apply"
	box.add_child(pick_label)
	_fighter_pick = OptionButton.new()
	_choices = GameState.selectable_roster_ids(false)
	for id in _choices:
		_fighter_pick.add_item(str(GameState.load_fighter(str(id)).get("displayName", id)))
	if GameState.p1_fighter_id in _choices: _fighter_pick.select(_choices.find(GameState.p1_fighter_id))
	box.add_child(_fighter_pick)
	_body_pick = OptionButton.new()
	_body_pick.add_item("Male presentation"); _body_pick.add_item("Female presentation")
	_body_pick.select(1 if GameState.p1_body_variant == "female" else 0)
	box.add_child(_body_pick)
	_apply_pick = Button.new(); _apply_pick.text = "Apply your fighter / body"
	_apply_pick.pressed.connect(_choose_fighter)
	box.add_child(_apply_pick)
	for item in [["Host direct LAN", _host], ["Join direct LAN", _join], ["Back", on_back]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(420, 48)
		button.pressed.connect(item[1])
		box.add_child(button)
	_start = Button.new()
	_start.text = "Start host BattleScene"
	_start.custom_minimum_size = Vector2(420, 48)
	_start.pressed.connect(_start_match)
	box.add_child(_start)
	focus_default()

func _host() -> void:
	var error := LanSession.host()
	_status.text = LanSession.status if error == OK else "Listen failed: " + error_string(error)
	if error == OK: _choose_fighter()

func _join() -> void:
	var error := LanSession.join(_address.text.strip_edges())
	_status.text = LanSession.status if error == OK else "Connect failed: " + error_string(error)
	if error == OK: _choose_fighter()

func _choose_fighter() -> void:
	if _fighter_pick.selected < 0: return
	var id := str(_choices[_fighter_pick.selected])
	if not LanSession.select_local_fighter(id, "female" if _body_pick.selected == 1 else "male"):
		LanSession.status = "Host/join first. Selections lock when the match starts."
		_status.text = LanSession.status

func _start_match() -> void:
	if not LanSession.start_match():
		LanSession.status = "Choose unlocked fighters and wait for the guest's confirmed selection."

func _process(_delta: float) -> void:
	if _start == null: return
	_start.disabled = LanSession.role != "host" or not LanSession.guest_pick_ready or LanSession._bound_once or LanSession._starting
	_apply_pick.disabled = LanSession.role.is_empty() or LanSession._bound_once or LanSession._starting
	if LanSession.role.is_empty(): return
	_status.text = LanSession.status
	if not LanSession.lobby_state.is_empty():
		var lobby: Dictionary = LanSession.lobby_state
		_status.text += "\nP1 %s (%s) · P2 %s (%s)%s" % [lobby.p1.fighter, lobby.p1.body, lobby.p2.fighter, lobby.p2.body, " · guest choice confirmed" if lobby.guest_ready else " · waiting for guest choice"]
	if LanSession.role == "guest" and LanSession.latest.has("actors"):
		for actor in LanSession.latest.actors:
			_status.text += "\nP%d %s (%s): %.1f%% | shield %.1f/%.1f | aura %.1f | %s" % [actor.slot, actor.fighter, actor.body, actor.damage, actor.shield, actor.shield_max, actor.aura, actor.state]

func on_back() -> void:
	LanSession.stop()
	SceneRouter.go("mode_select")
