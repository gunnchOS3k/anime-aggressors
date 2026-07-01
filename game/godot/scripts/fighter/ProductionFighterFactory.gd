extends RefCounted
class_name ProductionFighterFactory

const REQUIRED_PARTS := [
	"hips", "spine", "chest", "neck", "head", "hair_or_helmet",
	"left_upper_arm", "left_forearm", "left_hand",
	"right_upper_arm", "right_forearm", "right_hand",
	"left_upper_leg", "left_lower_leg", "left_foot",
	"right_upper_leg", "right_lower_leg", "right_foot",
	"back_accessory", "element_accessory", "aura_socket",
]

static func build_rig(
	root: Node3D,
	fighter_id: String,
	limbs: Dictionary,
	sockets: Dictionary,
	owner: Node,
) -> void:
	var style := FighterAppearance.get_style(fighter_id)
	var profile := FighterSilhouetteProfile.get(fighter_id)
	var scale := _size_scale(profile.get("shape", "athletic"))
	var hand_s: float = profile.get("hand_scale", 1.0)
	var foot_s: float = profile.get("foot_scale", 1.0)
	var head_s: float = profile.get("head_scale", 1.0)

	limbs["hips"] = _part(root, "hips", Vector3(0, 0.52, 0), Vector3(0.36, 0.20, 0.24) * scale, style["secondary"])
	limbs["spine"] = _part(root, "spine", Vector3(0, 0.22, 0), Vector3(0.30, 0.22, 0.20) * scale, style["primary"], limbs["hips"])
	limbs["chest"] = _part(root, "chest", Vector3(0, 0.24, 0.02), Vector3(0.44, 0.30, 0.28) * scale, style["primary"], limbs["spine"])
	limbs["neck"] = _part(root, "neck", Vector3(0, 0.20, 0), Vector3(0.14, 0.10, 0.14) * scale, style["accent"], limbs["chest"])
	limbs["head"] = _part(root, "head", Vector3(0, 0.20, 0), Vector3(0.32, 0.32, 0.30) * head_s * scale, style["accent"], limbs["neck"])
	limbs["hair_or_helmet"] = _hair(profile.get("hair", "angular_crest"), limbs["head"], style, scale)

	limbs["left_upper_arm"] = _part(root, "left_upper_arm", Vector3(-0.34, 0.02, 0), Vector3(0.15, 0.26, 0.15) * scale, style["primary"], limbs["chest"])
	limbs["left_forearm"] = _part(root, "left_forearm", Vector3(0, -0.24, 0), Vector3(0.13, 0.24, 0.13) * scale, style["secondary"], limbs["left_upper_arm"])
	limbs["left_hand"] = _part(root, "left_hand", Vector3(0, -0.22, 0.04), Vector3(0.20, 0.16, 0.18) * hand_s * scale, style["accent"], limbs["left_forearm"], true)

	limbs["right_upper_arm"] = _part(root, "right_upper_arm", Vector3(0.34, 0.02, 0), Vector3(0.15, 0.26, 0.15) * scale, style["primary"], limbs["chest"])
	limbs["right_forearm"] = _part(root, "right_forearm", Vector3(0, -0.24, 0), Vector3(0.13, 0.24, 0.13) * scale, style["secondary"], limbs["right_upper_arm"])
	limbs["right_hand"] = _part(root, "right_hand", Vector3(0, -0.22, 0.04), Vector3(0.24, 0.18, 0.20) * hand_s * scale, style["accent"], limbs["right_forearm"], true)

	limbs["left_upper_leg"] = _part(root, "left_upper_leg", Vector3(-0.14, -0.16, 0), Vector3(0.17, 0.30, 0.17) * scale, style["secondary"], limbs["hips"])
	limbs["left_lower_leg"] = _part(root, "left_lower_leg", Vector3(0, -0.26, 0), Vector3(0.15, 0.28, 0.15) * scale, style["primary"], limbs["left_upper_leg"])
	limbs["left_foot"] = _part(root, "left_foot", Vector3(0.06, -0.20, 0.06), Vector3(0.26, 0.14, 0.34) * foot_s * scale, style["outline"], limbs["left_lower_leg"])

	limbs["right_upper_leg"] = _part(root, "right_upper_leg", Vector3(0.14, -0.16, 0), Vector3(0.17, 0.30, 0.17) * scale, style["secondary"], limbs["hips"])
	limbs["right_lower_leg"] = _part(root, "right_lower_leg", Vector3(0, -0.26, 0), Vector3(0.15, 0.28, 0.15) * scale, style["primary"], limbs["right_upper_leg"])
	limbs["right_foot"] = _part(root, "right_foot", Vector3(0.06, -0.20, 0.06), Vector3(0.26, 0.14, 0.34) * foot_s * scale, style["outline"], limbs["right_lower_leg"])

	limbs["back_accessory"] = _back_piece(profile, limbs["chest"], style, scale)
	limbs["element_accessory"] = _element_accent(profile.get("accent", "flame_gauntlets"), limbs, style, scale, hand_s)

	limbs["aura_socket"] = _socket("aura_socket", Vector3(0, 0.10, 0.06), limbs["chest"])
	sockets["aura_socket"] = limbs["aura_socket"]
	sockets["left_hand_socket"] = _socket("left_hand_socket", Vector3(0, -0.26, 0.10), limbs["left_hand"])
	sockets["right_hand_socket"] = _socket("right_hand_socket", Vector3(0, -0.28, 0.12), limbs["right_hand"])
	sockets["left_foot_socket"] = _socket("left_foot_socket", Vector3(0.10, -0.22, 0.10), limbs["left_foot"])
	sockets["right_foot_socket"] = _socket("right_foot_socket", Vector3(0.10, -0.22, 0.10), limbs["right_foot"])
	sockets["weapon_socket"] = _socket("weapon_socket", Vector3(0.14, -0.30, 0.14), limbs["right_hand"])
	sockets["hit_center_socket"] = _socket("hit_center_socket", Vector3(0, 0.05, 0.08), limbs["chest"])
	sockets["right_fist"] = sockets["right_hand_socket"]
	sockets["left_fist"] = sockets["left_hand_socket"]
	sockets["right_foot"] = sockets["right_foot_socket"]
	sockets["left_foot"] = sockets["left_foot_socket"]
	sockets["weapon_tip"] = sockets["weapon_socket"]
	sockets["center_mass"] = sockets["hit_center_socket"]
	sockets["ground_contact"] = _socket("ground_contact", Vector3(0.10, -0.24, 0.12), limbs["right_foot"])
	sockets["aura_core"] = sockets["aura_socket"]

	ElementalAuraSystem.attach(owner, fighter_id, sockets["aura_socket"])

