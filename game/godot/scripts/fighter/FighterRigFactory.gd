extends RefCounted
class_name FighterRigFactory

const REQUIRED_PARTS := [
	"head", "torso", "hips",
	"left_upper_arm", "left_forearm", "left_hand",
	"right_upper_arm", "right_forearm", "right_hand",
	"left_thigh", "left_shin", "left_foot",
	"right_thigh", "right_shin", "right_foot",
	"element_accent", "aura_socket",
]

const FIGHTER_PROFILES := {
	"ember-vale": {"shape": "athletic", "accent": "flame_gauntlets"},
	"rook-ironside": {"shape": "broad", "accent": "impact_shoulders"},
	"juno-spark": {"shape": "compact", "accent": "volt_scarf"},
	"kaia-windrow": {"shape": "athletic", "accent": "gale_sash"},
	"nix-calder": {"shape": "broad", "accent": "frost_mantle"},
	"orion-vell": {"shape": "athletic", "accent": "gravity_rings"},
	"vesper-nyx": {"shape": "compact", "accent": "void_hood"},
}

static func build_rig(
	root: Node3D,
	fighter_id: String,
	limbs: Dictionary,
	sockets: Dictionary,
	owner: Node,
) -> void:
	var style := FighterAppearance.get_style(fighter_id)
	var profile: Dictionary = FIGHTER_PROFILES.get(fighter_id, {"shape": "athletic", "accent": "flame_gauntlets"})
	var scale := _size_scale(profile.get("shape", "athletic"))

	limbs["hips"] = _add_part(root, "hips", Vector3(0, 0.55, 0), Vector3(0.34, 0.18, 0.22) * scale, style["secondary"])
	limbs["torso"] = _add_part(root, "torso", Vector3(0, 0.82, 0), Vector3(0.42, 0.42, 0.26) * scale, style["primary"], limbs["hips"])
	limbs["head"] = _add_part(root, "head", Vector3(0, 0.34, 0), Vector3(0.30, 0.30, 0.28) * scale, style["accent"], limbs["torso"])

	limbs["left_upper_arm"] = _add_part(root, "left_upper_arm", Vector3(-0.30, -0.05, 0), Vector3(0.14, 0.24, 0.14) * scale, style["primary"], limbs["torso"])
	limbs["left_forearm"] = _add_part(root, "left_forearm", Vector3(0, -0.22, 0), Vector3(0.12, 0.22, 0.12) * scale, style["secondary"], limbs["left_upper_arm"])
	limbs["left_hand"] = _add_part(root, "left_hand", Vector3(0, -0.20, 0), Vector3(0.18, 0.14, 0.16) * scale, style["accent"], limbs["left_forearm"])

	limbs["right_upper_arm"] = _add_part(root, "right_upper_arm", Vector3(0.30, -0.05, 0), Vector3(0.14, 0.24, 0.14) * scale, style["primary"], limbs["torso"])
	limbs["right_forearm"] = _add_part(root, "right_forearm", Vector3(0, -0.22, 0), Vector3(0.12, 0.22, 0.12) * scale, style["secondary"], limbs["right_upper_arm"])
	limbs["right_hand"] = _add_part(root, "right_hand", Vector3(0, -0.20, 0), Vector3(0.20, 0.16, 0.18) * scale, style["accent"], limbs["right_forearm"])

	limbs["left_thigh"] = _add_part(root, "left_thigh", Vector3(-0.14, -0.18, 0), Vector3(0.16, 0.28, 0.16) * scale, style["secondary"], limbs["hips"])
	limbs["left_shin"] = _add_part(root, "left_shin", Vector3(0, -0.24, 0), Vector3(0.14, 0.26, 0.14) * scale, style["primary"], limbs["left_thigh"])
	limbs["left_foot"] = _add_part(root, "left_foot", Vector3(0.04, -0.18, 0.04), Vector3(0.22, 0.12, 0.30) * scale, style["outline"], limbs["left_shin"])

	limbs["right_thigh"] = _add_part(root, "right_thigh", Vector3(0.14, -0.18, 0), Vector3(0.16, 0.28, 0.16) * scale, style["secondary"], limbs["hips"])
	limbs["right_shin"] = _add_part(root, "right_shin", Vector3(0, -0.24, 0), Vector3(0.14, 0.26, 0.14) * scale, style["primary"], limbs["right_thigh"])
	limbs["right_foot"] = _add_part(root, "right_foot", Vector3(0.04, -0.18, 0.04), Vector3(0.22, 0.12, 0.30) * scale, style["outline"], limbs["right_shin"])

	limbs["element_accent"] = _build_element_accent(profile.get("accent", "flame_gauntlets"), limbs, style, scale)
	limbs["aura_socket"] = _add_socket(root, "aura_socket", Vector3(0, 0.82, 0), limbs["torso"])

	sockets["right_fist"] = _add_socket(root, "right_fist", Vector3(0, -0.24, 0.08), limbs["right_hand"])
	sockets["left_fist"] = _add_socket(root, "left_fist", Vector3(0, -0.24, 0.08), limbs["left_hand"])
	sockets["right_foot"] = _add_socket(root, "right_foot", Vector3(0.08, -0.20, 0.08), limbs["right_foot"])
	sockets["left_foot"] = _add_socket(root, "left_foot", Vector3(0.08, -0.20, 0.08), limbs["left_foot"])
	sockets["chest_aura"] = limbs["aura_socket"]
	sockets["weapon_tip"] = _add_socket(root, "weapon_tip", Vector3(0.12, -0.28, 0.12), limbs["right_hand"])

	ElementalVfxFactory.attach_aura(owner, fighter_id, sockets["chest_aura"])

