extends RefCounted
class_name AuraScaler

## Resolves aura amount into levels and applies aura_scaling to move data.

const LEVELS := [
	{"min": 0, "max": 24, "level": 0, "name": "base"},
	{"min": 25, "max": 49, "level": 1, "name": "level_1"},
	{"min": 50, "max": 74, "level": 2, "name": "level_2"},
	{"min": 75, "max": 99, "level": 3, "name": "level_3"},
	{"min": 100, "max": 100, "level": 4, "name": "super_ready"},
]

static func aura_level(aura_amount: float) -> int:
	for entry in LEVELS:
		if aura_amount >= entry.min and aura_amount <= entry.max:
			return entry.level
	return 0

static func aura_level_name(aura_amount: float) -> String:
	for entry in LEVELS:
		if aura_amount >= entry.min and aura_amount <= entry.max:
			return entry.name
	return "base"

static func apply_to_move(move: Dictionary, aura_amount: float) -> Dictionary:
	var scaled := move.duplicate(true)
	var level := aura_level(aura_amount)
	var scaling: Dictionary = move.get("aura_scaling", {})
	if scaling.is_empty():
		return scaled
	var tier_key := "level_%d" % level if level < 4 else "super_ready"
	var tier: Dictionary = scaling.get(tier_key, scaling.get("base", {}))
	if tier.is_empty() and level > 0:
		tier = scaling.get("level_0", {})
	if tier.has("damage_mult"):
		scaled["damage"] = float(scaled.get("damage", 0)) * float(tier.damage_mult)
	if tier.has("knockback_mult"):
		scaled["base_knockback"] = float(scaled.get("base_knockback", 0)) * float(tier.knockback_mult)
	if tier.has("hitbox_scale"):
		var scale := float(tier.hitbox_scale)
		var boxes: Array = []
		for hb in scaled.get("hitboxes", []):
			var b: Dictionary = hb.duplicate(true)
			b["width"] = int(float(b.get("width", 40)) * scale)
			b["height"] = int(float(b.get("height", 32)) * scale)
			boxes.append(b)
		scaled["hitboxes"] = boxes
	if tier.has("extra_active_frames"):
		scaled["active_frames"] = int(scaled.get("active_frames", 0)) + int(tier.extra_active_frames)
	if tier.has("armor_frames"):
		scaled["armor_frames"] = int(tier.armor_frames)
	if tier.has("cancel_windows"):
		scaled["cancel_windows"] = tier.cancel_windows
	if tier.has("element_strength"):
		var elem: Dictionary = scaled.get("element_effect", {}).duplicate(true)
		elem["strength"] = float(tier.element_strength)
		scaled["element_effect"] = elem
	if tier.has("feedback_tier"):
		var fb: Dictionary = scaled.get("feedback", {}).duplicate(true)
		fb["tier"] = tier.feedback_tier
		scaled["feedback"] = fb
	if tier.has("projectile_overrides") and scaled.has("projectile"):
		var proj: Dictionary = scaled.projectile.duplicate(true)
		for k in tier.projectile_overrides:
			proj[k] = tier.projectile_overrides[k]
		scaled["projectile"] = proj
	return scaled

static func projectile_value_by_aura(arr: Array, aura_amount: float) -> float:
	if arr.is_empty():
		return 0.0
	var level := aura_level(aura_amount)
	var idx := mini(level, arr.size() - 1)
	return float(arr[idx])

static func validate_scaling_not_damage_only(scaling: Dictionary) -> bool:
	if scaling.is_empty():
		return false
	var has_non_damage := false
	for tier_key in scaling:
		var tier: Dictionary = scaling[tier_key]
		for k in tier:
			if k != "damage_mult" and k != "knockback_mult":
				has_non_damage = true
				break
		if has_non_damage:
			break
	return has_non_damage
