extends Node2D
const _DataLoader = preload("res://scripts/data/data_loader.gd")

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

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")

func _ready() -> void:
	_build_stage()
	_spawn_fighters()
	_battle_sim = BattleSim.new()
	add_child(_battle_sim)
	_battle_sim.bind_fighters([fighter1, fighter2])
	if OS.is_debug_build():
		_debug_hud = DEBUG_HUD_SCENE.instantiate()
		add_child(_debug_hud)
		_debug_hud.bind_fighters([fighter1, fighter2])
		# Available via F1; stay hidden for release-facing presentation.
		_debug_hud.visible_debug = false
		if _debug_hud.has_node("Panel"):
			_debug_hud.get_node("Panel").visible = false
	fighter1.controls_enabled = false
	fighter2.controls_enabled = false
	await _run_countdown()
	fighter1.controls_enabled = true
	fighter2.controls_enabled = true
	_active = true

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

func _physics_process(_delta: float) -> void:
	if not _active or _paused:
		return
	_update_hud()
	_check_blast(fighter1)
	_check_blast(fighter2)
	_check_match_end()

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
		get_tree().create_timer(0.5).timeout.connect(func(): SceneRouter.go("results"), CONNECT_ONE_SHOT)

func _update_hud() -> void:
	if p1_hud and fighter1:
		p1_hud.text = "%s  %d%%  x%d  aura:%d" % [fighter1.data.get("displayName","P1"), int(fighter1.damage_percent), fighter1.stocks, int(fighter1.aura)]
	if p2_hud and fighter2:
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