extends Node
class_name HitResolver

signal hit_confirmed(attacker: Node, defender: Node, info: Dictionary)

var _logs: Array = []
var combat_feedback: CombatFeedback

func resolve(attacker: Node, defender: Node, move: Dictionary, attacker_damage_pct: float) -> void:
	if attacker == null or defender == null:
		return
	if not attacker.move_runner.can_hit_target(defender):
		return
	var scaled := move
	if attacker.has_method("get_aura"):
		scaled = AuraScaler.apply_to_move(move, attacker.get_aura())
	var weight: float = 100.0
	if defender.has_method("get_weight"):
		weight = defender.get_weight()
	var dealt: float = float(scaled.get("damage", 0.0))
	if attacker.has_method("get_damage_dealt_mult"):
		dealt *= attacker.get_damage_dealt_mult()
	var kb := CombatMath.knockback_vector(
		defender.damage_percent if "damage_percent" in defender else attacker_damage_pct,
		float(scaled.get("base_knockback", 6.0)),
		float(scaled.get("knockback_growth", 1.1)),
		float(scaled.get("angle_deg", 45.0)),
		weight,
		attacker.facing if "facing" in attacker else 1
	)
	var info := {
		"damage": dealt,
		"launch": kb,
		"hitstop_frames": int(scaled.get("hitstop_frames", 3)),
		"shield_damage": float(scaled.get("shield_damage", dealt * 0.8)),
		"move_id": scaled.get("move_id", ""),
		"blocked": false,
		"element": scaled.get("element_effect", {}).get("type", ""),
		"element_effect": scaled.get("element_effect", {}).get("effect", ""),
	}
	if combat_feedback:
		info = combat_feedback.apply_hit(attacker, defender, scaled, info)
	elif attacker.has_node("CombatFeedback"):
		var fb: CombatFeedback = attacker.get_node("CombatFeedback")
		info = fb.apply_hit(attacker, defender, scaled, info)
	if defender.has_method("receive_hit"):
		defender.receive_hit(attacker, info)
	hit_confirmed.emit(attacker, defender, info)
	var tag := "BLOCK" if info.get("blocked", false) else "HIT"
	log_hit("%s %s -> %s dmg:%.1f kb:%.1f" % [tag, scaled.get("move_id", ""), defender.name if defender else "?", dealt, kb.length()])

func log_hit(text: String) -> void:
	_logs.append(text)
	if _logs.size() > 24:
		_logs.pop_front()

func recent_logs() -> Array:
	return _logs.duplicate()
