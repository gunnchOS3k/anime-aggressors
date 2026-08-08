extends RefCounted
class_name AuraIdentity

## Per-fighter aura combat identity applied in REAL combat scripts (not YAML-only).
## Driven by combatTag / fighter id so each of the 7 launch fighters feels distinct in-match.

const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")

const PROFILES := {
	"ember-vale": {
		"tag": "burn_rushdown",
		"charge_rate_mult": 1.12,
		"hitbox_extend_at_level": 2,
		"hitbox_extend_px": 10.0,
		"trail_damage": 1.5,
		"on_hit_aura_gain": 2.0,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.0,
		"launch_angle_bias_deg": 0.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": -1,
	},
	"rook-ironside": {
		"tag": "armor_quake",
		"charge_rate_mult": 0.88,
		"hitbox_extend_at_level": -1,
		"hitbox_extend_px": 0.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 1.0,
		"armor_on_heavies": true,
		"air_drift_bonus": 0.0,
		"launch_angle_bias_deg": -4.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": -1,
	},
	"juno-spark": {
		"tag": "speed_chain",
		"charge_rate_mult": 1.2,
		"hitbox_extend_at_level": -1,
		"hitbox_extend_px": 0.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 3.0,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.05,
		"launch_angle_bias_deg": 0.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": true,
		"ice_armor_at_level": -1,
	},
	"kaia-windrow": {
		"tag": "wind_drift",
		"charge_rate_mult": 1.05,
		"hitbox_extend_at_level": 2,
		"hitbox_extend_px": 6.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 1.5,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.22,
		"launch_angle_bias_deg": 6.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": -1,
	},
	"nix-calder": {
		"tag": "freeze_control",
		"charge_rate_mult": 0.95,
		"hitbox_extend_at_level": -1,
		"hitbox_extend_px": 0.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 1.2,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.0,
		"launch_angle_bias_deg": -2.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": 2,
	},
	"orion-vell": {
		"tag": "gravity_pull",
		"charge_rate_mult": 0.9,
		"hitbox_extend_at_level": -1,
		"hitbox_extend_px": 0.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 1.0,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.0,
		"launch_angle_bias_deg": -12.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": -1,
	},
	"vesper-nyx": {
		"tag": "phase_mark",
		"charge_rate_mult": 1.08,
		"hitbox_extend_at_level": -1,
		"hitbox_extend_px": 0.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 2.5,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.08,
		"launch_angle_bias_deg": 2.0,
		"phase_cancel": true,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": -1,
	},
}


static func profile_for(fighter_id: String, combat_tag: String = "") -> Dictionary:
	if PROFILES.has(fighter_id):
		return PROFILES[fighter_id].duplicate(true)
	for id in PROFILES:
		if str(PROFILES[id].get("tag", "")) == combat_tag:
			return PROFILES[id].duplicate(true)
	return {
		"tag": combat_tag if combat_tag != "" else "generic",
		"charge_rate_mult": 1.0,
		"hitbox_extend_at_level": -1,
		"hitbox_extend_px": 0.0,
		"trail_damage": 0.0,
		"on_hit_aura_gain": 1.0,
		"armor_on_heavies": false,
		"air_drift_bonus": 0.0,
		"launch_angle_bias_deg": 0.0,
		"phase_cancel": false,
		"dash_cancel_after_hit": false,
		"ice_armor_at_level": -1,
	}


static func charge_rate_mult(fighter_id: String, combat_tag: String = "") -> float:
	return float(profile_for(fighter_id, combat_tag).get("charge_rate_mult", 1.0))