static func _size_scale(shape: String) -> float:
	match shape:
		"compact": return 0.90
		"broad": return 1.16
		_: return 1.0

static func _part(
	parent: Node3D,
	part_name: String,
	local_pos: Vector3,
	box_size: Vector3,
	color: Color,
	attach_parent: Node3D = null,
	glow_hand: bool = false,
) -> Node3D:
	var holder := Node3D.new()
	holder.name = part_name
	holder.position = local_pos
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_node.mesh = mesh
	mesh_node.material_override = FighterMaterialLibrary.glow(color) if glow_hand else FighterMaterialLibrary.toon(color)
	holder.add_child(mesh_node)
	if attach_parent != null:
		attach_parent.add_child(holder)
	else:
		parent.add_child(holder)
	return holder

static func _socket(socket_name: String, local_pos: Vector3, attach_parent: Node3D) -> Node3D:
	var socket := Node3D.new()
	socket.name = socket_name
	socket.position = local_pos
	attach_parent.add_child(socket)
	return socket

static func _hair(kind: String, head: Node3D, style: Dictionary, scale: float) -> Node3D:
	var hair := Node3D.new()
	hair.name = "hair_or_helmet"
	match kind:
		"angular_crest":
			_part(hair, "crest", Vector3(0, 0.18, -0.02), Vector3(0.22, 0.14, 0.10) * scale, style["glow"], null, true)
		"bolt_tufts":
			_part(hair, "bolt_l", Vector3(-0.10, 0.16, 0), Vector3(0.08, 0.16, 0.06) * scale, style["accent"], null, true)
			_part(hair, "bolt_r", Vector3(0.10, 0.14, 0), Vector3(0.08, 0.14, 0.06) * scale, style["accent"], null, true)
		"hood":
			_part(hair, "hood", Vector3(0, 0.12, -0.06), Vector3(0.38, 0.18, 0.22) * scale, style["secondary"])
		"helm":
			_part(hair, "helm", Vector3(0, 0.10, 0), Vector3(0.34, 0.16, 0.30) * scale, style["outline"])
		_:
			_part(hair, "hair", Vector3(0, 0.14, -0.04), Vector3(0.28, 0.10, 0.12) * scale, style["accent"])
	head.add_child(hair)
	return hair

