extends RefCounted
class_name CharacterSelectFraming

## Geometry-aware framing. Delegates to GeometryAutoFit — no per-fighter scale hacks.

const _Fit = preload("res://scripts/visual/geometry_auto_fit.gd")


static func compute_model_bounds(root: Node3D) -> AABB:
	return _Fit.compute_visible_aabb(root)


static func framing_for_fighter(
	fighter_id: String,
	bounds: AABB,
	select_mode: bool,
	vfx_envelope: float = 0.12
) -> Dictionary:
	var context := "SELECT_PREVIEW" if select_mode else "BATTLE"
	var report := _Fit.framing_for_bounds(bounds, context, vfx_envelope)
	report["fighter_id"] = fighter_id
	report["per_fighter_magic_scale"] = false
	return report


static func framing_for_context(fighter_id: String, bounds: AABB, context: String, vfx_envelope: float = 0.12) -> Dictionary:
	var report := _Fit.framing_for_bounds(bounds, context, vfx_envelope)
	report["fighter_id"] = fighter_id
	report["per_fighter_magic_scale"] = false
	return report
