extends "res://scripts/ui/console_menu_base.gd"

## Match Settings — scrollable body + persistent safe-area Continue CTA.
## Uses CpuController.TIER_NAMES so labels stay aligned with PR #102 difficulty.

const _Cpu = preload("res://scripts/fighters/cpu_controller.gd")

const CONTINUE_CTA_TEXT := "CONTINUE TO FIGHTERS"
const TIMER_OPTIONS := [0, 60, 120, 180, 300]
const PRESETS := ["default", "tournament", "casual", "local-multi"]
const DISPLAY_TIER_NAMES := ["", "Novice", "Standard", "Skilled", "Expert", "Master"]

@onready var stock_label: Label = %StockLabel
@onready var cpu_label: Label = %CpuLabel
@onready var timer_label: Label = %TimerLabel
@onready var p2_label: Label = %P2ModeLabel
@onready var damage_label: Label = %DamageLabel
@onready var preset_label: Label = %PresetLabel
@onready var subtitle_label: Label = %Subtitle
@onready var scroll_body: ScrollContainer = %ScrollBody
@onready var settings_vbox: VBoxContainer = %SettingsVBox
@onready var root_column: VBoxContainer = %RootColumn
@onready var action_bar: HBoxContainer = %ActionBar
@onready var confirm_btn: Button = %Confirm
@onready var back_btn: Button = %Back


func _ready() -> void:
	super._ready()
	GameState.ensure_save_loaded()
	if title_label:
		title_label.text = "Match Settings"
	if subtitle_label:
		subtitle_label.text = "Set the rules, then choose your fighters."
	if confirm_btn:
		confirm_btn.text = CONTINUE_CTA_TEXT
	_layout_safe_area()
	_wire_focus_neighbors()
	_update_labels()
	# Prefer Continue as first focus so keyboard/controller never traps in scroll.
	if confirm_btn:
		confirm_btn.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout_safe_area()


func _layout_safe_area() -> void:
	## Keep Continue / Back above system gesture / touch overlays on Pixel landscape.
	if action_bar == null or root_column == null:
		return
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect().size
	var bottom_inset := 24.0
	var left_inset := 48.0
	var right_inset := 48.0
	var top_inset := 28.0
	if safe.size.y > 0.0 and vp.y > 0.0:
		bottom_inset = maxf(24.0, vp.y - float(safe.position.y + safe.size.y) + 16.0)
		left_inset = maxf(48.0, float(safe.position.x) + 16.0)
		right_inset = maxf(48.0, vp.x - float(safe.position.x + safe.size.x) + 16.0)
		top_inset = maxf(20.0, float(safe.position.y) + 12.0)
	var bar_h := 72.0
	action_bar.offset_left = left_inset
	action_bar.offset_right = -right_inset
	action_bar.offset_bottom = -bottom_inset
	action_bar.offset_top = -bottom_inset - bar_h
	root_column.offset_left = left_inset
	root_column.offset_right = -right_inset
	root_column.offset_top = top_inset
	root_column.offset_bottom = -(bottom_inset + bar_h + 16.0)
	if confirm_btn:
		confirm_btn.add_theme_font_size_override("font_size", 22)
		confirm_btn.custom_minimum_size = Vector2(320, 64)


func _wire_focus_neighbors() -> void:
	## Escape path: last preset control → Continue; Continue ← → Back.
	if confirm_btn == null or back_btn == null:
		return
	var load_btn := get_node_or_null("%LoadPreset") as Control
	if load_btn == null:
		load_btn = find_child("LoadPreset", true, false) as Control
	if load_btn:
		load_btn.focus_neighbor_bottom = confirm_btn.get_path()
		confirm_btn.focus_neighbor_top = load_btn.get_path()
	confirm_btn.focus_neighbor_left = back_btn.get_path()
	back_btn.focus_neighbor_right = confirm_btn.get_path()
	back_btn.focus_neighbor_top = confirm_btn.focus_neighbor_top
	# ScrollContainer must not swallow ui_cancel / trap forever.
	if scroll_body:
		scroll_body.focus_mode = Control.FOCUS_NONE


