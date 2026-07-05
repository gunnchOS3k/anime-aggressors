extends Node
class_name ProjectileSpawner

## Spawns AAProjectile instances from move projectile config.

const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile2D.tscn")

var owner_fighter: Node = null
var active_projectiles: Array = []

func setup(fighter: Node) -> void:
	owner_fighter = fighter

func spawn_from_move(move: Dictionary, aura_amount: float) -> AAProjectile:
	var proj_cfg: Dictionary = move.get("projectile", {})
	if proj_cfg.is_empty():
		return null
	var level := AuraScaler.aura_level(aura_amount)
	var speed_arr: Array = proj_cfg.get("speed_by_aura", [400])
	var dmg_arr: Array = proj_cfg.get("damage_by_aura", [move.get("damage", 8)])
	var size_arr: Array = proj_cfg.get("size_by_aura", [16])
	var life_arr: Array = proj_cfg.get("lifetime_frames_by_aura", [90])
	var beh_arr: Array = proj_cfg.get("behavior_by_aura", ["straight"])
	var speed := AuraScaler.projectile_value_by_aura(speed_arr, aura_amount)
	var dmg := AuraScaler.projectile_value_by_aura(dmg_arr, aura_amount)
	var sz := AuraScaler.projectile_value_by_aura(size_arr, aura_amount)
	var life := int(AuraScaler.projectile_value_by_aura(life_arr, aura_amount))
	var beh_idx := mini(level, beh_arr.size() - 1)
	var behavior: String = beh_arr[beh_idx]
	var spawn_frame: int = int(proj_cfg.get("spawn_frame", 0))
	if owner_fighter == null:
		return null
	var proj: AAProjectile = PROJECTILE_SCENE.instantiate()
	var battle_root := owner_fighter.get_parent()
	if battle_root:
		battle_root.add_child(proj)
	else:
		owner_fighter.add_child(proj)
	var facing: int = owner_fighter.facing if "facing" in owner_fighter else 1
	var offset := Vector2(float(proj_cfg.get("offset_x", 40)) * facing, float(proj_cfg.get("offset_y", -12)))
	proj.global_position = owner_fighter.global_position + offset
	var element: String = move.get("element_effect", {}).get("type", "")
	var cfg := {
		"fighter_id": owner_fighter.fighter_id if "fighter_id" in owner_fighter else "",
		"move_id": move.get("move_id", ""),
		"aura_level": level,
		"team_slot": owner_fighter.slot if "slot" in owner_fighter else 1,
		"lifetime_frames": life,
		"speed": speed,
		"behavior": behavior,
		"damage": dmg,
		"move_data": move,
		"angle_deg": float(proj_cfg.get("angle_deg", 0)),
		"size": Vector2(sz, sz),
		"color": _element_color(element),
	}
	proj.configure(cfg, owner_fighter)
	active_projectiles.append(proj)
	proj.projectile_expired.connect(func(): active_projectiles.erase(proj))
	return proj

func tick_all() -> void:
	for p in active_projectiles.duplicate():
		if is_instance_valid(p):
			p.tick_sim_frame()

func clear_all() -> void:
	for p in active_projectiles:
		if is_instance_valid(p):
			p.queue_free()
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
