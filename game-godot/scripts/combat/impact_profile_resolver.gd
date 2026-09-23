extends RefCounted
class_name ImpactProfileResolver

## Resolves light|medium|heavy|aura|super|ko presentation profiles.
## Does not author knockback. Physics stays in CombatMath.

const PROFILE_PATH := "res://data/combat/impact_profiles.json"
const VALID_TIERS := ["light", "medium", "heavy", "aura", "super", "ko"]

static var _doc: Dictionary = {}
static var _loaded := false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PROFILE_PATH):
		_doc = {}
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		_doc = {}
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	_doc = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func valid_tiers() -> Array:
	return VALID_TIERS.duplicate()


static func profile_for_tier(tier: String) -> Dictionary:
	_ensure()
	var profiles: Dictionary = _doc.get("profiles", {})
	var key := normalize_tier(tier)
	var raw: Dictionary = profiles.get(key, profiles.get("light", {}))
	var out := raw.duplicate(true)
	out["tier"] = key
	return out


static func normalize_tier(tier: String) -> String:
	var t := tier.strip_edges().to_lower()
	if t in VALID_TIERS:
		return t
	return "light"


static func resolve(move: Dictionary, context: Dictionary = {}) -> Dictionary:
	_ensure()
	var forced := str(context.get("force_tier", ""))
	if forced.is_empty() and Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and "training_force_hit_tier" in gs:
			forced = str(gs.training_force_hit_tier)
	var source := "move_type_default"
	var tier := ""
	if forced != "" and forced in VALID_TIERS:
		tier = forced
		source = "training_force_tier"
	if tier.is_empty():
		var explicit := str(move.get("impact_profile", ""))
		if explicit in VALID_TIERS:
			tier = explicit
			source = "explicit_impact_profile"
	if tier.is_empty():
		var fb: Dictionary = move.get("feedback", {})
		var fb_tier := str(fb.get("tier", ""))
		if fb_tier in VALID_TIERS:
			tier = fb_tier
			source = "feedback.tier"
	if tier.is_empty():
		tier = _default_from_move(move)
		source = "move_type_default"
	if bool(context.get("is_ko", false)) or bool(move.get("ko_class", false)):
		tier = "ko"
		source = "ko_upgrade"
	elif source != "training_force_tier":
		var aura_amt := float(context.get("attacker_aura", 0.0))
		var aura_ready := bool(context.get("aura_ready", false))
		if aura_ready or aura_amt >= float(context.get("aura_threshold", 100.0)):
			if str(move.get("move_id", "")).begins_with("aura") or str(move.get("move_type", "")) == "burst":
				tier = "aura"
				source = "aura_upgrade"
	var profile := profile_for_tier(tier)
	profile["resolution_source"] = source
	profile["silent_special_fallback"] = false
	profile["contact_class"] = _contact_class(tier, context)
	return profile


static func _contact_class(tier: String, context: Dictionary) -> String:
	if bool(context.get("whiff", false)):
		return "whiff"
	if bool(context.get("blocked", false)) or bool(context.get("shield", false)):
		return "shield"
	if tier == "super":
		return "aura"
	return tier


static func _default_from_move(move: Dictionary) -> String:
	var mid := str(move.get("move_id", ""))
	var mtype := str(move.get("move_type", ""))
	if mid == "special" or mtype == "special":
		# Refuse silent generic special. Require explicit mapping.
		return "medium"
	if mid.begins_with("jab") or mid.ends_with("_tilt") or mid == "forward_tilt" or mid == "up_tilt" or mid == "down_tilt":
		return "light"
	if mid.begins_with("throw_") or mid == "heavy_attack" or mid == "dash_attack" or mid.contains("smash"):
		return "heavy"
	if mid.begins_with("aura") or mtype == "burst":
		return "aura"
	if mid.contains("signature_lane_finisher") or mid.contains("signature_lane_burst"):
		return "aura"
	if mtype == "projectile":
		return "medium"
	return "medium"


static func schema_ok() -> bool:
	_ensure()
	if str(_doc.get("schema_id", "")) != "anime_aggressors.impact_profile.v1":
		return false
	var profiles: Dictionary = _doc.get("profiles", {})
	for tier in VALID_TIERS:
		if not profiles.has(tier):
			return false
		var p: Dictionary = profiles[tier]
		if int(p.get("attacker_hitstop_frames", -1)) != int(p.get("defender_hitstop_frames", -2)):
			return false
		if not bool(p.get("hitstop_sync", false)):
			return false
	return bool(_doc.get("no_silent_special_fallback", false))
