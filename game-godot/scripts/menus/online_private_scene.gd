extends "res://scripts/ui/console_menu_base.gd"

## Private loopback netplay lobby UI (Alpha). No public matchmaking deploy.

const _PrivateNetplayStack = preload("res://scripts/net/private_netplay_stack.gd")
const _MatchmakingDev = preload("res://scripts/net/matchmaking_dev.gd")
const _AntiTamper = preload("res://scripts/net/anti_tamper.gd")

var _status: Label
var _stack
var _room_code: String = ""

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Private Netplay"
	_build_ui()

func _build_ui() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "VBox"
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.position = Vector2(420, 160)
		add_child(vbox)
		var title := Label.new()
		title.name = "Title"
		title.unique_name_in_owner = true
		title.text = "Private Netplay"
		title.add_theme_font_size_override("font_size", 32)
		vbox.add_child(title)
	_status = vbox.get_node_or_null("Status") as Label
	if _status == null:
		_status = Label.new()
		_status.name = "Status"
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_status.custom_minimum_size = Vector2(520, 120)
		vbox.add_child(_status)
	_status.text = "Loopback/private host only. Scope: %s\nBuild: %s" % [
		_PrivateNetplayStack.SCOPE,
		_AntiTamper.BUILD_ID,
	]
	if vbox.get_node_or_null("HostBtn") == null:
		for item in [
			["HostBtn", "Host Private Room", _on_host],
			["JoinBtn", "Join / DEV Matchmake", _on_join],
			["SpecBtn", "Add Spectator", _on_spec],
			["SimBtn", "Simulate Digital Pass (headless logic)", _on_sim],
			["BackBtn", "Back", on_back],
		]:
			var b := Button.new()
			b.name = item[0]
			b.text = item[1]
			b.custom_minimum_size = Vector2(420, 56)
			b.pressed.connect(item[2])
			vbox.add_child(b)

func _on_host() -> void:
	_stack = _PrivateNetplayStack.new()
	var r: Dictionary = _stack.host_create_room("LocalHost")
	_room_code = str(r.get("room_code", ""))
	_status.text = "Hosted room %s (private loopback). Waiting for join." % _room_code

func _on_join() -> void:
	if _stack == null:
		_on_host()
	var j: Dictionary = _stack.guest_join("LocalGuest", _room_code)
	if bool(j.get("ok", false)):
		_stack.ready_and_start(GameState.match_seed if GameState.match_seed != 0 else 42, GameState.stage_id)
		_status.text = "Joined %s — match syncing (private). Use Simulate for full digital pass." % _room_code
	else:
		# DEV matchmaking fallback
		var mm = _MatchmakingDev.new()
		mm.reset()
		mm.enqueue_matchmaking("QueueA")
		var paired: Dictionary = mm.enqueue_matchmaking("QueueB")
		_status.text = "DEV matchmaking: %s" % str(paired)

func _on_spec() -> void:
	if _stack == null:
		_status.text = "Host a room first."
		return
	var s: Dictionary = _stack.add_spectator("LocalSpec")
	_status.text = "Spectator added: %s" % str(s)

func _on_sim() -> void:
	_status.text = "Running private netplay digital pass…"
	var evidence: Dictionary = _PrivateNetplayStack.digital_pass_self_test()
	_status.text = "Digital pass ok=%s token=%s features=%d" % [
		str(evidence.get("ok")),
		str(evidence.get("token")),
		int(evidence.get("features", []).size()) if typeof(evidence.get("features")) == TYPE_ARRAY else 0,
	]
	# Persist evidence snapshot
	var path := "user://private_netplay_digital_pass.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(evidence, "\t"))
		f.close()

func on_back() -> void:
	SceneRouter.go("mode_select")
