extends RefCounted
class_name GeometryAutoFit

## Bounds-driven camera/wrapper adaptation. Never mutates canonical source assets.
## Occupancy is context-local. No per-fighter magic scale table.

const CTX_SELECT_CARD := "SELECT_CARD"
const CTX_SELECT_PREVIEW := "SELECT_PREVIEW"
const CTX_SHOWCASE := "SHOWCASE"
const CTX_VERSUS := "VERSUS"
const CTX_MATCH_START := "MATCH_START"
const CTX_BATTLE := "BATTLE"
const CTX_VICTORY := "VICTORY"

const OCCUPANCY := {
	"SELECT_CARD": {"min": 0.72, "max": 0.86, "target": 0.79},
	"SELECT_PREVIEW": {"min": 0.72, "max": 0.88, "target": 0.80},
	"SHOWCASE": {"min": 0.72, "max": 0.88, "target": 0.80},
	"VERSUS": {"min": 0.68, "max": 0.84, "target": 0.76},
	"MATCH_START": {"min": 0.68, "max": 0.84, "target": 0.76},
	"BATTLE": {"min": 0.0, "max": 1.0, "target": 0.0},
	"VICTORY": {"min": 0.70, "max": 0.88, "target": 0.78},
}

const VFX_ONLY_TOKENS := [
	"vfx", "fx", "trail", "particle", "aura", "spark", "burst", "ribbon_fx",
]
const HIDDEN_PROP_TOKENS := [
	"hidden", "lod_off", "collision", "hitbox", "hurtbox",
]


static func compute_visible_aabb(root: Node3D) -> AABB:
	if root == null or not is_instance_valid(root):
		return AABB(Vector3(-0.32, 0.0, -0.18), Vector3(0.64, 1.72, 0.36))
	if not root.is_inside_tree():
		return AABB(Vector3(-0.32, 0.0, -0.18), Vector3(0.64, 1.72, 0.36))
	var combined := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mesh := n as MeshInstance3D
			if mesh.mesh == null or not mesh.visible:
				continue
			if _exclude_mesh(mesh):
				continue
			var local := mesh.get_aabb()
			var xf := root.global_transform.affine_inverse() * mesh.global_transform
			var world := xf * local
			if first:
				combined = world
				first = false
			else:
				combined = combined.merge(world)
		for c in n.get_children():
			stack.append(c)
	if first:
		return AABB(Vector3(-0.32, 0.0, -0.18), Vector3(0.64, 1.72, 0.36))
	return combined


static func _exclude_mesh(mesh: MeshInstance3D) -> bool:
	var token := ("%s %s" % [mesh.name, mesh.get_parent().name if mesh.get_parent() else ""]).to_lower()
	for key in VFX_ONLY_TOKENS:
		if token.contains(key):
			return true
	for key in HIDDEN_PROP_TOKENS:
		if token.contains(key):
			return true
	return false


static func occupancy_for(context: String) -> Dictionary:
	var ctx := context
	if ctx == "BATTLE_P1" or ctx == "BATTLE_P2_CPU" or ctx == "TRAINING":
		ctx = CTX_BATTLE
	if ctx == CTX_SHOWCASE:
		ctx = CTX_SELECT_PREVIEW
	return OCCUPANCY.get(ctx, OCCUPANCY[CTX_SELECT_PREVIEW])


static func framing_for_bounds(bounds: AABB, context: String, vfx_envelope: float = 0.10) -> Dictionary:
	var occ: Dictionary = occupancy_for(context)
	var height := maxf(bounds.size.y, 0.85)
	var width := maxf(bounds.size.x, 0.30)
	var depth := maxf(bounds.size.z, 0.22)
	var center := bounds.get_center()
	var target := float(occ.get("target", 0.78))
	var occ_min := float(occ.get("min", 0.68))
	var occ_max := float(occ.get("max", 0.88))
	var pad := 0.10 + vfx_envelope
	var visual_center := Vector3(center.x, bounds.position.y + height * 0.48, center.z)
	var ortho := height / maxf(target * 2.0, 0.2)
	ortho = maxf(ortho, (width + pad) * 0.55)
	var coverage := clampf(height / maxf(ortho * 2.0, 0.01), 0.0, 1.0)
	if context != CTX_BATTLE:
		if coverage < occ_min:
			ortho = height / maxf(occ_min * 2.0, 0.2)
			coverage = clampf(height / maxf(ortho * 2.0, 0.01), 0.0, 1.0)
		elif coverage > occ_max:
			ortho = height / maxf(occ_max * 2.0, 0.2)
			coverage = clampf(height / maxf(ortho * 2.0, 0.01), 0.0, 1.0)
	var head_y := bounds.position.y + bounds.size.y
	var feet_y := bounds.position.y
	var cam_y := visual_center.y
	var margin := 0.96
	var head_visible := head_y <= cam_y + ortho * margin
	var feet_visible := feet_y >= cam_y - ortho * margin
	if not head_visible or not feet_visible:
		var span := maxf(head_y - cam_y, cam_y - feet_y)
		ortho = maxf(ortho, span / margin + pad * 0.25)
		head_visible = head_y <= cam_y + ortho * margin
		feet_visible = feet_y >= cam_y - ortho * margin
		coverage = clampf(height / maxf(ortho * 2.0, 0.01), 0.0, 1.0)
	var cam_z := 4.7 + depth * 0.32 + vfx_envelope
	var look_y := visual_center.y
	var cam_x := 0.16 if context in [CTX_SELECT_CARD, CTX_SELECT_PREVIEW, CTX_SHOWCASE] else 0.0
	var clip_ok := head_visible and feet_visible
	return {
		"context": context,
		"visible_bounds": {
			"min": [bounds.position.x, bounds.position.y, bounds.position.z],
			"max": [bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y, bounds.position.z + bounds.size.z],
			"size": [bounds.size.x, bounds.size.y, bounds.size.z],
		},
		"world_height": height,
		"world_width": width,
		"visual_center": [visual_center.x, visual_center.y, visual_center.z],
		"camera_parameters": {
			"orthographic_size": ortho,
			"position": [cam_x, cam_y, cam_z],
			"look_at": [0.0, look_y, 0.0],
			"lean_offset": 0.0,
		},
		"body_coverage": coverage,
		"occupancy_target": target,
		"occupancy_min": occ_min,
		"occupancy_max": occ_max,
		"head_visible": head_visible,
		"feet_visible": feet_visible,
		"no_clip": clip_ok,
		"silhouette_readable": clip_ok and (context == CTX_BATTLE or (coverage >= occ_min and coverage <= occ_max + 0.02)),
		"flourish_envelope_fit": vfx_envelope,
		"owner_review": "PENDING",
	}


static func pair_height_ratio(a: Dictionary, b: Dictionary) -> float:
	var ha := maxf(float(a.get("world_height", 1.0)), 0.01)
	var hb := maxf(float(b.get("world_height", 1.0)), 0.01)
	return maxf(ha, hb) / minf(ha, hb)


static func pair_visible(a: Dictionary, b: Dictionary) -> bool:
	return bool(a.get("no_clip", false)) and bool(b.get("no_clip", false))
