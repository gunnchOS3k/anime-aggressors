extends CanvasLayer
## Shared Trials combat overlay mounted on BattleScene — mode chrome + live sim tick.
## Does not own fighter combat authority. Advances mode sims from real actor positions.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Presentation = preload("res://scripts/trials/mode_presentation.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const ResonanceDummy = preload("res://scripts/trials/derby/resonance_dummy_actor.gd")

var _root: Control
var _banner: Label
var _detail: Label
var _territory: HBoxContainer
var _state: Dictionary = {}
var _battle: Node = null
var _tick_accum: float = 0.0
const TICK_HZ := 60.0


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


func bind_battle(battle: Node) -> void:
	_battle = battle


func _process(delta: float) -> void:
	if _battle == null or not bool(GameState.trial_live_combat):
		return
	_tick_accum += delta
	var step_dt: float = 1.0 / TICK_HZ
	while _tick_accum >= step_dt:
		_tick_accum -= step_dt
		var live: Dictionary = Bridge.tick_live_from_battle(_battle)
		if not live.is_empty():
			_state["live"] = live
			GameState.trial_overlay_state["live"] = live
			_refresh_detail_only()


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
	_detail.size = Vector2(720, 140)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 14)
	_root.add_child(_detail)

	_territory = HBoxContainer.new()
	_territory.name = "TerritoryStrip"
	_territory.position = Vector2(24, 190)
	_territory.custom_minimum_size = Vector2(640, 28)
	_territory.add_theme_constant_override("separation", 6)
	_root.add_child(_territory)


func _refresh() -> void:
	var lines: PackedStringArray = Bridge.overlay_hud_lines(_state)
	_banner.text = lines[0] if lines.size() > 0 else "TRIAL"
	_detail.text = "\n".join(lines.slice(1)) if lines.size() > 1 else ""
	_rebuild_territory()
	_draw_mode_chrome()


func _refresh_detail_only() -> void:
	var lines: PackedStringArray = Bridge.overlay_hud_lines(_state)
	if _banner:
		_banner.text = lines[0] if lines.size() > 0 else "TRIAL"
	if _detail:
		_detail.text = "\n".join(lines.slice(1)) if lines.size() > 1 else ""
	_rebuild_territory()


func _rebuild_territory() -> void:
	for c in _territory.get_children():
		c.queue_free()
	var mode_id: String = str(_state.get("mode_id", GameState.trial_mode_id))
	if mode_id != "fractured_accord":
		_territory.visible = false
		return
	_territory.visible = true
	var snap: Dictionary = GameState.trial_sim_snapshot
	var current_room: int = int(snap.get("current_room", 0))
	var presentation: Dictionary = _state.get("presentation", {})
	var rooms: Array = []
	for el in presentation.get("elements", []):
		if typeof(el) == TYPE_DICTIONARY and str(el.get("id", "")) == "territory_strip":
			rooms = el.get("rooms", [])
			break
	if rooms.is_empty():
		var fb: Dictionary = Presentation.flagline_territory(GameState.match_seed, current_room)
		for el in fb.get("elements", []):
			if str(el.get("id", "")) == "territory_strip":
				rooms = el.get("rooms", [])
	for room in rooms:
		if typeof(room) != TYPE_DICTIONARY:
			continue
		var panel := ColorRect.new()
		panel.custom_minimum_size = Vector2(108, 26)
		panel.color = room.get("fill", Color(0.4, 0.4, 0.45))
		var active: bool = int(room.get("room_index", 999)) == current_room or bool(room.get("active", false))
		if active:
			panel.color = panel.color.lightened(0.25)
		var lab := Label.new()
		lab.text = str(room.get("name", ""))
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lab.add_theme_font_size_override("font_size", 10)
		panel.add_child(lab)
		_territory.add_child(panel)
	## Capture occupancy meters — real actors, not HUD strip alone.
	var occ: Dictionary = Flagline.occupancy_summary(snap) if not snap.is_empty() else {}
	if not occ.is_empty() and _detail:
		_detail.text += "\nCapture B%.0f / V%.0f · contested=%s · actors=%d" % [
			float(occ.get("solar_capture", 0.0)), float(occ.get("lunar_capture", 0.0)),
			str(occ.get("contested", false)), int(occ.get("actor_count", 0)),
		]


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
			var body: Dictionary = ResonanceDummy.body_profile()
			var dummy := ColorRect.new()
			dummy.position = Vector2(980, 620)
			dummy.size = Vector2(float(body.get("radius_px", 28)) * 2.0, float(body.get("height_px", 96)))
			dummy.color = body.get("color", Color(0.72, 0.74, 0.78, 0.55))
			chrome.add_child(dummy)
			var bat := ColorRect.new()
			bat.position = Vector2(1040, 650)
			bat.size = Vector2(64, 12)
			bat.color = Color(0.95, 0.62, 0.18, 0.7)
			chrome.add_child(bat)
			var tag := Label.new()
			tag.position = Vector2(970, 590)
			tag.text = ResonanceDummy.DISPLAY_NAME
			tag.add_theme_font_size_override("font_size", 11)
			chrome.add_child(tag)
		"prism_weave":
			for i in range(8):
				var tile := ColorRect.new()
				tile.position = Vector2(24 + i * 22, 230)
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
			stamp.position = Vector2(24, 240)
			stamp.size = Vector2(480, 28)
			stamp.text = "COLOSSUS / PRISMATIC / PUPPET · controllable · art unapproved"
			stamp.add_theme_font_size_override("font_size", 12)
			chrome.add_child(stamp)
		"fractured_accord":
			var core := ColorRect.new()
			core.position = Vector2(880, 480)
			core.size = Vector2(160, 160)
			core.color = Color(0.35, 0.55, 0.85, 0.18)
			chrome.add_child(core)
			var core_lab := Label.new()
			core_lab.position = Vector2(900, 540)
			core_lab.text = "CORE"
			core_lab.add_theme_font_size_override("font_size", 12)
			chrome.add_child(core_lab)
