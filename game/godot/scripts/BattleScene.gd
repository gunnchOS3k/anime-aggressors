extends Node2D
class_name BattleScene

signal match_started(p1_fighter_id: String, p2_fighter_id: String)
signal fighter_ko(fighter: FighterController)

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

func _ready() -> void:
	blast_zones = get_node_or_null(blast_zones_path)
	hit_resolver = get_node_or_null(hit_resolver_path)
	aura_meter_p1 = get_node_or_null(aura_meter_p1_path)
	aura_meter_p2 = get_node_or_null(aura_meter_p2_path)

func setup_match(p1_fighter_id: String, p2_fighter_id: String) -> void:
	_cleanup_existing_fighters()
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

	match_started.emit(p1_fighter_id, p2_fighter_id)

func _on_hit_confirmed(_attacker: Node, _defender: Node, hit_info: Dictionary) -> void:
	var cam := get_node_or_null("CombatCamera/CameraImpulse") as CameraImpulse
	if cam != null:
		var launch: Vector2 = hit_info.get("launch_velocity", Vector2.ZERO)
		cam.add_impulse(Vector2(signf(launch.x) * 12.0, -8.0))

func _physics_process(_delta: float) -> void:
	if blast_zones == null:
		return
	_update_camera_anchors()
	if fighter_a != null and blast_zones.validate_fighter(fighter_a):
		fighter_ko.emit(fighter_a)
	if fighter_b != null and blast_zones.validate_fighter(fighter_b):
		fighter_ko.emit(fighter_b)

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