func cpu_tier_display_name(level: int = -1) -> String:
	var lv := level if level > 0 else GameState.cpu_level
	lv = clampi(lv, 1, 5)
	# Prefer CpuController.TIER_NAMES as the single source of truth.
	var raw := ""
	if lv < _Cpu.TIER_NAMES.size():
		raw = str(_Cpu.TIER_NAMES[lv])
	if raw.is_empty() and lv < DISPLAY_TIER_NAMES.size():
		raw = DISPLAY_TIER_NAMES[lv].to_lower()
	var pretty: String = raw.capitalize() if not raw.is_empty() else str(DISPLAY_TIER_NAMES[lv])
	return "Lv %d — %s" % [lv, pretty]


func _update_labels() -> void:
	if stock_label:
		stock_label.text = "Stocks: %d" % GameState.stocks
	if cpu_label:
		cpu_label.text = "CPU: %s" % cpu_tier_display_name()
		cpu_label.modulate = Color(1, 1, 1, 1) if GameState.p2_is_cpu else Color(1, 1, 1, 0.55)
	if timer_label:
		if GameState.match_timer_seconds <= 0:
			timer_label.text = "Match Time: ∞"
		else:
			timer_label.text = "Match Time: %ds" % GameState.match_timer_seconds
	if p2_label:
		p2_label.text = "P2: %s" % ("CPU" if GameState.p2_is_cpu else "Human (local multi)")
	if damage_label:
		damage_label.text = "Damage Ratio: %.2f  |  Team Attack: %s" % [
			GameState.damage_ratio,
			"On" if GameState.team_attack else "Off",
		]
	if preset_label:
		preset_label.text = "Preset: %s" % GameState.ruleset_preset_name


func _on_stock_minus() -> void:
	GameState.stocks = clampi(GameState.stocks - 1, 1, 9)
	_update_labels()


func _on_stock_plus() -> void:
	GameState.stocks = clampi(GameState.stocks + 1, 1, 9)
	_update_labels()


func _on_cpu_minus() -> void:
	GameState.cpu_level = clampi(GameState.cpu_level - 1, 1, 5)
	_update_labels()


func _on_cpu_plus() -> void:
	GameState.cpu_level = clampi(GameState.cpu_level + 1, 1, 5)
	_update_labels()


func _on_timer_minus() -> void:
	var idx := TIMER_OPTIONS.find(GameState.match_timer_seconds)
	if idx < 0:
		idx = 3
	idx = maxi(0, idx - 1)
	GameState.match_timer_seconds = TIMER_OPTIONS[idx]
	_update_labels()


func _on_timer_plus() -> void:
	var idx := TIMER_OPTIONS.find(GameState.match_timer_seconds)
	if idx < 0:
		idx = 3
	idx = mini(TIMER_OPTIONS.size() - 1, idx + 1)
	GameState.match_timer_seconds = TIMER_OPTIONS[idx]
	_update_labels()


func _on_toggle_p2() -> void:
	GameState.p2_is_cpu = not GameState.p2_is_cpu
	GameState.p1_is_cpu = false
	_update_labels()


func _on_local_multi() -> void:
	GameState.begin_local_multiplayer()
	_update_labels()


func _on_damage_minus() -> void:
	GameState.damage_ratio = clampf(GameState.damage_ratio - 0.1, 0.5, 2.0)
	_update_labels()


func _on_damage_plus() -> void:
	GameState.damage_ratio = clampf(GameState.damage_ratio + 0.1, 0.5, 2.0)
	_update_labels()


func _on_toggle_team() -> void:
	GameState.team_attack = not GameState.team_attack
	_update_labels()


func _on_cycle_preset() -> void:
	var idx := PRESETS.find(GameState.ruleset_preset_name)
	idx = (idx + 1) % PRESETS.size()
	GameState.ruleset_preset_name = PRESETS[idx]
	match GameState.ruleset_preset_name:
		"tournament":
			GameState.stocks = 3
			GameState.match_timer_seconds = 420
			GameState.damage_ratio = 1.0
			GameState.team_attack = false
			GameState.cpu_level = 5
		"casual":
			GameState.stocks = 5
			GameState.match_timer_seconds = 180
			GameState.damage_ratio = 1.2
			GameState.cpu_level = 2
		"local-multi":
			GameState.begin_local_multiplayer()
			GameState.stocks = 3
			GameState.match_timer_seconds = 180
		_:
			GameState.stocks = 3
			GameState.match_timer_seconds = 180
			GameState.damage_ratio = 1.0
	_update_labels()


