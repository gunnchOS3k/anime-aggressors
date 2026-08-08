extends Node2D
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _BattleHudPanel = preload("res://scripts/ui/battle_hud_panel.gd")
const _BattleSim = preload("res://scripts/battle/battle_sim.gd")

@onready var fighters_root: Node2D = $Fighters
@onready var stage_root: Node2D = $Stage
@onready var hud: CanvasLayer = $HUD
@onready var countdown_label: Label = %CountdownLabel
@onready var p1_hud: Label = %P1Hud
@onready var p2_hud: Label = %P2Hud
@onready var ko_label: Label = %KoLabel

var fighter1
var fighter2
var blast: Dictionary = {}
var _active := false
var _paused := false
var _ko_lock := false
var _debug_hud
var _battle_sim
var _pause_panel: PanelContainer
var _p1_panel
var _p2_panel
var _timer_label: Label
var _time_remaining: float = 180.0
var _time_enabled := true

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")

func _ready() -> void:
	_build_stage()
	_spawn_fighters()
	_setup_hud_panels()
	_apply_device_role()
	_time_remaining = float(GameState.match_timer_seconds)
	_time_enabled = GameState.match_timer_seconds > 0 and GameState.match_type != "stock_untimed"
	_battle_sim = _BattleSim.new()
	add_child(_battle_sim)
	_battle_sim.bind_fighters([fighter1, fighter2])
	var show_debug := OS.is_debug_build()
	if DeviceRoleRuntime.debug_hud_default:
		show_debug = true
	if show_debug:
		_debug_hud = DEBUG_HUD_SCENE.instantiate()
		add_child(_debug_hud)
		_debug_hud.bind_fighters([fighter1, fighter2])
		_debug_hud.visible_debug = DeviceRoleRuntime.debug_hud_default
		if _debug_hud.has_node("Panel"):
			_debug_hud.get_node("Panel").visible = DeviceRoleRuntime.debug_hud_default
	fighter1.controls_enabled = false
	fighter2.controls_enabled = false
	MatchTelemetry.start_match({
		"p1": GameState.p1_fighter_id,
		"p2": GameState.p2_fighter_id,
		"stage": GameState.stage_id,
		"stocks": GameState.stocks,
		"timer": GameState.match_timer_seconds,
		"device_role": DeviceRoleRuntime.active_role,
	})
	await _run_countdown()
	fighter1.controls_enabled = true
	fighter2.controls_enabled = true
	_active = true

func _apply_device_role() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	DeviceRoleRuntime.apply_layout_hint(cam)
	if hud:
		DeviceRoleRuntime.apply_to_battle_hud(hud)
	# Bind combat feedback cameras when FX allows shake.
	for f in [fighter1, fighter2]:
		if f and f.combat_feedback and cam:
			f.combat_feedback.bind_camera(cam)
	TouchInputManager._sync_overlay()

func _setup_hud_panels() -> void:
	var top := hud.get_node_or_null("TopBar") as HBoxContainer
	if top == null:
		return
	for c in top.get_children():
		c.visible = false
	_p1_panel = _BattleHudPanel.new()
	_p1_panel.name = "P1Panel"
	_p1_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p1_panel.custom_minimum_size = Vector2(280, 72)
	top.add_child(_p1_panel)
	_timer_label = Label.new()
	_timer_label.name = "MatchTimer"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 26)
	_timer_label.custom_minimum_size = Vector2(110, 0)
	top.add_child(_timer_label)
	_p2_panel = _BattleHudPanel.new()
	_p2_panel.name = "P2Panel"
	_p2_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p2_panel.custom_minimum_size = Vector2(280, 72)
	top.add_child(_p2_panel)
	var a1 := Color(fighter1.data.get("color", Color(1, 0.5, 0.2))) if fighter1 else Color(1, 0.5, 0.2)
	var a2 := Color(fighter2.data.get("color", Color(0.3, 0.6, 1.0))) if fighter2 else Color(0.3, 0.6, 1.0)
	_p1_panel.configure(fighter1.data.get("displayName", "P1"), a1, GameState.stocks, false)
	_p2_panel.configure(fighter2.data.get("displayName", "P2"), a2, GameState.stocks, true)
	_update_timer_label()