static func _back_piece(profile: Dictionary, chest: Node3D, style: Dictionary, scale: float) -> Node3D:
	var back := Node3D.new()
	back.name = "back_accessory"
	_part(back, "cape_stub", Vector3(0, -0.04, -0.14), Vector3(0.30, 0.36, 0.06) * scale, style["secondary"])
	chest.add_child(back)
	return back

static func _element_accent(accent_type: String, limbs: Dictionary, style: Dictionary, scale: float, hand_s: float) -> Node3D:
	var accent := Node3D.new()
	accent.name = "element_accessory"
	match accent_type:
		"flame_gauntlets":
			_part(accent, "gauntlet_l", Vector3(-0.36, -0.52, 0.10), Vector3(0.16, 0.16, 0.16) * hand_s * scale, style["glow"], null, true)
			_part(accent, "gauntlet_r", Vector3(0.36, -0.52, 0.10), Vector3(0.20, 0.18, 0.18) * hand_s * scale, style["glow"], null, true)
		"volt_scarf":
			_part(accent, "scarf", Vector3(0, 0.20, -0.10), Vector3(0.40, 0.10, 0.06) * scale, style["accent"], null, true)
			_part(accent, "afterimage_anchor", Vector3(0.22, 0.0, -0.12), Vector3(0.08, 0.08, 0.04) * scale, style["glow"], null, true)
		"impact_shoulders":
			_part(accent, "shoulder_l", Vector3(-0.28, 0.10, 0), Vector3(0.18, 0.14, 0.18) * scale, style["accent"])
			_part(accent, "shoulder_r", Vector3(0.28, 0.10, 0), Vector3(0.18, 0.14, 0.18) * scale, style["accent"])
		"gale_sash":
			_part(accent, "sash", Vector3(0, -0.02, 0.12), Vector3(0.32, 0.08, 0.04) * scale, style["accent"])
			_part(accent, "wing_l", Vector3(-0.22, 0.04, 0.08), Vector3(0.10, 0.22, 0.04) * scale, style["glow"])
		"frost_mantle":
			_part(accent, "mantle", Vector3(0, 0.14, -0.12), Vector3(0.52, 0.22, 0.08) * scale, style["glow"])
			_part(accent, "shard_l", Vector3(-0.20, 0.08, 0.04), Vector3(0.08, 0.12, 0.04) * scale, style["accent"])
		"gravity_rings":
			for i in range(3):
				_part(accent, "ring_%d" % i, Vector3(0.24 * cos(i * 2.1), 0.08 * i, 0.08), Vector3(0.10, 0.10, 0.10) * scale, style["accent"])
		"void_hood":
			_part(accent, "void_cape", Vector3(0, 0.06, -0.10), Vector3(0.36, 0.28, 0.08) * scale, style["secondary"])
	limbs["chest"].add_child(accent)
	return accent
