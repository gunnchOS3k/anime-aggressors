extends Node3D
## V1.6 art-direction candidate. Not final art.
## Elongated anime-humanoid read for Kaia, Yin, and Yang.
## Male and female share gameplay and differ in proportion, hair, and costume.

const LABEL := "ART_DIRECTION_CANDIDATE_V1_6"
const SLICE := ["kaia-windrow", "yin", "yang"]

var fighter_id: String = ""
var body_variant: String = "male"
var presentation_id: String = ""

var _torso: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _hair: Node3D
var _accent: Node3D
var _ring: Node3D


static func is_slice(id: String) -> bool:
	return id in SLICE


static func presentation_path(id: String, variant: String) -> String:
	var v := "female" if variant == "female" else "male"
	return "res://content/v16_art_direction/%s/%s/PRESENTATION.json" % [id, v]


static func create(id: String, variant: String) -> Node3D:
	var script: GDScript = load("res://scripts/visual/v16_art_direction_body.gd") as GDScript
	var node: Node3D = script.new() as Node3D
	node.build(id, variant)
	return node


func build(id: String, variant: String) -> void:
	fighter_id = id
	body_variant = "female" if variant == "female" else "male"
	presentation_id = "%s::%s::%s" % [fighter_id, body_variant, LABEL]
	name = "V16_%s_%s" % [fighter_id, body_variant]
	var female := body_variant == "female"
	var colors := _palette(fighter_id)
	var shoulder := 0.46 if female else 0.58
	var hip := 0.40 if female else 0.34
	var height := 1.92 if female else 1.84
	var hair_len := 0.72 if female else 0.28

	_torso = _pivot("Torso", Vector3(0, height * 0.52, 0))
	add_child(_torso)
	_box(_torso, "Chest", Vector3(shoulder, 0.42, 0.22), Vector3(0, 0.16, 0), colors.cloth)
	_box(_torso, "Waist", Vector3(hip, 0.28, 0.18), Vector3(0, -0.16, 0), colors.trim)
	_box(_torso, "Collar", Vector3(shoulder * 0.72, 0.08, 0.16), Vector3(0, 0.36, 0.02), colors.accent)

	_head = _pivot("Head", Vector3(0, 0.62, 0))
	_torso.add_child(_head)
	_box(_head, "Skull", Vector3(0.28, 0.32, 0.26), Vector3.ZERO, colors.skin)
	_box(_head, "Brow", Vector3(0.22, 0.04, 0.04), Vector3(0, 0.06, 0.12), colors.hair)
	_sphere(_head, "EyeL", 0.045, Vector3(-0.07, 0.02, 0.12), colors.eye)
	_sphere(_head, "EyeR", 0.045, Vector3(0.07, 0.02, 0.12), colors.eye)
	_box(_head, "Mouth", Vector3(0.08, 0.02, 0.02), Vector3(0, -0.08, 0.12), colors.trim)

	_hair = _pivot("Hair", Vector3(0, 0.12, -0.08))
	_head.add_child(_hair)
	_box(_hair, "Crest", Vector3(0.30, 0.12, 0.30), Vector3(0, 0.08, 0), colors.hair)
	_box(_hair, "Tail", Vector3(0.16, hair_len, 0.12), Vector3(0, -hair_len * 0.45, -0.04), colors.hair)
	if female:
		_box(_hair, "SideLock", Vector3(0.08, 0.46, 0.06), Vector3(0.16, -0.18, 0.04), colors.accent)

	_arm_l = _limb("ArmL", Vector3(-shoulder * 0.62, 0.22, 0), colors, true)
	_arm_r = _limb("ArmR", Vector3(shoulder * 0.62, 0.22, 0), colors, false)
	_torso.add_child(_arm_l)
	_torso.add_child(_arm_r)
	_leg_l = _limb("LegL", Vector3(-hip * 0.35, -0.34, 0), colors, true)
	_leg_r = _limb("LegR", Vector3(hip * 0.35, -0.34, 0), colors, false)
	_torso.add_child(_leg_l)
	_torso.add_child(_leg_r)

	_accent = _pivot("Identity", Vector3(0, 0.1, -0.12))
	_torso.add_child(_accent)
	_ring = _pivot("Ring", Vector3(0, -0.05, 0))
	_torso.add_child(_ring)
	_build_identity(colors)
	apply_story_form("BASE")


