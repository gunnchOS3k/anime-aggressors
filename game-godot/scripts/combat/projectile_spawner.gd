extends Node
class_name ProjectileSpawner
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _AAProjectile = preload("res://scripts/combat/projectile.gd")

## Spawns _AAProjectile instances from move projectile config.

const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile2D.tscn")
signal projectile_spawned(projectile: Node)

var owner_fighter: Node = null
var active_projectiles: Array = []
var _spawn_sequence := 0
var _interaction_data: Dictionary = {}

func setup(fighter: Node) -> void:
	owner_fighter = fighter
	_interaction_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/projectile_interactions.json"))

func spawn_from_move(move: Dictionary, aura_amount: float) -> Node:
	var proj_cfg: Dictionary = move.get("projectile", {})
	if proj_cfg.is_empty():
		return null
	var level: int = int(_AuraScaler.aura_level(aura_amount))
	var speed_arr: Array = proj_cfg.get("speed_by_aura", [400])
	var dmg_arr: Array = proj_cfg.get("damage_by_aura", [move.get("damage", 8)])
	var size_arr: Array = proj_cfg.get("size_by_aura", [16])
	var life_arr: Array = proj_cfg.get("lifetime_frames_by_aura", [90])
	var beh_arr: Array = proj_cfg.get("behavior_by_aura", ["straight"])
	var speed: float = float(_AuraScaler.projectile_value_by_aura(speed_arr, aura_amount))
	var dmg: float = float(_AuraScaler.projectile_value_by_aura(dmg_arr, aura_amount))
	var sz: float = float(_AuraScaler.projectile_value_by_aura(size_arr, aura_amount))
	var life := int(_AuraScaler.projectile_value_by_aura(life_arr, aura_amount))
	var beh_idx := mini(level, beh_arr.size() - 1)
	var behavior: String = beh_arr[beh_idx]
	var spawn_frame: int = int(proj_cfg.get("spawn_frame", 0))
	if owner_fighter == null:
		return null
	var limit := int(proj_cfg.get("max_active_per_move", 0))
	if limit > 0:
		var same: Array = active_projectiles.filter(func(p): return is_instance_valid(p) and p.active and p.move_id == str(move.get("move_id", "")))
		while same.size() >= limit:
			same.pop_front().cancel_immediate()
		owner_fighter.stamp_runtime_hook("construct_limit")
	var proj = PROJECTILE_SCENE.instantiate()
	var battle_root := owner_fighter.get_parent()
	if battle_root:
		battle_root.add_child(proj)
	else:
		owner_fighter.add_child(proj)
	var facing: int = owner_fighter.facing if "facing" in owner_fighter else 1
	if "attack_direction" in owner_fighter and int(owner_fighter.attack_direction) != 0:
		facing = int(owner_fighter.attack_direction)
	var offset := Vector2(float(proj_cfg.get("offset_x", 40)) * facing, float(proj_cfg.get("offset_y", -12)))
	proj.global_position = owner_fighter.global_position + offset
	var element: String = move.get("element_effect", {}).get("type", "")
	var tier := str(move.get("projectile_tier", ""))
	if tier.is_empty():
		match level:
			0, 1:
				tier = "projectile_tap"
			2:
				tier = "projectile_medium"
			_:
				tier = "projectile_full"
	var projectile_move := move.duplicate(true)
	projectile_move["_attack_activation_id"] = owner_fighter.move_runner.activation_id
	_spawn_sequence += 1
	var fighter_id: String = owner_fighter.fighter_id if "fighter_id" in owner_fighter else ""
	var interaction: Dictionary = _interaction_data.get("fighters", {}).get(fighter_id, {}).get(str(move.get("move_id", "")), {})
	if bool(move.get("_party_move",false)) and interaction.is_empty():
		interaction={"eligible_behaviors":["straight"],"integrity_by_aura":[1],"residual_damage_exponent":1.0}
	var integrity_values: Array = interaction.get("integrity_by_aura", [1])
	var team := "story:" + str(owner_fighter.get_meta("story_team")) if owner_fighter.has_meta("story_team") else "slot:" + str(owner_fighter.slot)
	var cfg := {
		"fighter_id": owner_fighter.fighter_id if "fighter_id" in owner_fighter else "",
		"move_id": move.get("move_id", ""),
		"aura_level": level,
		"projectile_tier": tier,
		"team_slot": owner_fighter.slot if "slot" in owner_fighter else 1,
		"team_key": team,
		"order_id": owner_fighter.slot * 1000000 + _spawn_sequence,
		"clash_eligible": behavior in interaction.get("eligible_behaviors", []),
		"integrity": int(integrity_values[mini(level, integrity_values.size() - 1)]),
		"residual_damage_exponent": float(interaction.get("residual_damage_exponent", 1.0)),
		"lifetime_frames": life,
		"speed": speed,
		"behavior": behavior,
		# Motion classification (including beam) grants no fighter piercing.
		"pierces_fighters": bool(proj_cfg.get("pierce", false)),
		"damage": dmg,
		"move_data": projectile_move,
		"angle_deg": float(proj_cfg.get("angle_deg", 0)),
		"size": Vector2(sz, sz),
		"color": _element_color(element),
	}
	proj.configure(cfg, owner_fighter)
	if str(proj_cfg.get("type", "")) == "definition_panel": owner_fighter.stamp_runtime_hook("definition_construct")
	active_projectiles.append(proj)
	proj.projectile_expired.connect(func(): active_projectiles.erase(proj))
	projectile_spawned.emit(proj)
	return proj

func tick_all() -> void:
	for p in active_projectiles.duplicate():
		if is_instance_valid(p):
			p.tick_sim_frame()

func clear_all() -> void:
	for p in active_projectiles.duplicate():
		if is_instance_valid(p):
			p.cancel_immediate()
	active_projectiles.clear()

func count() -> int:
	var n := 0
	for p in active_projectiles:
		if is_instance_valid(p):
			n += 1
	return n

func set_debug_visible(v: bool) -> void:
	for p in active_projectiles:
		if is_instance_valid(p):
			p.set_debug_visible(v)

func _element_color(element: String) -> Color:
	match element:
		"flame": return Color(1.0, 0.4, 0.1, 0.8)
		"impact": return Color(0.9, 0.7, 0.2, 0.8)
		"volt": return Color(1.0, 0.95, 0.2, 0.8)
		"gale": return Color(0.3, 0.85, 0.5, 0.8)
		"frost": return Color(0.4, 0.7, 1.0, 0.8)
		"gravity": return Color(0.5, 0.4, 0.8, 0.8)
		"void": return Color(0.6, 0.2, 0.8, 0.8)
		_: return Color(0.9, 0.5, 0.2, 0.7)