func _build_stage() -> void:
	for c in stage_root.get_children():
		c.queue_free()
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id)
	blast = stage_data.get("blastZones", {})
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = Vector2(1920, 1080)
	bg.z_index = -10
	stage_root.add_child(bg)
	if not DeviceRoleRuntime.reduce_motion:
		for i in range(3):
			var band := ColorRect.new()
			band.color = Color(0.08, 0.12, 0.22, 0.35)
			band.size = Vector2(2200, 18)
			band.position = Vector2(-1100, -280 + i * 120)
			band.rotation = -0.08 + i * 0.04
			band.z_index = -9
			stage_root.add_child(band)
	var main: Dictionary = stage_data.get("mainPlatform", {})
	_add_platform(main)
	for p in stage_data.get("sidePlatforms", []):
		_add_platform(p)

func _add_platform(p: Dictionary) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(p.width, p.height)
	shape.shape = rect
	body.position = Vector2(p.x, p.y + p.height / 2.0)
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.color = Color(0.12, 0.14, 0.22)
	vis.size = rect.size
	vis.position = Vector2(-rect.size.x / 2, -rect.size.y / 2)
	body.add_child(vis)
	var trim := ColorRect.new()
	trim.color = Color(0.28, 0.55, 0.95, 0.85)
	trim.size = Vector2(rect.size.x, 6)
	trim.position = Vector2(-rect.size.x / 2, -rect.size.y / 2)
	body.add_child(trim)
	stage_root.add_child(body)

func _spawn_fighters() -> void:
	for c in fighters_root.get_children():
		c.queue_free()
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id)
	var spawns: Array = stage_data.get("spawnPoints", [])
	var s1 := Vector2(-200, 200)
	var s2 := Vector2(200, 200)
	var main: Dictionary = stage_data.get("mainPlatform", {})
	for sp in spawns:
		if sp.slot == 1:
			s1 = Vector2(sp.x, sp.y)
		if sp.slot == 2:
			s2 = Vector2(sp.x, sp.y)
	fighter1 = FIGHTER_SCENE.instantiate()
	fighter2 = FIGHTER_SCENE.instantiate()
	fighter1.name = "Fighter1"
	fighter2.name = "Fighter2"
	fighters_root.add_child(fighter1)
	fighters_root.add_child(fighter2)
	fighter1.configure(GameState.p1_fighter_id, 1, false, GameState.stocks, s1)
	fighter2.configure(GameState.p2_fighter_id, 2, GameState.p2_is_cpu, GameState.stocks, s2)
	fighter1.global_position = s1
	fighter2.global_position = s2
	for f in [fighter1, fighter2]:
		f.platform_half_width = float(main.get("width", 800)) / 2.0
		f.platform_center_x = float(main.get("x", 0))
	_connect_hitboxes(fighter1, fighter2)
	_connect_hitboxes(fighter2, fighter1)
	fighter1.koed.connect(_on_ko.bind(fighter1))
	fighter2.koed.connect(_on_ko.bind(fighter2))
	_update_hud()

func _connect_hitboxes(attacker, defender) -> void:
	var hb: Area2D = attacker.get_node("Hitbox")
	var hurt: Area2D = defender.get_node("Hurtbox")
	hb.area_entered.connect(func(area: Area2D):
		if area != hurt or not hb.monitoring or not attacker.move_runner.is_active_phase():
			return
		var move = attacker._current_move
		if move.is_empty():
			move = _DataLoader.find_move(attacker.move_manifest, attacker.move_runner.current_move_id())
		if move.is_empty() or move.get("move_id") == "grab":
			return
		attacker.hit_resolver.resolve(attacker, defender, move, attacker.damage_percent)
	)

func _run_countdown() -> void:
	for i in range(3, 0, -1):
		if countdown_label:
			countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	if countdown_label:
		countdown_label.text = "FIGHT!"
	await get_tree().create_timer(0.6).timeout
	if countdown_label:
		countdown_label.visible = false

func _physics_process(delta: float) -> void:
	if not _active or _paused:
		return
	if _time_enabled:
		_time_remaining = maxf(0.0, _time_remaining - delta)
		_update_timer_label()
		if _time_remaining <= 0.0:
			_end_match_on_time()
			return
	_update_hud()
	_check_blast(fighter1)
	_check_blast(fighter2)
	_check_match_end()

