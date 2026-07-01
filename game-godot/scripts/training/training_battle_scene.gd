extends Node2D

## Training battle — reuses battle systems with dummy behavior from GameState.training_dummy_mode

@onready var fighters_root: Node2D = $Fighters
@onready var stage_root: Node2D = $Stage

var fighter1: AAFighter
var fighter2: AAFighter
var _debug_hud: DebugHud
var _hit_log: Label
var _combo_p1: int = 0

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")

func _ready() -> void:
	_build_stage()
	_spawn_fighters()
	_debug_hud = DEBUG_HUD_SCENE.instantiate()
	add_child(_debug_hud)
	_debug_hud.bind_fighters([fighter1, fighter2])
	_hit_log = get_node_or_null("%HitLog") as Label

func _build_stage() -> void:
	var stage_data: Dictionary = GameState.load_stage("training-grid")
	var main: Dictionary = stage_data.get("mainPlatform", {})
	_add_platform(main)

func _add_platform(p: Dictionary) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(p.width, p.height)
	shape.shape = rect
	body.position = Vector2(p.x, p.y + p.height / 2.0)
	body.add_child(shape)
	stage_root.add_child(body)

func _spawn_fighters() -> void:
	var stage_data: Dictionary = GameState.load_stage("training-grid")
	var s1 := Vector2(-180, 200)
	var s2 := Vector2(180, 200)
	fighter1 = FIGHTER_SCENE.instantiate()
	fighter2 = FIGHTER_SCENE.instantiate()
	fighters_root.add_child(fighter1)
	fighters_root.add_child(fighter2)
	fighter1.configure(GameState.p1_fighter_id, 1, false, 99, s1)
	fighter2.configure(GameState.p2_fighter_id, 2, false, 99, s2)
	fighter2.dummy_mode = GameState.training_dummy_mode
	fighter2.is_cpu = GameState.training_dummy_mode == "cpu"
	fighter1.global_position = s1
	fighter2.global_position = s2
	_connect_hits(fighter1, fighter2)
	_connect_hits(fighter2, fighter1)
	fighter2.hit_landed.connect(_on_dummy_hit)

func _connect_hits(attacker: AAFighter, defender: AAFighter) -> void:
	var hb: Area2D = attacker.get_node("Hitbox")
	var hurt: Area2D = defender.get_node("Hurtbox")
	hb.area_entered.connect(func(area: Area2D):
		if area != hurt or not hb.monitoring:
			return
		var move := attacker._current_move
		if move.is_empty():
			move = DataLoader.find_move(attacker.move_manifest, attacker.move_runner.current_move_id())
		if not move.is_empty():
			attacker.hit_resolver.resolve(attacker, defender, move, attacker.damage_percent)
	)

func _on_dummy_hit(_info: Dictionary) -> void:
	_combo_p1 += 1
	if _hit_log:
		_hit_log.text = "Hits: %d  Last: %s" % [_combo_p1, _info.get("move_id", "?")]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F3:
				fighter1.reset_position()
				fighter2.reset_position()
			KEY_F4:
				fighter1.reset_damage()
				fighter2.reset_damage()
				_combo_p1 = 0
			KEY_F5:
				fighter1.aura = 100.0
	if event.is_action_pressed("ui_cancel"):
		SceneRouter.go("training")
