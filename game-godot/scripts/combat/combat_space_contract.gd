extends RefCounted
class_name CombatSpaceContract

## Authoritative fighter↔stage proportion contract (VXP-2.2 human-feedback closure).
## Visual scale, collision capsule, platform width, jump reach, and ledge windows
## must stay coherent — do not enlarge stage OR shrink visuals in isolation.

const BATTLE_DISPLAY_SCALE := Vector2(0.58, 0.58)
const MAX_BATTLE_DISPLAY_SCALE := 0.72
## Visual footprint (viewport * display scale) vs main-platform width ratio band.
const MIN_VISUAL_TO_PLATFORM_RATIO := 0.12
const MAX_VISUAL_TO_PLATFORM_RATIO := 0.28
const DEFAULT_HURT_W := 40.0
const DEFAULT_HURT_H := 48.0
const LEDGE_GRAB_X_TOLERANCE := 42.0
const LEDGE_GRAB_Y_ABOVE := 28.0
const LEDGE_GRAB_Y_BELOW := 96.0
const LEDGE_HANG_DROP := 22.0
const LEDGE_SNAP_MAX_SPEED_UP := 40.0


static func visual_footprint_px(display_scale: Vector2 = BATTLE_DISPLAY_SCALE, viewport: Vector2i = Vector2i(256, 320)) -> Vector2:
	return Vector2(float(viewport.x) * absf(display_scale.x), float(viewport.y) * absf(display_scale.y))


static func visual_to_platform_ratio(platform_width: float, display_scale: Vector2 = BATTLE_DISPLAY_SCALE) -> float:
	var foot := visual_footprint_px(display_scale)
	if platform_width <= 1.0:
		return 999.0
	return foot.x / platform_width


static func ratio_in_band(platform_width: float, display_scale: Vector2 = BATTLE_DISPLAY_SCALE) -> bool:
	var r := visual_to_platform_ratio(platform_width, display_scale)
	return r >= MIN_VISUAL_TO_PLATFORM_RATIO and r <= MAX_VISUAL_TO_PLATFORM_RATIO


static func hurt_size_from_profile(profile: Dictionary) -> Vector2:
	return Vector2(
		float(profile.get("hurtboxWidth", DEFAULT_HURT_W)),
		float(profile.get("hurtboxHeight", DEFAULT_HURT_H)),
	)


static func collision_size_from_profile(profile: Dictionary) -> Vector2:
	var hurt := hurt_size_from_profile(profile)
	# Capsule-ish rect slightly smaller than hurt for forgiveness.
	return Vector2(maxf(24.0, hurt.x * 0.9), maxf(36.0, hurt.y * 0.95))


static func ledge_hang_position(anchor_x: float, surface_y: float, side: int) -> Vector2:
	return Vector2(anchor_x, surface_y + LEDGE_HANG_DROP)


static func in_ledge_grab_window(pos: Vector2, anchor: Vector2, rising_too_fast: bool) -> bool:
	if rising_too_fast:
		return false
	if absf(pos.x - anchor.x) > LEDGE_GRAB_X_TOLERANCE:
		return false
	var dy := pos.y - anchor.y
	return dy >= -LEDGE_GRAB_Y_ABOVE and dy <= LEDGE_GRAB_Y_BELOW


static func snapshot_for_stage(stage: Dictionary, display_scale: Vector2 = BATTLE_DISPLAY_SCALE) -> Dictionary:
	var main: Dictionary = stage.get("mainPlatform", {})
	var width := float(main.get("width", 800))
	var ratio := visual_to_platform_ratio(width, display_scale)
	var foot := visual_footprint_px(display_scale)
	return {
		"stage_id": str(stage.get("id", "")),
		"platform_width": width,
		"platform_y": float(main.get("y", 280)),
		"visual_w": foot.x,
		"visual_h": foot.y,
		"visual_to_platform_ratio": ratio,
		"ratio_in_band": ratio_in_band(width, display_scale),
		"ledges": bool(stage.get("ledges", true)),
		"ledge_anchors": stage.get("ledgeAnchors", []),
		"blast": stage.get("blastZones", {}),
	}