static func apply_to_scaled_move(move: Dictionary, fighter_id: String, aura_amount: float, combat_tag: String = "") -> Dictionary:
	## Post-process AuraScaler output with fighter-unique combat identity.
	var scaled := move.duplicate(true)
	var profile := profile_for(fighter_id, combat_tag)
	var level: int = int(_AuraScaler.aura_level(aura_amount))

	var extend_at: int = int(profile.get("hitbox_extend_at_level", -1))
	if extend_at >= 0 and level >= extend_at:
		var extra: float = float(profile.get("hitbox_extend_px", 0.0))
		var boxes: Array = []
		for hb in scaled.get("hitboxes", []):
			var b: Dictionary = hb.duplicate(true)
			b["width"] = int(float(b.get("width", 40)) + extra)
			boxes.append(b)
		scaled["hitboxes"] = boxes
		if float(profile.get("trail_damage", 0.0)) > 0.0:
			scaled["damage"] = float(scaled.get("damage", 0.0)) + float(profile.trail_damage) * float(level)

	var mid := str(scaled.get("move_id", ""))
	var mt := str(scaled.get("move_type", ""))
	var is_heavy := mid.contains("heavy") or mid.contains("dash_attack") or mt == "heavy"
	if profile.get("armor_on_heavies", false) and is_heavy and level >= 2:
		scaled["armor_frames"] = maxi(int(scaled.get("armor_frames", 0)), 4 + level)

	if profile.get("dash_cancel_after_hit", false) and level >= 2:
		scaled["dash_cancel_enabled"] = true
		var windows: Array = scaled.get("cancel_windows", [])
		if windows is Array:
			var w := windows.duplicate()
			var startup: int = int(scaled.get("startup_frames", 0))
			var active_f: int = int(scaled.get("active_frames", 0))
			var recovery: int = int(scaled.get("recovery_frames", 0))
			var start_f: int = maxi(1, startup + active_f - 2)
			var end_f: int = startup + active_f + recovery
			w.append({"start": start_f, "end": end_f, "action": "dash", "requires": "hit_confirm"})
			scaled["cancel_windows"] = w

	if int(profile.get("ice_armor_at_level", -1)) >= 0 and level >= int(profile.ice_armor_at_level):
		scaled["armor_frames"] = maxi(int(scaled.get("armor_frames", 0)), 3)
		var elem: Dictionary = scaled.get("element_effect", {}).duplicate(true)
		elem["type"] = elem.get("type", "chill")
		elem["strength"] = float(elem.get("strength", 1.0)) + 0.25 * float(level)
		scaled["element_effect"] = elem

	var bias: float = float(profile.get("launch_angle_bias_deg", 0.0))
	if absf(bias) > 0.01 and level >= 1:
		scaled["angle_deg"] = float(scaled.get("angle_deg", 45.0)) + bias * (float(level) / 4.0)

	if profile.get("phase_cancel", false) and level >= 2 and str(scaled.get("input_command", "")).begins_with("special"):
		scaled["phase_cancel_frames"] = 6 + level

	scaled["aura_identity_tag"] = str(profile.get("tag", ""))
	return scaled


static func modify_knockback(kb: Vector2, fighter_id: String, aura_amount: float, combat_tag: String = "") -> Vector2:
	var profile := profile_for(fighter_id, combat_tag)
	var level: int = int(_AuraScaler.aura_level(aura_amount))
	var bias: float = float(profile.get("launch_angle_bias_deg", 0.0))
	if absf(bias) < 0.01 or level < 1:
		return kb
	# Rotate launch slightly toward fighter identity (Orion pulls down, Kaia lifts).
	var rad := deg_to_rad(bias * (float(level) / 4.0) * 0.35)
	var cos_r := cos(rad)
	var sin_r := sin(rad)
	return Vector2(kb.x * cos_r - kb.y * sin_r, kb.x * sin_r + kb.y * cos_r)


static func air_drift_bonus(fighter_id: String, aura_amount: float, combat_tag: String = "") -> float:
	var profile := profile_for(fighter_id, combat_tag)
	var level: int = int(_AuraScaler.aura_level(aura_amount))
	if level < 1:
		return 0.0
	return float(profile.get("air_drift_bonus", 0.0)) * (float(level) / 4.0)


static func on_hit_aura_gain(fighter_id: String, combat_tag: String = "") -> float:
	return float(profile_for(fighter_id, combat_tag).get("on_hit_aura_gain", 1.0))


static func has_passive_armor(fighter_id: String, aura_amount: float, combat_tag: String = "") -> bool:
	var profile := profile_for(fighter_id, combat_tag)
	var level: int = int(_AuraScaler.aura_level(aura_amount))
	if profile.get("armor_on_heavies", false) and level >= 3:
		return true
	var ice_at: int = int(profile.get("ice_armor_at_level", -1))
	return ice_at >= 0 and level >= ice_at


static func all_fighter_ids() -> Array:
	return PROFILES.keys()
