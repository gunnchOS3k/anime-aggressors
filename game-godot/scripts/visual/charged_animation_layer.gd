extends RefCounted
class_name ChargedAnimationLayer

## Presentation-only charged performances. Does not change CombatMath.

const READY := true
const BANDS := [0.0, 25.0, 50.0, 75.0, 100.0]
const LOCO_MAP := {
	"idle": "charged_idle",
	"walk": "charged_walk",
	"run": "charged_run",
	"dash": "charged_dash",
	"jump": "charged_jump",
	"fall": "charged_fall",
	"landing": "charged_land",
	"land": "charged_land",
}


static func band_for(aura: float) -> int:
	if aura >= 100.0:
		return 100
	if aura >= 75.0:
		return 75
	if aura >= 50.0:
		return 50
	if aura >= 25.0:
		return 25
	return 0


static func charge_clip_for_band(band: int) -> String:
	match band:
		100:
			return "charge_full"
		75:
			return "charge_high"
		50:
			return "charge_mid"
		25:
			return "charge_low"
		_:
			return "charge_start"


static func layer_for_move(move: Dictionary) -> String:
	var choreo: Dictionary = move.get("choreography", {})
	return str(choreo.get("charged_layer", "none"))


static func overlay_clip(base_clip: String, move: Dictionary, aura: float = 0.0, loaded: Dictionary = {}) -> String:
	var layer := layer_for_move(move)
	if layer == "hold":
		return _prefer(charge_clip_for_band(band_for(aura)), loaded, "charged_hold")
	if layer == "release":
		# Unique burst/super/attack clips stay fighter-specific. Generic charge_release
		# is only for charge-state release, never a silent signature remap.
		if _keeps_attack_identity(base_clip):
			return _prefer("charged_%s" % base_clip, loaded, base_clip)
		return _prefer("charge_release", loaded, base_clip)
	if aura >= 25.0 and LOCO_MAP.has(base_clip):
		return _prefer(str(LOCO_MAP[base_clip]), loaded, base_clip)
	return base_clip


static func _keeps_attack_identity(clip: String) -> bool:
	if clip.begins_with("signature_") or clip.begins_with("aerial_") or clip.begins_with("tilt_") or clip.begins_with("jab"):
		return true
	return clip in [
		"aura_release",
		"super",
		"heavy",
		"grab",
		"projectile_tap",
		"projectile_medium",
		"projectile_full",
		"recovery",
	]


static func should_apply(_fighter_id: String, move: Dictionary) -> bool:
	if not READY:
		return false
	if layer_for_move(move) != "none":
		return true
	return float(move.get("attacker_aura", 0.0)) >= 25.0


static func _prefer(name: String, loaded: Dictionary, fallback: String) -> String:
	if loaded.is_empty() or loaded.has(name):
		return name
	if loaded.has(fallback):
		return fallback
	return name