func apply_story_form(form_id: String) -> void:
	var form := form_id.to_lower()
	var tint := Color(1, 1, 1)
	if form.contains("black") or form.contains("puppet") and fighter_id == "yin":
		tint = Color(0.25, 0.25, 0.28)
	elif form.contains("white") or form.contains("puppet"):
		tint = Color(0.95, 0.92, 0.8)
	elif form.contains("gray") or form.contains("prismatic") or form.contains("essence_6"):
		tint = Color(0.75, 0.9, 1.0)
	elif form.contains("essence_2") or form.contains("2"):
		tint = Color(0.7, 1.0, 0.85)
	elif form.contains("essence"):
		tint = Color(0.55, 0.95, 0.8)
	if _ring:
		for child in _ring.get_children():
			if child is MeshInstance3D:
				var mat := child.material_override as StandardMaterial3D
				if mat:
					mat.albedo_color = tint


func animate_pose(clip: String, t: float) -> void:
	var name := clip.to_lower()
	var phase := sin(t * TAU)
	_reset_pose()
	if name.contains("victory") or name.contains("win"):
		_arm_l.rotation_degrees.z = 70.0
		_arm_r.rotation_degrees.z = -70.0
		_torso.rotation_degrees.x = -8.0
	elif name.contains("super"):
		_torso.rotation_degrees.y = phase * 25.0
		_arm_r.rotation_degrees.x = -80.0
		_arm_l.rotation_degrees.x = -40.0
		if _ring:
			_ring.scale = Vector3(1.8, 1.0, 1.8)
	elif name.contains("special"):
		_apply_special(phase)
	elif name.contains("heavy"):
		_torso.rotation_degrees.y = -28.0
		_arm_r.rotation_degrees.x = -110.0
		_arm_r.rotation_degrees.z = -20.0
	elif name.contains("light") or name.contains("jab") or name == "attack":
		_arm_r.rotation_degrees.x = -75.0
		_torso.rotation_degrees.y = -12.0
	elif name.contains("aerial") or name.contains("nair") or name.contains("jump"):
		_torso.position.y += 0.18
		_leg_l.rotation_degrees.x = -30.0
		_leg_r.rotation_degrees.x = 20.0
		_arm_r.rotation_degrees.z = -40.0
	elif name.contains("dash") or name.contains("run"):
		_torso.rotation_degrees.x = 18.0
		_leg_l.rotation_degrees.x = 35.0 * phase
		_leg_r.rotation_degrees.x = -35.0 * phase
	elif name.contains("hurt"):
		_torso.rotation_degrees.x = 22.0
		_head.rotation_degrees.x = 15.0
	elif name.contains("tumble") or name.contains("launch"):
		_torso.rotation_degrees.z = 70.0 * phase
		_torso.rotation_degrees.x = -40.0
	else:
		_torso.rotation_degrees.y = phase * 4.0
		_hair.rotation_degrees.x = phase * 6.0
		if fighter_id == "kaia-windrow" and _accent:
			_accent.rotation_degrees.y = t * 40.0


func _apply_special(phase: float) -> void:
	if fighter_id == "yin":
		_torso.scale = Vector3(0.82, 0.9, 0.82)
		_arm_l.rotation_degrees.x = -100.0
		_arm_r.rotation_degrees.x = -100.0
		if _ring:
			_ring.scale = Vector3(0.45, 1.0, 0.45)
	elif fighter_id == "yang":
		_arm_l.rotation_degrees.z = 80.0
		_arm_r.rotation_degrees.z = -80.0
		if _ring:
			_ring.scale = Vector3(1.6 + phase * 0.2, 1.0, 1.6)
	else:
		_torso.rotation_degrees.y = phase * 35.0
		_arm_r.rotation_degrees.x = -60.0
		_arm_l.rotation_degrees.z = 50.0
		if _accent:
			_accent.rotation_degrees.y = phase * 80.0


