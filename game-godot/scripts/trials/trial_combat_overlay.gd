extends CanvasLayer
## Shared Trials combat overlay mounted on BattleScene — mode chrome only.
## Does not own fighter combat authority.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Presentation = preload("res://scripts/trials/mode_presentation.gd")

var _root: Control
var _banner: Label
var _detail: Label
var _territory: HBoxContainer
var _state: Dictionary = {}


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	if _state.is_empty() and not GameState.trial_overlay_state.is_empty():
		configure(GameState.trial_overlay_state)


func configure(state: Dictionary) -> void:
	_state = state.duplicate(true) if not state.is_empty() else {}
	if _banner == null:
		return
	_refresh()


func _build() -> void:
	_root = Control.new()
	_root.name = "OverlayRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_banner = Label.new()
	_banner.name = "TrialBanner"
	_banner.position = Vector2(24, 12)
	_banner.size = Vector2(720, 36)
	_banner.add_theme_font_size_override("font_size", 18)
	_root.add_child(_banner)

	_detail = Label.new()
	_detail.name = "TrialDetail"
	_detail.position = Vector2(24, 48)
	_detail.size = Vector2(720, 120)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 14)
	_root.add_child(_detail)

	_territory = HBoxContainer.new()
	_territory.name = "TerritoryStrip"
	_territory.position = Vector2(24, 170)
	_territory.custom_minimum_size = Vector2(640, 28)
	_territory.add_theme_constant_override("separation", 6)
	_root.add_child(_territory)


func _refresh() -> void:
	var lines: PackedStringArray = Bridge.overlay_hud_lines(_state)
	_banner.text = lines[0] if lines.size() > 0 else "TRIAL"
	_detail.text = "\n".join(lines.slice(1)) if lines.size() > 1 else ""
	_rebuild_territory()
	_draw_mode_chrome()


func _rebuild_territory() -> void:
	for c in _territory.get_children():
		c.queue_free()
	var mode_id: String = str(_state.get("mode_id", GameState.trial_mode_id))
	if mode_id != "fractured_accord":
		_territory.visible = false
		return
	_territory.visible = true
	var presentation: Dictionary = _state.get("presentation", {})
	var rooms: Array = []
	for el in presentation.get("elements", []):
		if typeof(el) == TYPE_DICTIONARY and str(el.get("id", "")) == "territory_strip":
			rooms = el.get("rooms", [])
			break
	if rooms.is_empty():
		var fb: Dictionary = Presentation.flagline_territory(GameState.match_seed, 0)
		for el in fb.get("elements", []):
			if str(el.get("id", "")) == "territory_strip":
				rooms = el.get("rooms", [])
	for room in rooms:
		if typeof(room) != TYPE_DICTIONARY:
			continue
		var panel := ColorRect.new()
		panel.custom_minimum_size = Vector2(108, 26)
		panel.color = room.get("fill", Color(0.4, 0.4, 0.45))
		if bool(room.get("active", false)):
			panel.color = panel.color.lightened(0.25)
		var lab := Label.new()
		lab.text = str(room.get("name", ""))
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lab.add_theme_font_size_override("font_size", 10)
		panel.add_child(lab)
		_territory.add_child(panel)


func _draw_mode_chrome() -> void:
	## Lightweight procedural chrome for derby dummy marker / prism hint / unbound label.
	var mode_id: String = str(_state.get("mode_id", GameState.trial_mode_id))
	var old := _root.get_node_or_null("ModeChrome")
	if old:
		old.queue_free()
	var chrome := Control.new()
	chrome.name = "ModeChrome"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(chrome)
	match mode_id:
		"resonance_trial":
			var dummy := ColorRect.new()
			dummy.position = Vector2(980, 620)
			dummy.size = Vector2(48, 96)
			dummy.color = Color(0.72, 0.74, 0.78, 0.55)
			chrome.add_child(dummy)
			var bat := ColorRect.new()
			bat.position = Vector2(1040, 650)
			bat.size = Vector2(64, 12)
			bat.color = Color(0.95, 0.62, 0.18, 0.7)
			chrome.add_child(bat)
		"prism_weave":
			for i in range(8):
				var tile := ColorRect.new()
				tile.position = Vector2(24 + i * 22, 210)
				tile.size = Vector2(18, 18)
				tile.color = Color(0.45 + i * 0.05, 0.55, 0.85, 0.5)
				chrome.add_child(tile)
		"riftline_defense":
			for i in range(4):
				var lane := ColorRect.new()
				lane.position = Vector2(900, 200 + i * 70)
				lane.size = Vector2(280, 4)
				lane.color = Color(0.4, 0.85, 0.7, 0.45)
				chrome.add_child(lane)
		"echoes_gauntlet":
			var echo := ColorRect.new()
			echo.position = Vector2(1100, 180)
			echo.size = Vector2(40, 40)
			echo.color = Color(0.55, 0.35, 0.75, 0.4)
			chrome.add_child(echo)
		"convergence_unbound":
			var stamp := Label.new()
			stamp.position = Vector2(24, 220)
			stamp.size = Vector2(400, 28)
			stamp.text = "COLOSSUS / MYTHIC SCAFFOLD · art unapproved"
			stamp.add_theme_font_size_override("font_size", 12)
			chrome.add_child(stamp)
