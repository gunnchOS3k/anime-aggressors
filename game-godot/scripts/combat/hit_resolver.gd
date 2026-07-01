extends Node
class_name HitResolver

signal hit_confirmed(attacker: Node, defender: Node, info: Dictionary)

var _logged: Dictionary = {}

func resolve(attacker: Node, defender: Node, move: Dictionary, attacker_damage_pct: float) -> void:
	if attacker == null or defender == null:
		return
	var weight: float = 100.0
	if defender.has_method("get_weight"):
		weight = defender.get_weight()
	var dealt: float = move.get("damage", 0.0)
	if attacker.has_method("get_damage_dealt_mult"):
		dealt *= attacker.get_damage_dealt_mult()
	var kb := CombatMath.knockback_vector(
		attacker_damage_pct,
		move.get("base_knockback", 6.0),
		move.get("knockback_growth", 1.1),
		move.get("angle_deg", 45.0),
		weight,
		attacker.facing if "facing" in attacker else 1
	)
	var info := {
		"damage": dealt,
		"launch": kb,
		"hitstop_frames": move.get("hitstop_frames", 3),
		"shield_damage": move.get("shield_damage", 0.0),
		"move_id": move.get("move_id", ""),
	}
	if defender.has_method("receive_hit"):
		defender.receive_hit(attacker, info)
	hit_confirmed.emit(attacker, defender, info)
	log_hit("%s -> %s (%s)" % [move.get("move_id",""), defender.name if defender else "?", dealt])

func log_hit(text: String) -> void:
	_logged[Time.get_ticks_msec()] = text

func recent_logs() -> Array:
	return _logged.values()
