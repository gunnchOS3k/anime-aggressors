extends SceneTree

## Structural facing / mapping / VFX checks. Does not set HUMAN_* gates.

const _Facing = preload("res://scripts/combat/fighter_facing_contract.gd")
const _Hit = preload("res://scripts/combat/directional_hit_reaction.gd")
const _Signature = preload("res://scripts/visual/signature_move_presentation.gd")
const _Vfx = preload("res://scripts/visual/elemental_vfx_family.gd")
const _Material = preload("res://scripts/visual/elemental_material_contract.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]


func _init() -> void:
	var failures: PackedStringArray = []
	if not _Facing.attack_faces_target("RIGHT", 100.0, 200.0):
		failures.append("right_attack_should_face_right_target")
	if not _Facing.attack_faces_target("LEFT", 200.0, 100.0):
		failures.append("left_attack_should_face_left_target")
	if _Facing.projectile_sign(1, -1) != 1:
		failures.append("projectile_should_keep_attack_lock")
	var right_hurt: Dictionary = _Facing.hurt_away_from_force(Vector2(1, 0))
	var left_hurt: Dictionary = _Facing.hurt_away_from_force(Vector2(-1, 0))
	if str(right_hurt.get("logical_facing")) != "LEFT":
		failures.append("hurt_from_left_should_face_left")
	if str(left_hurt.get("logical_facing")) != "RIGHT":
		failures.append("hurt_from_right_should_face_right")
	if not _Facing.launch_follows_force(Vector2(8, -3)):
		failures.append("launch_should_follow_force")
	if not _Signature.mapping_complete():
		failures.append("signature_mapping_incomplete")
	if not _Vfx.complete():
		failures.append("vfx_families_incomplete")
	var silhouettes := {}
	for fid in FIGHTERS:
		if not _Material.has_three_value_groups(fid):
			failures.append("material_missing:%s" % fid)
		if _Material.has_method("has_layered_identity") and not _Material.has_layered_identity(fid):
			failures.append("layered_identity_missing:%s" % fid)
		var colors: Dictionary = _Material.identity_colors(fid) if _Material.has_method("identity_colors") else {}
		if colors.is_empty() or not colors.has("tile_primary"):
			failures.append("identity_colors_missing:%s" % fid)
		var sil := _Signature.unique_super_silhouette(fid)
		if sil.is_empty() or silhouettes.has(sil):
			failures.append("super_silhouette_not_unique:%s" % fid)
		silhouettes[sil] = true
		var families: Array = _Hit.families()
		if families.size() != 6:
			failures.append("hit_families:%s" % fid)
	if failures.is_empty():
		print("ELEMENTAL_SPECIALS_STRUCTURAL_TEST=PASS")
		quit(0)
	else:
		print("ELEMENTAL_SPECIALS_STRUCTURAL_TEST=FAIL")
		for row in failures:
			print("FAIL %s" % row)
		quit(1)
