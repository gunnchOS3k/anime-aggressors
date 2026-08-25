extends RefCounted
class_name CharacterSelectFraming

## Wave020 revised — per-fighter orthographic preview framing from mesh bounds + VFX envelope.


static func compute_model_bounds(root: Node3D) -> AABB:
	if root == null or not is_instance_valid(root):
		return AABB(Vector3.ZERO, Vector3(0.01, 1.8, 0.01))
	var combined := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mesh := n as MeshInstance3D
			if mesh.mesh == null or not mesh.visible:
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
		return AABB(Vector3(-0.35, 0.0, -0.2), Vector3(0.7, 1.75, 0.4))
	return combined


static func framing_for_fighter(
	fighter_id: String,
	bounds: AABB,
	select_mode: bool,
	vfx_envelope: float = 0.12
) -> Dictionary:
	var height := maxf(bounds.size.y, 0.85)
	var width := maxf(bounds.size.x, 0.35)
	var depth := maxf(bounds.size.z, 0.25)
	var center := bounds.get_center()
	var lean := 0.0
	match fighter_id:
		"rook-ironside":
			lean = 0.08
		"juno-spark":
			lean = -0.04
		"kaia-windrow":
			lean = -0.06
		"orion-vell":
			lean = 0.05
		"vesper-nyx":
			lean = 0.03
	var pad_y := 0.18 + vfx_envelope
	var pad_x := 0.14 + vfx_envelope * 0.6
	var ortho_size := maxf(height * 0.52 + pad_y, width * 0.95 + pad_x)
	if select_mode:
		ortho_size *= 0.92
	var cam_y := center.y + height * 0.06 + pad_y * 0.35
	var cam_z := 4.6 + depth * 0.35 + vfx_envelope
	var look_y := center.y + height * 0.02
	var coverage := clampf(height / (ortho_size * 2.0), 0.0, 1.0)
	var head_y := bounds.position.y + bounds.size.y
	var feet_y := bounds.position.y
	var head_visible := head_y <= cam_y + ortho_size * 0.95
	var feet_visible := feet_y >= cam_y - ortho_size * 0.95
	return {
		"visible_bounds": {
			"min": [bounds.position.x, bounds.position.y, bounds.position.z],
			"max": [bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y, bounds.position.z + bounds.size.z],
			"size": [bounds.size.x, bounds.size.y, bounds.size.z],
		},
		"camera_parameters": {
			"orthographic_size": ortho_size,
			"position": [0.0, cam_y, cam_z],
			"look_at": [0.0, look_y, 0.0],
			"lean_offset": lean,
		},
		"body_coverage": coverage,
		"head_visible": head_visible,
		"feet_visible": feet_visible,
		"silhouette_readable": coverage >= 0.55 and head_visible and feet_visible,
		"flourish_envelope_fit": vfx_envelope,
		"owner_review": "PENDING",
	}