func _reset_pose() -> void:
	_torso.rotation = Vector3.ZERO
	_torso.scale = Vector3.ONE
	_head.rotation = Vector3.ZERO
	_arm_l.rotation = Vector3.ZERO
	_arm_r.rotation = Vector3.ZERO
	_leg_l.rotation = Vector3.ZERO
	_leg_r.rotation = Vector3.ZERO
	if _ring:
		_ring.scale = Vector3.ONE
		_ring.rotation = Vector3.ZERO


func _build_identity(colors: Dictionary) -> void:
	if fighter_id == "kaia-windrow":
		_box(_accent, "RibbonL", Vector3(0.08, 0.9, 0.04), Vector3(-0.28, -0.2, 0), colors.accent)
		_box(_accent, "RibbonR", Vector3(0.08, 0.7, 0.04), Vector3(0.28, -0.05, 0), colors.accent)
	elif fighter_id == "yin":
		_box(_accent, "VoidCore", Vector3(0.16, 0.16, 0.08), Vector3(0, 0.05, 0.12), Color(0.05, 0.05, 0.08))
		_box(_ring, "Collapse", Vector3(0.5, 0.04, 0.5), Vector3.ZERO, colors.accent)
	else:
		_box(_ring, "Radiance", Vector3(0.7, 0.05, 0.7), Vector3(0, 0.05, 0), colors.accent)
		_box(_accent, "Ray", Vector3(0.06, 0.55, 0.06), Vector3(0.34, 0.2, 0), colors.accent)


func _palette(id: String) -> Dictionary:
	if id == "yin":
		return {
			"cloth": Color(0.12, 0.12, 0.14),
			"trim": Color(0.28, 0.28, 0.32),
			"accent": Color(0.55, 0.5, 0.7),
			"skin": Color(0.55, 0.52, 0.58),
			"hair": Color(0.08, 0.08, 0.1),
			"eye": Color(0.75, 0.7, 0.95),
		}
	if id == "yang":
		return {
			"cloth": Color(0.95, 0.93, 0.86),
			"trim": Color(0.92, 0.78, 0.35),
			"accent": Color(1.0, 0.86, 0.45),
			"skin": Color(0.96, 0.86, 0.74),
			"hair": Color(0.98, 0.95, 0.8),
			"eye": Color(0.35, 0.28, 0.12),
		}
	return {
		"cloth": Color(0.12, 0.45, 0.42),
		"trim": Color(0.85, 0.95, 0.9),
		"accent": Color(0.45, 0.95, 0.75),
		"skin": Color(0.93, 0.78, 0.66),
		"hair": Color(0.1, 0.35, 0.32),
		"eye": Color(0.15, 0.45, 0.4),
	}


func _pivot(node_name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	n.position = pos
	return n


func _limb(node_name: String, pos: Vector3, colors: Dictionary, _left: bool) -> Node3D:
	var pivot := _pivot(node_name, pos)
	_box(pivot, "Upper", Vector3(0.1, 0.34, 0.1), Vector3(0, -0.16, 0), colors.cloth)
	_box(pivot, "Hand", Vector3(0.1, 0.08, 0.12), Vector3(0, -0.36, 0.02), colors.skin)
	return pivot


func _box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.name = node_name
	mesh_node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.45
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh_node.material_override = mat
	parent.add_child(mesh_node)
	return mesh_node


func _sphere(parent: Node3D, node_name: String, radius: float, pos: Vector3, color: Color) -> void:
	var mesh_node := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_node.mesh = sphere
	mesh_node.name = node_name
	mesh_node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_node.material_override = mat
	parent.add_child(mesh_node)
