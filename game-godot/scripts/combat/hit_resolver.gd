extends Node
class_name HitResolver

signal hit_confirmed(attacker: Node, defender: Node, info: Dictionary)

var _logs: Array = []

func resolve(attacker: Node, defender: Node, move: Dictionary, attacker_damage_pct: float) -> void:
	if attacker == null or defender == null:
		return
	if not attacker.move_runner.can_hit_target(defender):
		return
	var weight: float = 100.0
	if defender.has_method("get_weight"):
		weight = defender.get_weight()
	var dealt: float = float(move.get("damage", 0.0))
	if attacker.has_method("get_damage_dealt_mult"):
		dealt *= attacker.get_damage_dealt_mult()
	var kb := CombatMath.knockback_vector(
		defender.damage_percent if "damage_percent" in defender else attacker_damage_pct,
		float(move.get("base_knockback", 6.0)),
		float(move.get("knockback_growth", 1.1)),
		float(move.get("angle_deg", 45.0)),
		weight,
		attacker.facing if "facing" in attacker else 1
	)
	var info := {
		"damage": dealt,
		"launch": kb,
		"hitstop_frames": int(move.get("hitstop_frames", 3)),
		"shield_damage": float(move.get("shield_damage", dealt * 0.8)),
		"move_id": move.get("move_id", ""),
		"blocked": false,
	}
	if defender.has_method("receive_hit"):
		defender.receive_hit(attacker, info)
	hit_confirmed.emit(attacker, defender, info)
	var tag := "BLOCK" if info.get("blocked", false) else "HIT"
	log_hit("%s %s -> %s dmg:%.1f kb:%.1f" % [tag, move.get("move_id", ""), defender.name if defender else "?", dealt, kb.length()])

func log_hit(text: String) -> void:
	_logs.append(text)
	if _logs.size() > 24:
		_logs.pop_front()

func recent_logs() -> Array:
	return _logs.duplicate()
