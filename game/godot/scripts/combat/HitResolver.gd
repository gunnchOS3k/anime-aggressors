extends Node
class_name HitResolver

@export var hitstop_duration: float = 0.05
@export var launch_multiplier: float = 1.0
@export var combat_events_path: NodePath

var combat_events: CombatEvents

func _ready() -> void:
	combat_events = get_node_or_null(combat_events_path)
	if combat_events == null:
		combat_events = CombatEvents.new()
		add_child(combat_events)

func register_hitbox(hitbox: Hitbox) -> void:
	if not hitbox.hit_connected.is_connected(_on_hit_connected):
		hitbox.hit_connected.connect(_on_hit_connected)

func _on_hit_connected(hitbox: Hitbox, hurtbox: Hurtbox) -> void:
	if not hurtbox.can_be_hit():
		return

	var attacker := hitbox.owner_fighter
	var defender := hurtbox.owner_fighter
	if defender == null:
		return

	var damage_percent := _read_float_property(defender, "damage_percent", 0.0)
	var victim_weight := 1.0
	var fighter_stats_obj: Variant = _read_property(defender, "fighter_stats")
	if fighter_stats_obj is FighterStats:
		victim_weight = float((fighter_stats_obj as FighterStats).weight)

	var launch_velocity := Knockback.calculate_velocity(
		damage_percent,
		hitbox.base_knockback,
		hitbox.knockback_growth,
		hitbox.knockback_angle_deg,
		victim_weight
	) * launch_multiplier

	var stun_seconds := Knockback.calculate_hitstun_seconds(launch_velocity)
	var hit_info := {
		"attacker": attacker,
		"defender": defender,
		"damage": hitbox.damage,
		"launch_velocity": launch_velocity,
		"hitstun": stun_seconds,
		"hitstop": hitstop_duration,
		"move_type": hitbox.move_type
	}

	if defender.has_method("receive_hit"):
		defender.receive_hit(hit_info)
	else:
		hurtbox.apply_hit(hit_info)

	combat_events.hit_confirmed.emit(attacker, defender, hit_info)
	combat_events.launched.emit(defender, launch_velocity)

func _read_property(target: Object, property_name: String) -> Variant:
	for item in target.get_property_list():
		if item.get("name", "") == property_name:
			return target.get(property_name)
	return null

func _read_float_property(target: Object, property_name: String, default_value: float) -> float:
	var value: Variant = _read_property(target, property_name)
	if value == null:
		return default_value
	return float(value)
