extends Node
class_name HitResolver
const _CombatFeedback = preload("res://scripts/combat/combat_feedback.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _AuraSpecialRuntime = preload("res://scripts/combat/aura_special_runtime.gd")
const _CombatMath = preload("res://scripts/combat/combat_math.gd")

signal hit_confirmed(attacker: Node, defender: Node, info: Dictionary)

var _logs: Array = []
var combat_feedback: Node

func resolve(attacker: Node, defender: Node, move: Dictionary, attacker_damage_pct: float) -> void:
	if attacker == null or defender == null:
		return
	var from_projectile := bool(move.get("_from_projectile", false))
	var move_id := str(move.get("move_id", ""))
	var is_direct_throw := move_id.begins_with("throw_") or str(move.get("move_type", "")) == "throw"
	if not from_projectile and not is_direct_throw:
		if attacker.move_runner == null or not attacker.move_runner.can_hit_target(defender):
			return
	# Active armor frames (Rook heavies / Nix ice window) fully gate the hit.
	if "armor_frames_remaining" in defender and float(defender.armor_frames_remaining) > 0.0:
		var armor_info := {
			"damage": 0.0,
			"launch": Vector2.ZERO,
			"hitstop_frames": 2,
			"shield_damage": 0.0,
			"move_id": move.get("move_id", ""),
			"blocked": true,
			"armor_block": true,
			"element": "",
			"element_effect": "",
		}
		if defender.has_method("receive_hit"):
			defender.receive_hit(attacker, armor_info)
		if defender.has_method("stamp_runtime_hook"):
			defender.stamp_runtime_hook("passive_armor")
		hit_confirmed.emit(attacker, defender, armor_info)
		log_hit("ARMOR %s -> %s" % [move.get("move_id", ""), defender.name if defender else "?"])
		_record_hit_telemetry(armor_info)
		return
	var scaled := move
	var aura_amt := 0.0
	var fid := ""
	var tag := ""
	if attacker.has_method("get_aura"):
		aura_amt = float(attacker.get_aura())
		scaled = _AuraScaler.apply_to_move(move, aura_amt)
	if "fighter_id" in attacker:
		fid = str(attacker.fighter_id)
	if "data" in attacker and attacker.data is Dictionary:
		tag = str(attacker.data.get("combatTag", ""))
	if fid != "":
		scaled = _AuraIdentity.apply_to_scaled_move(scaled, fid, aura_amt, tag)
	var weight: float = 100.0
	if defender.has_method("get_weight"):
		weight = defender.get_weight()
	var dealt: float = float(scaled.get("damage", 0.0))
	if attacker.has_method("get_damage_dealt_mult"):
		dealt *= attacker.get_damage_dealt_mult()
	if "damage_ratio" in GameState:
		dealt *= float(GameState.damage_ratio)
	if attacker.has_method("stale_repeat_count"):
		dealt *= _CombatMath.stale_multiplier(int(attacker.stale_repeat_count(str(scaled.get("move_id", "")))))
	if "combo_count" in attacker:
		dealt *= _CombatMath.combo_decay(int(attacker.combo_count))
	# Passive aura armor (Rook L3+ / Nix ice) chips damage — script runtime, not data-only.
	if _AuraSpecialRuntime.should_block_hit_with_armor(defender):
		dealt *= 0.55
		if defender.has_method("stamp_runtime_hook"):
			defender.stamp_runtime_hook("passive_armor")
	var kb: Vector2 = _CombatMath.knockback_vector(
		defender.damage_percent if "damage_percent" in defender else attacker_damage_pct,
		float(scaled.get("base_knockback", 6.0)),
		float(scaled.get("knockback_growth", 1.1)),
		float(scaled.get("angle_deg", 45.0)),
		weight,
		attacker.facing if "facing" in attacker else 1
	)
	if fid != "":
		kb = _AuraIdentity.modify_knockback(kb, fid, aura_amt, tag)
	if _AuraSpecialRuntime.should_block_hit_with_armor(defender):
		kb *= 0.65
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
	info = _AuraSpecialRuntime.apply_attacker_on_confirm(attacker, defender, scaled, info)
	for hook in info.get("aura_runtime_hooks", []):
		if attacker != null and attacker.has_method("stamp_runtime_hook"):
			attacker.stamp_runtime_hook(str(hook))
	dealt = float(info.get("damage", dealt))
	kb = info.get("launch", kb)
	if combat_feedback:
		info = combat_feedback.apply_hit(attacker, defender, scaled, info)
		if combat_feedback.has_method("spawn_hit_spark") and defender is Node2D:
			combat_feedback.spawn_hit_spark(defender, defender.global_position + Vector2(0, -24), str(info.get("element", "")))
		if attacker != null and "last_impact_readable" in attacker:
			attacker.last_impact_readable = true
			attacker.last_feedback_tier = str(info.get("feedback_tier", ""))
	elif attacker.has_node("_CombatFeedback"):
		var fb = attacker.get_node("_CombatFeedback")
		info = fb.apply_hit(attacker, defender, scaled, info)
	if defender.has_method("receive_hit"):
		defender.receive_hit(attacker, info)
	hit_confirmed.emit(attacker, defender, info)
	var hit_tag := "BLOCK" if info.get("blocked", false) else "HIT"
	log_hit("%s %s -> %s dmg:%.1f kb:%.1f" % [hit_tag, scaled.get("move_id", ""), defender.name if defender else "?", dealt, kb.length()])
	_record_hit_telemetry(info)


func _record_hit_telemetry(info: Dictionary) -> void:
	# record_hit() existed on MatchTelemetry but was never called from the
	# real hit-resolution path — only match_start/match_end and KO/stock-loss
	# (fighter.gd:lose_stock) were wired, so H2H hits landed with no
	# inspectable telemetry event at all.
	var telem := get_node_or_null("/root/MatchTelemetry")
	if telem and telem.has_method("record_hit"):
		telem.record_hit(info)

func log_hit(text: String) -> void:
	_logs.append(text)
	if _logs.size() > 24:
		_logs.pop_front()

func recent_logs() -> Array:
	return _logs.duplicate()
