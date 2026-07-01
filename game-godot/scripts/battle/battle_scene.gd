extends Node2D

@onready var fighters_root: Node2D = $Fighters
@onready var stage_root: Node2D = $Stage
@onready var hud: CanvasLayer = $HUD
@onready var countdown_label: Label = %CountdownLabel
@onready var p1_hud: Label = %P1Hud
@onready var p2_hud: Label = %P2Hud
@onready var ko_label: Label = %KoLabel

var fighter1: AAFighter
var fighter2: AAFighter
var blast: Dictionary = {}
var _active := false
var _ko_lock := false
var _debug_hud: DebugHud

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")

func _ready() -> void:
	_build_stage()
	_spawn_fighters()
	_debug_hud = DEBUG_HUD_SCENE.instantiate()
	add_child(_debug_hud)
	_debug_hud.bind_fighters([fighter1, fighter2])
	await _run_countdown()
	_active = true

func _build_stage() -> void:
	for c in stage_root.get_children():
		c.queue_free()
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id)
	blast = stage_data.get("blastZones", {})
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
	vis.color = Color(0.18, 0.22, 0.32)
	vis.size = rect.size
	vis.position = Vector2(-rect.size.x / 2, -rect.size.y / 2)
	body.add_child(vis)
	stage_root.add_child(body)

func _spawn_fighters() -> void:
	for c in fighters_root.get_children():
		c.queue_free()
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id)
	var spawns: Array = stage_data.get("spawnPoints", [])
	var s1 := Vector2(-200, 200)
	var s2 := Vector2(200, 200)
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
	_connect_hitboxes(fighter1, fighter2)
	_connect_hitboxes(fighter2, fighter1)
	fighter1.koed.connect(_on_ko.bind(fighter1))
	fighter2.koed.connect(_on_ko.bind(fighter2))
	_update_hud()

func _connect_hitboxes(attacker: AAFighter, defender: AAFighter) -> void:
	var hb: Area2D = attacker.get_node("Hitbox")
	var hurt: Area2D = defender.get_node("Hurtbox")
	hb.area_entered.connect(func(area: Area2D):
		if area != hurt or not hb.monitoring:
			return
		var move := attacker._current_move
		if move.is_empty():
			move = DataLoader.find_move(attacker.move_manifest, attacker.move_runner.current_move_id())
		if move.is_empty():
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
	if not _active:
		return
	_update_hud()
	_check_blast(fighter1)
	_check_blast(fighter2)
	_check_match_end()

func _check_blast(f: AAFighter) -> void:
	if f == null or f.stocks <= 0 or _ko_lock:
		return
	var pos := f.global_position
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

func _on_ko(_f: AAFighter) -> void:
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
		p2_hud.text = "%s  %d%%  x%d  aura:%d%s" % [fighter2.data.get("displayName","P2"), int(fighter2.damage_percent), fighter2.stocks, int(fighter2.aura), " (CPU)" if GameState.p2_is_cpu else ""]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneRouter.go("pause")
