extends Node2D
class_name BattleScene

signal match_started(p1_fighter_id: String, p2_fighter_id: String)
signal fighter_ko(fighter: FighterController)
signal match_finished(winner_id: String)

@export_file("*.tscn") var fighter_scene_path: String = ""
@export var spawn_a: Vector2 = Vector2(-220, -140)
@export var spawn_b: Vector2 = Vector2(220, -140)
@export var blast_zones_path: NodePath
@export var hit_resolver_path: NodePath
@export var aura_meter_p1_path: NodePath
@export var aura_meter_p2_path: NodePath

var fighter_a: FighterController
var fighter_b: FighterController
var blast_zones: BlastZones
var hit_resolver: HitResolver
var aura_meter_p1: AuraMeter
var aura_meter_p2: AuraMeter
var camera_director: CameraImpactDirector
var battle_intro: BattleIntro
var battle_results: BattleResults
var _match_active := false

func _ready() -> void:
	blast_zones = get_node_or_null(blast_zones_path)
	hit_resolver = get_node_or_null(hit_resolver_path)
	aura_meter_p1 = get_node_or_null(aura_meter_p1_path)
	aura_meter_p2 = get_node_or_null(aura_meter_p2_path)
	camera_director = get_node_or_null("CameraImpactDirector") as CameraImpactDirector
	battle_intro = get_node_or_null("BattleIntro") as BattleIntro
	battle_results = get_node_or_null("HUD/BattleResults") as BattleResults
	if battle_results != null:
		battle_results.visible = false
		battle_results.rematch_requested.connect(_on_rematch)
		battle_results.character_select_requested.connect(_on_character_select)
		battle_results.main_menu_requested.connect(_on_main_menu)

func setup_match(p1_fighter_id: String, p2_fighter_id: String) -> void:
	_cleanup_existing_fighters()
	_match_active = false
	if battle_results != null:
		battle_results.visible = false

	var stage := get_node_or_null("Stage")
	if stage != null:
		var spawn_a_marker := stage.get_node_or_null("SpawnA") as Node2D
		var spawn_b_marker := stage.get_node_or_null("SpawnB") as Node2D
		if spawn_a_marker != null:
			spawn_a = spawn_a_marker.global_position
		if spawn_b_marker != null:
			spawn_b = spawn_b_marker.global_position

	fighter_a = _spawn_fighter(p1_fighter_id, FighterInput.PlayerSlot.P1, spawn_a, 1)
	fighter_b = _spawn_fighter(p2_fighter_id, FighterInput.PlayerSlot.P2, spawn_b, -1)

	if aura_meter_p1 != null and fighter_a != null:
		aura_meter_p1.bind_charge(fighter_a.aura_charge)
	if aura_meter_p2 != null and fighter_b != null:
		aura_meter_p2.bind_charge(fighter_b.aura_charge)

	if hit_resolver != null:
		_register_fighter_hitboxes(fighter_a)
		_register_fighter_hitboxes(fighter_b)
		if not hit_resolver.combat_events.hit_confirmed.is_connected(_on_hit_confirmed):
			hit_resolver.combat_events.hit_confirmed.connect(_on_hit_confirmed)

	if battle_intro != null:
		await battle_intro.play("Skyline Arena")
	_match_active = true
	match_started.emit(p1_fighter_id, p2_fighter_id)

func _on_hit_confirmed(attacker: Node, defender: Node, hit_info: Dictionary) -> void:
	if camera_director != null:
		camera_director.on_hit_confirmed(hit_info)
	elif get_node_or_null("CombatCamera/CameraImpulse") != null:
		var cam := get_node("CombatCamera/CameraImpulse") as CameraImpulse
		var launch: Vector2 = hit_info.get("launch_velocity", Vector2.ZERO)
		cam.add_impulse(Vector2(signf(launch.x) * 12.0, -8.0))

	if defender is FighterController:
		var victim := defender as FighterController
		if victim.visual_rig != null:
			victim.visual_rig.play_hit_spark("hit_center_socket")
	if attacker is FighterController:
		var atk := attacker as FighterController
		var style := FighterAppearance.get_style(atk.fighter_stats.fighter_id)
		var socket_name := FighterMoveChoreography.hit_socket_for_state(atk.state_machine.current_state)
		if atk.visual_rig != null and atk.visual_rig.sockets.has(socket_name):
			AttackTrailFactory.spawn_trail(atk.visual_rig.sockets[socket_name], style["glow"])

func _physics_process(_delta: float) -> void:
	if blast_zones == null or not _match_active:
		return
	_update_camera_anchors()
	if fighter_a != null and blast_zones.validate_fighter(fighter_a):
		_end_match(fighter_b)
	elif fighter_b != null and blast_zones.validate_fighter(fighter_b):
		_end_match(fighter_a)

func _end_match(winner: FighterController) -> void:
	if not _match_active:
		return
	_match_active = false
	if camera_director != null:
		camera_director.on_ko()
	var winner_id := winner.fighter_stats.fighter_id if winner != null else ""
	match_finished.emit(winner_id)
	if battle_results != null:
		battle_results.show_results(winner_id, fighter_a, fighter_b)
	fighter_ko.emit(winner)

func _on_rematch() -> void:
	if fighter_a != null and fighter_b != null:
		setup_match(fighter_a.fighter_stats.fighter_id, fighter_b.fighter_stats.fighter_id)

func _on_character_select() -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "main_router", "go_character_select")

func _on_main_menu() -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "main_router", "go_character_select")

func _update_camera_anchors() -> void:
	var anchor_a := get_node_or_null("FighterAAnchor") as Node2D
	var anchor_b := get_node_or_null("FighterBAnchor") as Node2D
	var cam := get_node_or_null("CombatCamera") as PlatformFighterCamera
	if fighter_a != null and anchor_a != null:
		anchor_a.global_position = fighter_a.global_position
	if fighter_b != null and anchor_b != null:
		anchor_b.global_position = fighter_b.global_position
	if cam != null and fighter_a != null and fighter_b != null:
		cam.fighter_a = get_node("FighterAAnchor")
		cam.fighter_b = get_node("FighterBAnchor")

func _spawn_fighter(fighter_id: String, slot: FighterInput.PlayerSlot, at: Vector2, face: int) -> FighterController:
	var fighter: FighterController
	if not fighter_scene_path.is_empty():
		var packed: PackedScene = load(fighter_scene_path)
		if packed != null:
			fighter = packed.instantiate() as FighterController
	if fighter == null:
		fighter = FighterController.new()

	fighter.fighter_stats = FighterStats.new(fighter_id)
	fighter.player_slot = slot
	fighter.position = at
	fighter.facing = face
	add_child(fighter)
	return fighter

func _register_fighter_hitboxes(fighter: FighterController) -> void:
	if fighter == null or hit_resolver == null:
		return
	for child in fighter.get_children():
		var hitbox := child as Hitbox
		if hitbox != null:
			hitbox.owner_fighter = fighter
			hit_resolver.register_hitbox(hitbox)

func _cleanup_existing_fighters() -> void:
	if fighter_a != null:
		fighter_a.queue_free()
		fighter_a = null
	if fighter_b != null:
		fighter_b.queue_free()
		fighter_b = null