static func _size_scale(shape: String) -> float:
	match shape:
		"compact":
			return 0.88
		"broad":
			return 1.14
		_:
			return 1.0

static func _add_part(
	parent: Node3D,
	part_name: String,
	local_pos: Vector3,
	box_size: Vector3,
	color: Color,
	attach_parent: Node3D = null,
) -> Node3D:
	var holder := Node3D.new()
	holder.name = part_name
	holder.position = local_pos
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.08
	mesh_node.material_override = mat
	holder.add_child(mesh_node)
	if attach_parent != null:
		attach_parent.add_child(holder)
	else:
		parent.add_child(holder)
	return holder

static func _add_socket(parent: Node3D, socket_name: String, local_pos: Vector3, attach_parent: Node3D) -> Node3D:
	var socket := Node3D.new()
	socket.name = socket_name
	socket.position = local_pos
	attach_parent.add_child(socket)
	return socket

static func _build_element_accent(accent_type: String, limbs: Dictionary, style: Dictionary, scale: float) -> Node3D:
	var parent: Node3D = limbs.get("torso")
	var accent := Node3D.new()
	accent.name = "element_accent"
	match accent_type:
		"flame_gauntlets":
			_add_part(accent, "flame_l", Vector3(-0.08, -0.18, 0.08), Vector3(0.10, 0.10, 0.10) * scale, style["glow"], null)
			_add_part(accent, "flame_r", Vector3(0.08, -0.18, 0.08), Vector3(0.10, 0.10, 0.10) * scale, style["glow"], null)
		"impact_shoulders":
			_add_part(accent, "shoulder_l", Vector3(-0.24, 0.08, 0), Vector3(0.16, 0.12, 0.16) * scale, style["accent"], null)
			_add_part(accent, "shoulder_r", Vector3(0.24, 0.08, 0), Vector3(0.16, 0.12, 0.16) * scale, style["accent"], null)
		"volt_scarf":
			_add_part(accent, "scarf", Vector3(0, 0.18, -0.08), Vector3(0.34, 0.08, 0.06) * scale, style["accent"], null)
		"gale_sash":
			_add_part(accent, "sash", Vector3(0, -0.02, 0.10), Vector3(0.28, 0.06, 0.04) * scale, style["accent"], null)
		"frost_mantle":
			_add_part(accent, "mantle", Vector3(0, 0.12, -0.10), Vector3(0.48, 0.20, 0.08) * scale, style["glow"], null)
		"gravity_rings":
			for i in range(3):
				_add_part(accent, "ring_%d" % i, Vector3(0.22 * cos(i * 2.1), 0.1 * i, 0.1), Vector3(0.08, 0.08, 0.08) * scale, style["accent"], null)
		"void_hood":
			_add_part(accent, "hood", Vector3(0, 0.18, -0.06), Vector3(0.34, 0.16, 0.20) * scale, style["secondary"], null)
	parent.add_child(accent)
	return accent