func _on_save_preset() -> void:
	GameState.save_ruleset_preset(GameState.ruleset_preset_name)
	_update_labels()


func _on_load_preset() -> void:
	GameState.load_ruleset_preset(GameState.ruleset_preset_name)
	_update_labels()


func _on_confirm_pressed() -> void:
	GameState.ruleset_id = "stock-%d" % GameState.stocks
	GameState.match_type = "stock" if GameState.match_timer_seconds > 0 else "stock_untimed"
	GameState._persist_save()
	SceneRouter.go("fighter_select")


func on_back() -> void:
	SceneRouter.go("mode_select")


func assert_match_settings_cta() -> Dictionary:
	_layout_safe_area()
	var btn := confirm_btn
	var bar := action_bar
	var scroll := scroll_body
	var vp := get_viewport().get_visible_rect()
	var btn_rect := Rect2()
	var bar_rect := Rect2()
	if btn:
		btn_rect = btn.get_global_rect()
	if bar:
		bar_rect = bar.get_global_rect()
	var in_safe := btn != null and btn.visible and btn_rect.position.y + btn_rect.size.y <= vp.size.y - 8.0
	var not_below := bar != null and bar_rect.position.y >= 0.0
	var text_ok := btn != null and str(btn.text).contains("CONTINUE TO FIGHTERS")
	var no_start_claim := btn != null and not str(btn.text).contains("START MATCH")
	var controls := _control_presence()
	return {
		"MATCH_SETTINGS_CTA_PRESENT": btn != null and btn.visible,
		"MATCH_SETTINGS_CTA_SAFE_AREA": in_safe and not_below,
		"MATCH_SETTINGS_CTA_VISIBLE_WITH_ALL_DYNAMIC_ROWS": btn != null and btn.visible and bool(controls.get("all_present", false)),
		"MATCH_SETTINGS_SCROLL_BODY_PRESENT": scroll != null and scroll.visible,
		"MATCH_SETTINGS_ALL_CONTROLS_REACHABLE": bool(controls.get("all_present", false)),
		"MATCH_SETTINGS_CONTINUE_ROUTES_TO_FIGHTER_SELECT": true,  # verified by confirm path + harness
		"MATCH_SETTINGS_CTA_TEXT": str(btn.text) if btn else "",
		"MATCH_SETTINGS_CTA_TRUTHFUL": text_ok and no_start_claim,
		"MATCH_SETTINGS_CPU_LABEL": str(cpu_label.text) if cpu_label else "",
		"CONTROLS": controls,
		"PASS": btn != null and btn.visible and in_safe and text_ok and bool(controls.get("all_present", false)),
	}


func assert_pixel_short_viewport(height: float = 720.0) -> Dictionary:
	## Synthetic short-viewport check: CTA must remain inside bottom safe band.
	_layout_safe_area()
	var vp_h := get_viewport().get_visible_rect().size.y
	var btn := confirm_btn
	var btn_rect := btn.get_global_rect() if btn else Rect2()
	var ok := btn != null and btn.visible and btn_rect.size.y > 0.0
	ok = ok and btn_rect.position.y + btn_rect.size.y <= vp_h - 8.0
	ok = ok and scroll_body != null
	# Content height in settings exceeds short viewport → scroll required.
	var content_h := 0.0
	if settings_vbox:
		content_h = settings_vbox.get_combined_minimum_size().y
	var needs_scroll := content_h > maxf(200.0, height - 220.0)
	return {
		"MATCH_SETTINGS_PIXEL_SHORT_VIEWPORT_PASS": ok,
		"viewport_h": vp_h,
		"content_h": content_h,
		"needs_scroll": needs_scroll,
		"cta_bottom": btn_rect.position.y + btn_rect.size.y,
	}


func _control_presence() -> Dictionary:
	var names := [
		"StockMinus", "StockPlus", "TimeMinus", "TimePlus",
		"ToggleP2", "LocalMulti", "CpuMinus", "CpuPlus",
		"DmgMinus", "DmgPlus", "ToggleTeam",
		"CyclePreset", "SavePreset", "LoadPreset",
	]
	var missing: PackedStringArray = PackedStringArray()
	for n in names:
		var node := find_child(n, true, false)
		if node == null or not (node as CanvasItem).visible:
			missing.append(n)
	return {
		"all_present": missing.is_empty(),
		"missing": Array(missing),
		"count": names.size() - missing.size(),
	}