func _update_timer_label() -> void:
	if _timer_label == null:
		return
	if not _time_enabled:
		_timer_label.text = "∞"
		return
	var secs := int(ceil(_time_remaining))
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]

func _end_match_on_time() -> void:
	_active = false
	# Higher stocks wins; tie-break lower percent.
	var winner := 1
	if fighter2.stocks > fighter1.stocks:
		winner = 2
	elif fighter2.stocks == fighter1.stocks:
		winner = 1 if fighter1.damage_percent <= fighter2.damage_percent else 2
	GameState.last_winner_slot = winner
	MatchTelemetry.record_match_end(winner)
	get_tree().create_timer(0.5).timeout.connect(func(): SceneRouter.go("results"), CONNECT_ONE_SHOT)

func _check_blast(f) -> void:
	if f == null or f.stocks <= 0 or _ko_lock:
		return
	var pos: Vector2 = f.global_position
	if pos.x < blast.get("left", -9999) or pos.x > blast.get("right", 9999) or pos.y < blast.get("top", -9999) or pos.y > blast.get("bottom", 9999):
		_ko_lock = true
		if ko_label:
			ko_label.text = "%s KO!" % f.data.get("displayName", "?")
			ko_label.visible = true
		f.lose_stock()
		get_tree().create_timer(0.8).timeout.connect(func():
			if ko_label:
				ko_label.visible = false
			_ko_lock = false
		, CONNECT_ONE_SHOT)

func _on_ko(_f) -> void:
	pass

func _check_match_end() -> void:
	if fighter1.stocks <= 0 or fighter2.stocks <= 0:
		_active = false
		var winner := 2 if fighter1.stocks <= 0 else 1
		GameState.last_winner_slot = winner
		MatchTelemetry.record_match_end(winner)
		get_tree().create_timer(0.5).timeout.connect(func(): SceneRouter.go("results"), CONNECT_ONE_SHOT)

func _update_hud() -> void:
	if _p1_panel and fighter1:
		_p1_panel.update_from_fighter(fighter1)
	elif p1_hud and fighter1:
		p1_hud.text = "%s  %d%%  x%d  aura:%d" % [fighter1.data.get("displayName","P1"), int(fighter1.damage_percent), fighter1.stocks, int(fighter1.aura)]
	if _p2_panel and fighter2:
		_p2_panel.update_from_fighter(fighter2)
	elif p2_hud and fighter2:
		p2_hud.text = "%s  %d%%  x%d  aura:%d%s" % [fighter2.data.get("displayName","P2"), int(fighter2.damage_percent), fighter2.stocks, int(fighter2.aura), " (CPU L%d)" % GameState.cpu_level if GameState.p2_is_cpu else ""]

func _toggle_pause() -> void:
	_paused = not _paused
	if _battle_sim:
		_battle_sim.set_paused(_paused)
	if fighter1:
		fighter1.controls_enabled = not _paused
	if fighter2:
		fighter2.controls_enabled = not _paused
	if _pause_panel:
		_pause_panel.visible = _paused
	TouchInputManager._sync_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_ensure_pause_panel()
		_toggle_pause()
	if _paused and event.is_action_pressed("ui_accept"):
		_toggle_pause()

func _ensure_pause_panel() -> void:
	if _pause_panel:
		return
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_panel.custom_minimum_size = Vector2(420, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.16, 0.94)
	style.border_color = Color(0.95, 0.75, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_content_margin_all(18)
	_pause_panel.add_theme_stylebox_override("panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_toggle_pause)
	v.add_child(resume_btn)
	var rematch_btn := Button.new()
	rematch_btn.text = "Rematch"
	rematch_btn.pressed.connect(func(): SceneRouter.go("battle"))
	v.add_child(rematch_btn)
	var menu_btn := Button.new()
	menu_btn.text = "Return to Menu"
	menu_btn.pressed.connect(func(): SceneRouter.go("main_menu"))
	v.add_child(menu_btn)
	_pause_panel.add_child(v)
	hud.add_child(_pause_panel)
	_pause_panel.visible = false
