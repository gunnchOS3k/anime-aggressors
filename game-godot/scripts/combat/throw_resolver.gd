extends RefCounted
class_name ThrowResolver
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")

## Reads throw direction during grab hold and resolves directional throws.

const PRIORITY := ["up", "down", "forward", "back"]

static func read_throw_direction(fighter: Node) -> String:
	if not fighter.has_method("_read_axis"):
		return "forward"
	var up_held := false
	var down_held := false
	if fighter.has_method("_read_up"):
		up_held = fighter._read_up()
	if fighter.has_method("_read_down"):
		down_held = fighter._read_down()
	elif "slot" in fighter:
		var slot: int = int(fighter.slot)
		up_held = Input.is_action_pressed("p%d_up" % slot)
		down_held = Input.is_action_pressed("p%d_down" % slot)
	if up_held:
		return "up"
	if down_held:
		return "down"
	var axis: float = fighter._read_axis()
	if absf(axis) > 0.3:
		var facing: int = fighter.facing if "facing" in fighter else 1
		if signf(axis) == signf(float(facing)):
			return "forward"
		return "back"
	return "forward"

static func throw_move_id(direction: String) -> String:
	return "throw_%s" % direction

static func resolve_throw(attacker: Node, target: Node, manifest: Dictionary, direction: String) -> Dictionary:
	var move_id: String = throw_move_id(direction)
	var throw_move: Dictionary = _DataLoader.find_move(manifest, move_id)
	if throw_move.is_empty():
		throw_move = _DataLoader.find_move(manifest, "throw_forward")
	var synthesized := throw_move.is_empty()
	if synthesized:
		throw_move = {
			"move_id": move_id,
			"damage": 6.0,
			"base_knockback": 16.0,
			"knockback_growth": 1.1,
			"angle_deg": 45.0,
			"hitstop_frames": 4,
			"feedback": {"tier": "medium", "hitstop_frames": 5},
			"throw": {"direction": direction, "victim_offset": {"x": 20, "y": -8}},
		}
		match direction:
			"up":
				throw_move["angle_deg"] = 88.0
				throw_move["base_knockback"] = 18.0
				throw_move["throw"] = {"direction": "up", "victim_offset": {"x": 4, "y": -28}}
			"down":
				throw_move["angle_deg"] = 270.0
				throw_move["base_knockback"] = 10.0
				throw_move["throw"] = {"direction": "down", "victim_offset": {"x": 8, "y": 16}}
			"back":
				throw_move["angle_deg"] = 135.0
				throw_move["base_knockback"] = 16.0
				throw_move["throw"] = {"direction": "back", "victim_offset": {"x": -22, "y": -8}}
			_:
				throw_move["angle_deg"] = 38.0
				throw_move["throw"] = {"direction": "forward", "victim_offset": {"x": 22, "y": -8}}
	throw_move = throw_move.duplicate(true)
	throw_move["direction"] = direction
	var throw_cfg: Dictionary = throw_move.get("throw", {})
	if not throw_cfg.is_empty():
		if throw_cfg.has("damage"):
			throw_move["damage"] = throw_cfg.damage
		if throw_cfg.has("angle_deg"):
			throw_move["angle_deg"] = throw_cfg.angle_deg
		if throw_cfg.has("base_knockback"):
			throw_move["base_knockback"] = throw_cfg.base_knockback
		if throw_cfg.has("knockback_growth"):
			throw_move["knockback_growth"] = throw_cfg.knockback_growth
	if attacker != null and attacker.has_method("get_aura"):
		throw_move = _AuraScaler.apply_to_move(throw_move, attacker.aura)
	return throw_move

static func apply_victim_offset(attacker: Node, target: Node, throw_move: Dictionary) -> void:
	var cfg: Dictionary = throw_move.get("throw", {})
	var offset: Dictionary = cfg.get("victim_offset", {"x": 0, "y": 0})
	if target == null or attacker == null:
		return
	var facing: int = attacker.facing if "facing" in attacker else 1
	target.global_position = attacker.global_position + Vector2(
		float(offset.get("x", 0)) * facing,
		float(offset.get("y", 0))
	)
