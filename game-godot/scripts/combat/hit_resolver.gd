extends Node
class_name HitResolver
const _CombatFeedback = preload("res://scripts/combat/combat_feedback.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _AuraSpecialRuntime = preload("res://scripts/combat/aura_special_runtime.gd")
const _CombatMath = preload("res://scripts/combat/combat_math.gd")
const _CombatOutcome = preload("res://scripts/combat/combat_outcome.gd")

signal hit_confirmed(attacker: Node, defender: Node, info: Dictionary)

var _logs: Array = []
var combat_feedback: Node
var _contact_sequence := 0

func resolve(attacker: Node, defender: Node, move: Dictionary, attacker_damage_pct: float) -> Dictionary:
	if attacker == null or defender == null:
		return {}
	if ("invincible" in defender and defender.invincible) or ("grabbed_by" in defender and defender.grabbed_by != null):
		return {}
	if bool(defender.get_meta("story_cosmic_contract", false)):
		# Story manifestations reject ordinary combat damage; competitive Yin/Yang have no such metadata.
		return {}
	if bool(attacker.get_meta("story_released", false)) or bool(defender.get_meta("story_released", false)):
		return {}
	if attacker.has_meta("story_team") and attacker.get_meta("story_team") == defender.get_meta("story_team", ""):
		return {}
	var from_projectile := bool(move.get("_from_projectile", false))
	# Projectile damage is owned by the emitting Area2D's target ledger.
	# A lingering fighter hitbox cannot claim a cast's damage/contact feedback.
	if not from_projectile and (move.has("projectile") or str(move.get("move_type", "")) == "projectile"):
		return {}
	var move_id := str(move.get("move_id", ""))
	var is_direct_throw := move_id.begins_with("throw_") or str(move.get("move_type", "")) == "throw"
	if is_direct_throw:
		# Direct release happens at the existing frame zero, outside active
		# overlap polling, but still consumes this move's target ledger once.
		if attacker.move_runner == null or not attacker.move_runner.active or attacker.move_runner.current_move_id() != move_id or not attacker.move_runner.can_hit_target(defender):
			return {}
	elif not from_projectile:
		if attacker.move_runner == null or not attacker.move_runner.can_hit_target(defender):
			return {}
	if "perfect_guard" in defender:
		var parry: Dictionary = defender.perfect_guard.try_contact(attacker, move)
		if not parry.is_empty():
			parry = _contact_contract(attacker, defender, move, parry)
			if combat_feedback: parry = combat_feedback.apply_hit(attacker, defender, move, parry)
			defender.hit_landed.emit(parry)
			hit_confirmed.emit(attacker, defender, parry)
			_record_hit_telemetry(parry)
			return parry
	# Active armor frames (Rook heavies / Nix ice window) fully gate the hit.
	if "armor_frames_remaining" in defender and float(defender.armor_frames_remaining) > 0.0:
		if "party_overdrive" in defender:defender.party_overdrive.armor_contact()
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
		armor_info = _contact_contract(attacker,defender,move,armor_info)
		if combat_feedback:
			armor_info = combat_feedback.apply_hit(attacker,defender,move,armor_info)
		if defender.has_method("receive_hit"):
			defender.receive_hit(attacker, armor_info)
		if defender.has_method("stamp_runtime_hook"):
			defender.stamp_runtime_hook("passive_armor")
		hit_confirmed.emit(attacker, defender, armor_info)
		log_hit("ARMOR %s -> %s" % [move.get("move_id", ""), defender.name if defender else "?"])
		_record_hit_telemetry(armor_info)
		return armor_info
	var scaled := move
	var aura_amt := 0.0
	var fid := ""
	var tag := ""
	var resolved_form_melee := bool(move.get("_party_move",false)) or (not from_projectile and (bool(move.get("_resolved_form_melee_scaling", false)) or bool(move.get("_resolved_melee_scaling", false))))
	if attacker.has_method("get_aura"):
		aura_amt = float(attacker.get_aura())
		if not resolved_form_melee: scaled = _AuraScaler.apply_to_move(move, aura_amt)
	if "fighter_id" in attacker:
		fid = str(attacker.fighter_id)
	if "data" in attacker and attacker.data is Dictionary:
		tag = str(attacker.data.get("combatTag", ""))
	if fid != "" and not resolved_form_melee:
		scaled = _AuraIdentity.apply_to_scaled_move(scaled, fid, aura_amt, tag)
	var weight: float = 100.0
	if defender.has_method("get_weight"):
		weight = defender.get_weight()
	var dealt: float = float(scaled.get("damage", 0.0))
	var authored_damage: float = float(move.get("damage", dealt))
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
	if fid != "" and not bool(move.get("_party_move",false)):
		kb = _AuraIdentity.modify_knockback(kb, fid, aura_amt, tag)
	if _AuraSpecialRuntime.should_block_hit_with_armor(defender):
		kb *= 0.65
	var info := {
		"damage": dealt,
		"authored_damage": authored_damage,
		"launch": kb,
		"hitstop_frames": int(scaled.get("hitstop_frames", 3)),
		"shield_damage": float(scaled.get("shield_damage", dealt * 0.8)),
		"shield_stun_frames": int(scaled.get("shield_stun_frames", move.get("shield_stun_frames", 0))),
		"move_id": scaled.get("move_id", ""),
		"blocked": false,
		"element": scaled.get("element_effect", {}).get("type", ""),
		"element_effect": scaled.get("element_effect", {}).get("effect", ""),
	}
	if not bool(move.get("_party_move",false)):info = _AuraSpecialRuntime.apply_attacker_on_confirm(attacker, defender, scaled, info)
	for hook in info.get("aura_runtime_hooks", []):
		if attacker != null and attacker.has_method("stamp_runtime_hook"):
			attacker.stamp_runtime_hook(str(hook))
	dealt = float(info.get("damage", dealt))
	kb = info.get("launch", kb)
	# Classify contact before presenting it; receive_hit used to mark block too late.
	if ("shielding" in defender and defender.shielding) or ("state_machine" in defender and defender.state_machine.current_state == "shield_hold"):
		info["blocked"] = true
		info["launch"] = Vector2.ZERO
		info["parry_result"] = "fail"
		info["shield_event"] = "parry_fail"
	info = _contact_contract(attacker,defender,scaled,info)
	if combat_feedback:
		info = combat_feedback.apply_hit(attacker, defender, scaled, info)
		if attacker != null and "last_impact_readable" in attacker:
			attacker.last_impact_readable = true
			attacker.last_feedback_tier = str(info.get("feedback_tier", ""))
	elif attacker.has_node("_CombatFeedback"):
		var fb = attacker.get_node("_CombatFeedback")
		info = fb.apply_hit(attacker, defender, scaled, info)
	if defender.has_method("receive_hit"):
		defender.receive_hit(attacker, info)
	info["actual_launch"] = Vector2.ZERO if info.get("blocked",false) else defender.velocity if "velocity" in defender else info.get("launch",Vector2.ZERO)
	info["actual_defender_state"] = str(defender.state_machine.current_state) if "state_machine" in defender else "unknown"
	if "move_runner" in attacker and attacker.move_runner!=null:
		attacker.move_runner.record_confirmed_contact(info)
	hit_confirmed.emit(attacker, defender, info)
	var hit_tag := "BLOCK" if info.get("blocked", false) else "HIT"
	log_hit("%s %s -> %s dmg:%.1f kb:%.1f" % [hit_tag, scaled.get("move_id", ""), defender.name if defender else "?", dealt, kb.length()])
	_record_hit_telemetry(info)
	return info


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

func _contact_contract(attacker: Node, defender: Node, move: Dictionary, info: Dictionary) -> Dictionary:
	_contact_sequence += 1
	var point: Vector2 = defender.global_position+Vector2(0,-24) if defender is Node2D else Vector2.ZERO
	# World-space center of the real intersecting shape bounds; never a socket guess.
	var hurt = defender.get_node_or_null("Hurtbox/HurtShape") as CollisionShape2D
	var attack = attacker.get_node_or_null("Hitbox/HitShape") as CollisionShape2D
	if move.has("_contact_world"):
		point = move._contact_world
	elif hurt != null and attack != null and hurt.shape != null and attack.shape != null:
		var hr := _world_bounds(hurt)
		var ar := _world_bounds(attack)
		var overlap := hr.intersection(ar)
		point = overlap.get_center() if overlap.has_area() else hr.get_center()
	var launch: Vector2 = info.get("launch",Vector2.ZERO)
	var direction := launch.normalized() if launch.length()>0.01 else Vector2(float(attacker.facing) if "facing" in attacker else 1.0,0)
	info.merge({"combat_event_id":"%s:%s:%s" % [get_instance_id(),Engine.get_physics_frames(),_contact_sequence],
		"confirmed_contact":true,"contact_owner":"projectile" if bool(move.get("_from_projectile",false)) else "direct_throw" if str(move.get("move_id","")).begins_with("throw_") else "melee",
		"attack_activation_id":int(move.get("_attack_activation_id",attacker.move_runner.activation_id if "move_runner" in attacker and attacker.move_runner!=null else -1)),
		"projectile_instance_id":int(move.get("_projectile_instance_id",-1)),"attacker_id":str(attacker.fighter_id) if "fighter_id" in attacker else str(attacker.name),
		"defender_id":str(defender.fighter_id) if "fighter_id" in defender else str(defender.name),
		"gameplay_frame":Engine.get_physics_frames(),"timestamp_usec":Time.get_ticks_usec(),"move_frame":attacker.move_runner.total_frame if "move_runner" in attacker and attacker.move_runner != null else -1,
		"contact_world":point,"contact_direction":direction,"contact_result":"parry" if info.get("perfect_guard",false) else "armor" if info.get("armor_block",false) else "shield" if info.get("blocked",false) else "hit",
		"launch_strength":launch.length(),"defender_damage_before":float(defender.damage_percent) if "damage_percent" in defender else 0.0,
		"defender_airborne":not defender.is_on_floor() if defender is CharacterBody2D else false,
		"combo_count_before":int(attacker.combo_count) if "combo_count" in attacker else 0,
		"counterhit":bool(defender.move_runner.active) if "move_runner" in defender and defender.move_runner != null else false,
		"defender_state_before":str(defender.state_machine.current_state) if "state_machine" in defender else "unknown",
		"defender_in_hitstun_before":defender.state_machine.current_state in ["hitstun","launched","tumble","hurt_light","hurt_heavy"] if "state_machine" in defender else false,
		"parry_supported":true,"clash_supported":false},true)
	return info

func _world_bounds(shape: CollisionShape2D) -> Rect2:
	var rect := shape.shape.get_rect()
	var first := shape.to_global(rect.position)
	var bounds := Rect2(first,Vector2.ZERO)
	for corner in [rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
		bounds = bounds.expand(shape.to_global(corner))
	return bounds
