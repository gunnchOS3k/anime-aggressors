extends Node2D

@onready var fighters_root: Node2D = $Fighters
@onready var stage_root: Node2D = $Stage
@onready var hud: CanvasLayer = $HUD

var fighter1: AAFighter
var fighter2: AAFighter
var _debug_hud: DebugHud
var _battle_sim: BattleSim
var _hit_log: Label
var _combo_p1: int = 0
var _paused := false
var _slow_mo := false

const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const DEBUG_HUD_SCENE := preload("res://scenes/ui/DebugHud.tscn")

func _ready() -> void:
	_build_stage()
	_spawn_fighters()
	_battle_sim = BattleSim.new()
	add_child(_battle_sim)
	_battle_sim.bind_fighters([fighter1, fighter2])
	_debug_hud = DEBUG_HUD_SCENE.instantiate()
	add_child(_debug_hud)
	_debug_hud.bind_fighters([fighter1, fighter2])
	_hit_log = get_node_or_null("%HitLog") as Label
	_update_help()

func _build_stage() -> void:
	var stage_id := GameState.stage_id if GameState.stage_id != "" else "training-grid"
	var stage_data: Dictionary = GameState.load_stage(stage_id)
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
	var stage_data: Dictionary = GameState.load_stage(GameState.stage_id if GameState.stage_id != "" else "training-grid")
	var main: Dictionary = stage_data.get("mainPlatform", {})
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
	if fighter2.is_cpu:
		fighter2.cpu.setup(fighter2, GameState.cpu_level)
	fighter1.global_position = s1
	fighter2.global_position = s2
	for f in [fighter1, fighter2]:
		f.platform_half_width = float(main.get("width", 800)) / 2.0
		f.platform_center_x = float(main.get("x", 0))
	_connect_hits(fighter1, fighter2)
	_connect_hits(fighter2, fighter1)
	fighter2.hit_landed.connect(_on_dummy_hit)
	fighter1.grab_event.connect(_on_grab)
	fighter2.grab_event.connect(_on_grab)

func _connect_hits(attacker: AAFighter, defender: AAFighter) -> void:
	var hb: Area2D = attacker.get_node("Hitbox")
	var hurt: Area2D = defender.get_node("Hurtbox")
	hb.area_entered.connect(func(area: Area2D):
		if area != hurt or not hb.monitoring or not attacker.move_runner.is_active_phase():
			return
		var move := attacker._current_move
		if move.is_empty():
			move = DataLoader.find_move(attacker.move_manifest, attacker.move_runner.current_move_id())
		if move.is_empty() or move.get("move_id") == "grab":
			return
		attacker.hit_resolver.resolve(attacker, defender, move, attacker.damage_percent)
	)

func _on_dummy_hit(info: Dictionary) -> void:
	if info.get("blocked", false):
		_combo_p1 = 0
	else:
		_combo_p1 += 1
	_log("HIT %s combo:%d" % [info.get("move_id", "?"), _combo_p1])

func _on_grab(info: Dictionary) -> void:
	_log("GRAB %s" % info.get("result", "?"))

func _log(msg: String) -> void:
	if _hit_log:
		_hit_log.text = msg
	if _debug_hud:
		_debug_hud.push_log(msg)

func _update_help() -> void:
	if _hit_log:
		_hit_log.text = "Training — F1 HUD F2 hitboxes F3 pos F4 dmg F5 aura F7 clear F8 dummy F9 pause F10 slow"

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
				fighter1.fill_aura()
			KEY_F7:
				fighter1.clear_aura()
			KEY_F8:
				_cycle_dummy()
			KEY_F9:
				_paused = not _paused
				_battle_sim.set_paused(_paused)
				fighter1.controls_enabled = not _paused
				fighter2.controls_enabled = not _paused
				_log("PAUSED" if _paused else "RESUMED")
			KEY_F10:
				_slow_mo = not _slow_mo
				Engine.time_scale = 0.35 if _slow_mo else 1.0
				_log("SLOW-MO" if _slow_mo else "NORMAL SPEED")
	if event.is_action_pressed("ui_cancel"):
		Engine.time_scale = 1.0
		SceneRouter.go("training")

func _cycle_dummy() -> void:
	var modes := ["idle", "shield", "jump", "attack", "cpu"]
	var idx := modes.find(fighter2.dummy_mode)
	idx = (idx + 1) % modes.size()
	fighter2.dummy_mode = modes[idx]
	fighter2.is_cpu = fighter2.dummy_mode == "cpu"
	_log("Dummy: %s" % fighter2.dummy_mode)
