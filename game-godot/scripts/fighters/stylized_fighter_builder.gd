extends Node3D
## Procedural stylized low-poly fighter. No Blender / marketplace meshes.
## Prefer preload over class_name to avoid global-scope registration order issues.

const SKIN := Color(0.96, 0.82, 0.72)
const SKIN_COOL := Color(0.88, 0.78, 0.74)
const EYE_WHITE := Color(0.98, 0.98, 1.0)
const IRIS_DARK := Color(0.08, 0.08, 0.12)
const MOUTH_DARK := Color(0.35, 0.12, 0.14)

## Per-fighter silhouette scales + clothing language.
const PROFILES := {
	"ember-vale": {
		"height": 1.0,
		"width": 0.92,
		"limb": 1.0,
		"head": 1.02,
		"lean_x": -10.0,
		"hair": "flame_crest",
		"clothes": ["chest_plate", "gauntlets", "sash"],
		"secondary": Color(0.24, 0.08, 0.06),
		"accent": Color(1.0, 0.65, 0.20),
		"timing": 1.18,
	},
	"rook-ironside": {
		"height": 1.06,
		"width": 1.28,
		"limb": 1.1,
		"head": 0.96,
		"lean_x": 4.0,
		"hair": "helm_plate",
		"clothes": ["pauldrons", "chest_plate", "skirt"],
		"secondary": Color(0.16, 0.14, 0.14),
		"accent": Color(0.72, 0.56, 0.38),
		"timing": 0.72,
	},
	"juno-spark": {
		"height": 0.88,
		"width": 0.86,
		"limb": 0.92,
		"head": 1.12,
		"lean_x": -6.0,
		"hair": "bolt_tufts",
		"clothes": ["scarf", "sash", "gauntlets"],
		"secondary": Color(0.17, 0.18, 0.30),
		"accent": Color(0.80, 0.95, 1.0),
		"timing": 1.35,
	},
	"kaia-windrow": {
		"height": 1.12,
		"width": 0.9,
		"limb": 1.05,
		"head": 1.0,
		"lean_x": -3.0,
		"hair": "wind_sweep",
		"clothes": ["skirt", "sash", "scarf"],
		"secondary": Color(0.10, 0.24, 0.14),
		"accent": Color(0.72, 1.0, 0.84),
		"timing": 0.95,
	},
	"nix-calder": {
		"height": 1.04,
		"width": 0.94,
		"limb": 1.0,
		"head": 0.98,
		"lean_x": 0.0,
		"hair": "ice_spikes",
		"clothes": ["hood", "mantle", "chest_plate"],
		"secondary": Color(0.08, 0.15, 0.30),
		"accent": Color(0.70, 0.90, 1.0),
		"timing": 0.68,
	},
	"orion-vell": {
		"height": 1.18,
		"width": 1.02,
		"limb": 1.08,
		"head": 0.94,
		"lean_x": 2.0,
		"hair": "orbit_crown",
		"clothes": ["mantle", "chest_plate", "pauldrons"],
		"secondary": Color(0.15, 0.09, 0.28),
		"accent": Color(0.86, 0.82, 1.0),
		"timing": 0.8,
	},
	"vesper-nyx": {
		"height": 1.02,
		"width": 0.96,
		"limb": 1.0,
		"head": 1.04,
		"lean_x": -8.0,
		"asym_z": 0.06,
		"hair": "shadow_hood",
		"clothes": ["hood", "mantle", "scarf"],
		"secondary": Color(0.13, 0.05, 0.20),
		"accent": Color(0.92, 0.48, 0.98),
		"timing": 1.08,
	},
}


var fighter_id: String = ""
var _parts: Dictionary = {}
var _rest: Dictionary = {}
var _mats: Dictionary = {}
var _timing: float = 1.0
var _eyes: Array = []
var _brows: Array = []
var _mouth: MeshInstance3D
var _expression: String = "neutral"
var _clip: String = "idle"


static func create(fighter_id: String, fighter_data: Dictionary = {}) -> Node3D:
	var script: GDScript = load("res://scripts/fighters/stylized_fighter_builder.gd") as GDScript
	var root: Node3D = script.new() as Node3D
	root.name = "StylizedFighter"
	root.build(fighter_id, fighter_data)
	return root


func build(p_fighter_id: String, fighter_data: Dictionary = {}) -> void:
	fighter_id = p_fighter_id
	var profile: Dictionary = PROFILES.get(fighter_id, {
		"height": 1.0,
		"width": 1.0,
		"limb": 1.0,
		"head": 1.0,
		"lean_x": 0.0,
		"hair": "short",
		"clothes": ["chest_plate"],
		"secondary": Color(0.2, 0.2, 0.25),
		"accent": Color(0.9, 0.8, 0.3),
		"timing": 1.0,
	}).duplicate(true)
	_timing = float(profile.get("timing", 1.0))
	_mats = _make_materials(fighter_data, profile)
	_build_body(profile)
	_build_face()
	_build_hair(str(profile.get("hair", "short")))
	_build_clothes(profile.get("clothes", []) as Array)
	_cache_rest()
	rotation_degrees.x = float(profile.get("lean_x", 0.0))
	if profile.has("asym_z"):
		position.z = float(profile.get("asym_z", 0.0))


func set_expression(state: String) -> void:
	_expression = state
	if _mouth == null:
		return
	var brow_y := 0.03
	var brow_rot := 0.0
	var eye_scale := Vector3.ONE
	var mouth_scale := Vector3(1.0, 0.35, 1.0)
	var mouth_y := -0.03
	match state:
		"confident", "victory":
			brow_y = 0.045
			brow_rot = -8.0
			mouth_scale = Vector3(1.15, 0.55, 1.0)
			mouth_y = -0.035
		"focused", "charging", "strained":
			brow_y = 0.01
			brow_rot = 18.0
			eye_scale = Vector3(1.0, 0.72, 1.0)
			mouth_scale = Vector3(0.7, 0.22, 1.0)
		"surprised":
			brow_y = 0.06
			eye_scale = Vector3(1.15, 1.2, 1.0)
			mouth_scale = Vector3(0.55, 0.85, 1.0)
			mouth_y = -0.04
		"hurt":
			brow_y = 0.0
			brow_rot = 22.0
			eye_scale = Vector3(1.0, 0.55, 1.0)
			mouth_scale = Vector3(0.9, 0.7, 1.0)
			mouth_y = -0.045
		"defeat":
			brow_y = -0.01
			brow_rot = 12.0
			eye_scale = Vector3(1.0, 0.4, 1.0)
			mouth_scale = Vector3(0.8, 0.25, 1.0)
		_:
			pass
	for i in _brows.size():
		var brow: Node3D = _brows[i]
		brow.position.y = brow_y
		brow.rotation_degrees.z = brow_rot * (1.0 if i == 0 else -1.0)
	for eye in _eyes:
		(eye as Node3D).scale = eye_scale
	_mouth.scale = mouth_scale
	_mouth.position.y = mouth_y


func animate_pose(clip: String, t: float) -> void:
	_clip = clip
	var speed := _timing
	var phase := t * TAU * speed
	_reset_to_rest()
	match clip:
		"idle":
			_pose_idle(phase)
		"walk":
			_pose_locomotion(phase * 1.4, 0.35, 18.0)
		"run", "dash":
			_pose_locomotion(phase * 2.1, 0.55, 32.0)
		"jump":
			_pose_jump(clampf(t * speed, 0.0, 1.0))
		"fall":
			_pose_fall(phase)
		"land":
			_pose_land(clampf(t * speed * 2.0, 0.0, 1.0))
		"jab_1":
			_pose_jab(clampf(t * speed * 3.2, 0.0, 1.0), false)
		"jab_2":
			_pose_jab(clampf(t * speed * 3.2, 0.0, 1.0), true)
		"heavy_attack":
			_pose_heavy(clampf(t * speed * 2.0, 0.0, 1.0))
		"special":
			_pose_special(clampf(t * speed * 1.8, 0.0, 1.0))
		"shield":
			_pose_shield()
		"hurt_light":
			_pose_hurt(0.35)
		"hurt_heavy":
			_pose_hurt(0.85)
		"launched":
			_pose_launched(phase)
		"aura_charge":
			_pose_aura_charge(phase)
		"aura_burst":
			_pose_aura_burst(clampf(t * speed * 1.5, 0.0, 1.0))
		"throw_forward":
			_pose_throw(Vector3(0, -8, -35))
		"throw_back":
			_pose_throw(Vector3(0, 40, 20))
		"throw_up":
			_pose_throw(Vector3(-35, 0, -10))
		"throw_down":
			_pose_throw(Vector3(28, 0, -8))
		"ko":
			_pose_ko(clampf(t * 0.7, 0.0, 1.0))
		"victory":
			_pose_victory(phase)
		"defeat":
			_pose_defeat()
		_:
			_pose_idle(phase)


func get_height_scale() -> float:
	var profile: Dictionary = PROFILES.get(fighter_id, {})
	return float(profile.get("height", 1.0))


func _make_materials(fighter_data: Dictionary, profile: Dictionary) -> Dictionary:
	var primary := _parse_color(fighter_data.get("color", "#e8453c"), Color(0.91, 0.27, 0.24))
	var accent := _parse_color(
		fighter_data.get("auraColor", fighter_data.get("color", "#f0c040")),
		Color(0.94, 0.75, 0.25)
	)
	var secondary: Color = profile.get("secondary", primary.darkened(0.45))
	var accent_c: Color = profile.get("accent", accent)
	return {
		"primary": _mat(primary),
		"secondary": _mat(secondary),
		"accent": _mat(accent_c),
		"skin": _mat(SKIN if fighter_id != "nix-calder" else SKIN_COOL),
		"hair": _mat(accent_c.darkened(0.15)),
		"eye": _mat(EYE_WHITE),
		"iris": _mat(IRIS_DARK),
		"brow": _mat(secondary.darkened(0.2)),
		"mouth": _mat(MOUTH_DARK),
		"cloth": _mat(secondary.lightened(0.08)),
	}


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value as Color
	var text := str(value).strip_edges()
	if text.begins_with("#") and text.length() >= 7:
		return Color.html(text)
	return fallback


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	m.metallic = 0.05
	return m


func _build_body(profile: Dictionary) -> void:
	var h: float = float(profile.get("height", 1.0))
	var w: float = float(profile.get("width", 1.0))
	var limb: float = float(profile.get("limb", 1.0))
	var head_s: float = float(profile.get("head", 1.0))

	var hip := _joint("Hip", self, Vector3(0, 0.55 * h, 0))
	_capsule(hip, "HipMesh", 0.11 * w, 0.16 * h, _mats["secondary"], Vector3(0, 0, 0))

	var torso := _joint("Torso", hip, Vector3(0, 0.14 * h, 0))
	_capsule(torso, "TorsoMesh", 0.13 * w, 0.18 * h, _mats["primary"], Vector3(0, 0.02, 0))

	var chest := _joint("Chest", torso, Vector3(0, 0.16 * h, 0.01))
	_capsule(chest, "ChestMesh", 0.16 * w, 0.22 * h, _mats["primary"], Vector3(0, 0.04, 0))

	var neck := _joint("Neck", chest, Vector3(0, 0.16 * h, 0))
	_cylinder(neck, "NeckMesh", 0.045 * w, 0.08 * h, _mats["skin"], Vector3(0, 0.02, 0))

	var head := _joint("Head", neck, Vector3(0, 0.12 * h, 0))
	_sphere(head, "HeadMesh", 0.13 * head_s * w, _mats["skin"], Vector3(0, 0.06 * head_s, 0.01))

	_arm("L", chest, -1, h, w, limb)
	_arm("R", chest, 1, h, w, limb)
	_leg("L", hip, -1, h, w, limb)
	_leg("R", hip, 1, h, w, limb)


func _arm(side: String, chest: Node3D, dir: float, h: float, w: float, limb: float) -> void:
	var upper := _joint("%sUpperArm" % side, chest, Vector3(dir * 0.2 * w, 0.08 * h, 0))
	upper.rotation_degrees.z = dir * 12.0
	_capsule(upper, "Mesh", 0.055 * limb, 0.22 * limb * h, _mats["primary"], Vector3(0, -0.1 * limb * h, 0))
	var fore := _joint("%sForeArm" % side, upper, Vector3(0, -0.22 * limb * h, 0))
	_capsule(fore, "Mesh", 0.045 * limb, 0.2 * limb * h, _mats["skin"], Vector3(0, -0.09 * limb * h, 0))
	var hand := _joint("%sHand" % side, fore, Vector3(0, -0.2 * limb * h, 0.02))
	_sphere(hand, "Mesh", 0.055 * limb * w, _mats["accent"], Vector3.ZERO)


func _leg(side: String, hip: Node3D, dir: float, h: float, w: float, limb: float) -> void:
	var thigh := _joint("%sThigh" % side, hip, Vector3(dir * 0.09 * w, -0.05 * h, 0))
	_capsule(thigh, "Mesh", 0.07 * limb * w, 0.26 * limb * h, _mats["secondary"], Vector3(0, -0.12 * limb * h, 0))
	var shin := _joint("%sShin" % side, thigh, Vector3(0, -0.28 * limb * h, 0))
	_capsule(shin, "Mesh", 0.055 * limb * w, 0.24 * limb * h, _mats["primary"], Vector3(0, -0.1 * limb * h, 0))
	var foot := _joint("%sFoot" % side, shin, Vector3(0, -0.24 * limb * h, 0.04))
	_prism(foot, "Mesh", Vector3(0.1 * w, 0.05, 0.16 * limb), _mats["accent"], Vector3(0.02, -0.01, 0.04))


func _build_face() -> void:
	var head: Node3D = _parts.get("Head")
	if head == null:
		return
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, 0.06, 0.11)
	head.add_child(face)

	for side in [-1.0, 1.0]:
		var eye_white := MeshInstance3D.new()
		eye_white.name = "EyeWhite_%s" % ("L" if side < 0 else "R")
		var ew := SphereMesh.new()
		ew.radius = 0.028
		ew.height = 0.056
		eye_white.mesh = ew
		eye_white.material_override = _mats["eye"]
		eye_white.position = Vector3(side * 0.045, 0.02, 0.02)
		face.add_child(eye_white)
		_eyes.append(eye_white)

		var iris := MeshInstance3D.new()
		iris.name = "Iris_%s" % ("L" if side < 0 else "R")
		var im := SphereMesh.new()
		im.radius = 0.014
		im.height = 0.028
		iris.mesh = im
		iris.material_override = _mats["iris"]
		iris.position = Vector3(side * 0.045, 0.02, 0.038)
		face.add_child(iris)

		var brow := MeshInstance3D.new()
		brow.name = "Brow_%s" % ("L" if side < 0 else "R")
		var bm := CapsuleMesh.new()
		bm.radius = 0.008
		bm.height = 0.05
		brow.mesh = bm
		brow.material_override = _mats["brow"]
		brow.rotation_degrees = Vector3(0, 0, 90)
		brow.position = Vector3(side * 0.045, 0.045, 0.03)
		face.add_child(brow)
		_brows.append(brow)

	_mouth = MeshInstance3D.new()
	_mouth.name = "Mouth"
	var mm := CapsuleMesh.new()
	mm.radius = 0.01
	mm.height = 0.05
	_mouth.mesh = mm
	_mouth.material_override = _mats["mouth"]
	_mouth.rotation_degrees = Vector3(0, 0, 90)
	_mouth.position = Vector3(0, -0.03, 0.04)
	_mouth.scale = Vector3(1.0, 0.35, 1.0)
	face.add_child(_mouth)


func _build_hair(kind: String) -> void:
	var head: Node3D = _parts.get("Head")
	if head == null:
		return
	var hair := Node3D.new()
	hair.name = "Hair"
	head.add_child(hair)
	match kind:
		"flame_crest":
			_prism(hair, "Crest", Vector3(0.08, 0.18, 0.1), _mats["accent"], Vector3(0, 0.18, -0.02))
			_prism(hair, "Crest2", Vector3(0.06, 0.12, 0.08), _mats["hair"], Vector3(0.04, 0.14, -0.04))
		"helm_plate":
			_capsule(hair, "Helm", 0.14, 0.12, _mats["secondary"], Vector3(0, 0.1, 0))
			_prism(hair, "Visor", Vector3(0.18, 0.04, 0.08), _mats["accent"], Vector3(0, 0.08, 0.08))
		"bolt_tufts":
			_prism(hair, "BoltL", Vector3(0.05, 0.16, 0.05), _mats["accent"], Vector3(-0.08, 0.16, 0))
			_prism(hair, "BoltR", Vector3(0.05, 0.14, 0.05), _mats["accent"], Vector3(0.08, 0.14, -0.02))
			_sphere(hair, "Core", 0.08, _mats["hair"], Vector3(0, 0.12, -0.02))
		"wind_sweep":
			_capsule(hair, "Sweep", 0.12, 0.2, _mats["hair"], Vector3(0.04, 0.12, -0.06))
			_prism(hair, "Ribbon", Vector3(0.06, 0.2, 0.04), _mats["accent"], Vector3(-0.1, 0.1, -0.08))
		"ice_spikes":
			_prism(hair, "Spike1", Vector3(0.04, 0.16, 0.04), _mats["accent"], Vector3(-0.06, 0.16, -0.02))
			_prism(hair, "Spike2", Vector3(0.04, 0.2, 0.04), _mats["accent"], Vector3(0.0, 0.18, -0.04))
			_prism(hair, "Spike3", Vector3(0.04, 0.14, 0.04), _mats["hair"], Vector3(0.06, 0.15, -0.02))
		"orbit_crown":
			_cylinder(hair, "Crown", 0.12, 0.04, _mats["accent"], Vector3(0, 0.14, 0))
			_sphere(hair, "Orb", 0.04, _mats["accent"], Vector3(0.12, 0.18, 0))
		"shadow_hood":
			_capsule(hair, "Hood", 0.15, 0.18, _mats["secondary"], Vector3(0, 0.08, -0.04))
			_prism(hair, "Cowl", Vector3(0.22, 0.1, 0.12), _mats["cloth"], Vector3(0.03, 0.02, -0.08))
		_:
			_capsule(hair, "Short", 0.12, 0.1, _mats["hair"], Vector3(0, 0.12, -0.02))


func _build_clothes(kinds: Array) -> void:
	var chest: Node3D = _parts.get("Chest")
	var hip: Node3D = _parts.get("Hip")
	var neck: Node3D = _parts.get("Neck")
	if chest == null:
		return
	for kind in kinds:
		match str(kind):
			"chest_plate":
				_capsule(chest, "ChestPlate", 0.17, 0.14, _mats["accent"], Vector3(0, 0.02, 0.06))
			"skirt":
				if hip:
					_prism(hip, "Skirt", Vector3(0.28, 0.14, 0.16), _mats["cloth"], Vector3(0, -0.08, 0))
			"sash":
				_capsule(chest, "Sash", 0.15, 0.05, _mats["accent"], Vector3(0, -0.06, 0.08))
			"scarf":
				if neck:
					_capsule(neck, "Scarf", 0.08, 0.06, _mats["accent"], Vector3(0.02, 0.0, 0.06))
					_prism(neck, "ScarfTail", Vector3(0.06, 0.18, 0.04), _mats["cloth"], Vector3(0.1, -0.1, -0.04))
			"pauldrons":
				_sphere(chest, "PauldronL", 0.08, _mats["secondary"], Vector3(-0.2, 0.1, 0))
				_sphere(chest, "PauldronR", 0.08, _mats["secondary"], Vector3(0.2, 0.1, 0))
			"hood":
				# Hood volume lives on hair for Nix/Vesper; add cowl strip on chest.
				_prism(chest, "HoodCowl", Vector3(0.2, 0.08, 0.1), _mats["cloth"], Vector3(0, 0.12, -0.08))
			"mantle":
				_prism(chest, "Mantle", Vector3(0.32, 0.28, 0.06), _mats["secondary"], Vector3(0, -0.02, -0.12))
			"gauntlets":
				var lf: Node3D = _parts.get("LForeArm")
				var rf: Node3D = _parts.get("RForeArm")
				if lf:
					_cylinder(lf, "GauntletL", 0.055, 0.08, _mats["accent"], Vector3(0, -0.04, 0))
				if rf:
					_cylinder(rf, "GauntletR", 0.055, 0.08, _mats["accent"], Vector3(0, -0.04, 0))


func _joint(part_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = part_name
	n.position = pos
	parent.add_child(n)
	_parts[part_name] = n
	return n


func _capsule(parent: Node3D, mesh_name: String, radius: float, height: float, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	var mesh := CapsuleMesh.new()
	mesh.radius = maxf(radius, 0.01)
	mesh.height = maxf(height, radius * 2.0 + 0.01)
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, mesh_name: String, radius: float, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	var mesh := SphereMesh.new()
	mesh.radius = maxf(radius, 0.01)
	mesh.height = maxf(radius, 0.01) * 2.0
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cylinder(parent: Node3D, mesh_name: String, radius: float, height: float, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = maxf(radius, 0.01)
	mesh.bottom_radius = maxf(radius, 0.01)
	mesh.height = maxf(height, 0.02)
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _prism(parent: Node3D, mesh_name: String, size: Vector3, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	var mesh := PrismMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cache_rest() -> void:
	_rest.clear()
	for key in _parts.keys():
		var n: Node3D = _parts[key]
		_rest[key] = {
			"position": n.position,
			"rotation": n.rotation_degrees,
			"scale": n.scale,
		}


func _reset_to_rest() -> void:
	for key in _rest.keys():
		var n: Node3D = _parts.get(key)
		if n == null:
			continue
		var r: Dictionary = _rest[key]
		n.position = r["position"]
		n.rotation_degrees = r["rotation"]
		n.scale = r["scale"]


func _rot(part: String, degrees: Vector3) -> void:
	var n: Node3D = _parts.get(part)
	if n == null:
		return
	var base: Vector3 = _rest.get(part, {}).get("rotation", Vector3.ZERO)
	n.rotation_degrees = base + degrees


func _pose_idle(phase: float) -> void:
	var bob := sin(phase) * 0.015
	var hip: Node3D = _parts.get("Hip")
	if hip:
		hip.position.y = float(_rest["Hip"]["position"].y) + bob
	_rot("Torso", Vector3(sin(phase * 0.5) * 2.0, 0, 0))
	_rot("LUpperArm", Vector3(sin(phase) * 4.0, 0, -4.0))
	_rot("RUpperArm", Vector3(-sin(phase) * 4.0, 0, 4.0))
	_rot("Head", Vector3(sin(phase * 0.7) * 3.0, sin(phase * 0.35) * 6.0, 0))


func _pose_locomotion(phase: float, bounce: float, swing: float) -> void:
	var hip: Node3D = _parts.get("Hip")
	if hip:
		hip.position.y = float(_rest["Hip"]["position"].y) + absf(sin(phase)) * bounce * 0.08
	_rot("LThigh", Vector3(sin(phase) * swing, 0, 0))
	_rot("RThigh", Vector3(-sin(phase) * swing, 0, 0))
	_rot("LShin", Vector3(maxf(0.0, -sin(phase)) * swing * 0.7, 0, 0))
	_rot("RShin", Vector3(maxf(0.0, sin(phase)) * swing * 0.7, 0, 0))
	_rot("LUpperArm", Vector3(-sin(phase) * swing * 0.8, 0, -8.0))
	_rot("RUpperArm", Vector3(sin(phase) * swing * 0.8, 0, 8.0))
	_rot("Torso", Vector3(0, sin(phase) * 6.0, 0))


func _pose_jump(u: float) -> void:
	_rot("LThigh", Vector3(-35.0 * u, 0, -8.0))
	_rot("RThigh", Vector3(-30.0 * u, 0, 8.0))
	_rot("LUpperArm", Vector3(-50.0 * u, 0, -20.0))
	_rot("RUpperArm", Vector3(-45.0 * u, 0, 20.0))
	_rot("Chest", Vector3(-8.0 * u, 0, 0))


func _pose_fall(phase: float) -> void:
	_rot("LUpperArm", Vector3(-30.0 + sin(phase) * 8.0, 0, -25.0))
	_rot("RUpperArm", Vector3(-30.0 - sin(phase) * 8.0, 0, 25.0))
	_rot("LThigh", Vector3(20.0, 0, -10.0))
	_rot("RThigh", Vector3(15.0, 0, 10.0))


func _pose_land(u: float) -> void:
	var squash := sin(u * PI)
	_rot("LThigh", Vector3(40.0 * squash, 0, 0))
	_rot("RThigh", Vector3(40.0 * squash, 0, 0))
	_rot("Torso", Vector3(12.0 * squash, 0, 0))
	_rot("LUpperArm", Vector3(20.0 * squash, 0, -15.0))
	_rot("RUpperArm", Vector3(20.0 * squash, 0, 15.0))


func _pose_jab(u: float, left: bool) -> void:
	var punch := sin(clampf(u, 0.0, 1.0) * PI)
	var arm := "LUpperArm" if left else "RUpperArm"
	var fore := "LForeArm" if left else "RForeArm"
	_rot(arm, Vector3(-70.0 * punch, 0, (15.0 if left else -15.0) * punch))
	_rot(fore, Vector3(-20.0 * punch, 0, 0))
	_rot("Torso", Vector3(0, (18.0 if left else -18.0) * punch, 0))
	_rot("Chest", Vector3(-6.0 * punch, 0, 0))


func _pose_heavy(u: float) -> void:
	var wind := clampf(u * 2.0, 0.0, 1.0) if u < 0.5 else 1.0
	var strike := 0.0 if u < 0.5 else sin((u - 0.5) * 2.0 * PI)
	_rot("RUpperArm", Vector3(-40.0 * wind + -90.0 * strike, 20.0 * strike, -25.0))
	_rot("RForeArm", Vector3(-30.0 * strike, 0, 0))
	_rot("Torso", Vector3(5.0, -30.0 * strike, 0))
	_rot("LUpperArm", Vector3(20.0 * wind, 0, -20.0))


func _pose_special(u: float) -> void:
	var lift := sin(u * PI)
	_rot("LUpperArm", Vector3(-110.0 * lift, 0, -30.0))
	_rot("RUpperArm", Vector3(-110.0 * lift, 0, 30.0))
	_rot("Chest", Vector3(-15.0 * lift, 0, 0))
	_rot("Head", Vector3(-10.0 * lift, 0, 0))


func _pose_shield() -> void:
	_rot("LUpperArm", Vector3(-50.0, 20.0, -40.0))
	_rot("RUpperArm", Vector3(-50.0, -20.0, 40.0))
	_rot("LForeArm", Vector3(-40.0, 0, 0))
	_rot("RForeArm", Vector3(-40.0, 0, 0))
	_rot("Torso", Vector3(8.0, 0, 0))


func _pose_hurt(amount: float) -> void:
	_rot("Torso", Vector3(18.0 * amount, 12.0 * amount, 0))
	_rot("Head", Vector3(10.0 * amount, -15.0 * amount, 0))
	_rot("LUpperArm", Vector3(-20.0 * amount, 0, -25.0))
	_rot("RUpperArm", Vector3(-20.0 * amount, 0, 25.0))


func _pose_launched(phase: float) -> void:
	_rot("Torso", Vector3(-25.0 + sin(phase) * 10.0, 0, 0))
	_rot("LUpperArm", Vector3(-120.0, 0, -40.0))
	_rot("RUpperArm", Vector3(-110.0, 0, 40.0))
	_rot("LThigh", Vector3(-40.0, 0, -15.0))
	_rot("RThigh", Vector3(-35.0, 0, 15.0))


func _pose_aura_charge(phase: float) -> void:
	var pulse := 0.5 + 0.5 * sin(phase * 1.5)
	_rot("LUpperArm", Vector3(-70.0 * pulse, 0, -50.0 * pulse))
	_rot("RUpperArm", Vector3(-70.0 * pulse, 0, 50.0 * pulse))
	_rot("Chest", Vector3(-8.0 * pulse, 0, 0))
	_rot("Head", Vector3(-5.0 * pulse, 0, 0))
	var hip: Node3D = _parts.get("Hip")
	if hip:
		hip.position.y = float(_rest["Hip"]["position"].y) + pulse * 0.04


func _pose_aura_burst(u: float) -> void:
	var blast := sin(u * PI)
	_rot("LUpperArm", Vector3(-140.0 * blast, 0, -60.0))
	_rot("RUpperArm", Vector3(-140.0 * blast, 0, 60.0))
	_rot("Chest", Vector3(-20.0 * blast, 0, 0))
	_rot("Torso", Vector3(0, 0, sin(u * TAU) * 8.0))


func _pose_throw(arm_deg: Vector3) -> void:
	_rot("RUpperArm", arm_deg)
	_rot("RForeArm", Vector3(-25.0, 0, 0))
	_rot("Torso", Vector3(arm_deg.x * 0.25, arm_deg.y * 0.4, 0))
	_rot("LUpperArm", Vector3(-20.0, 0, -30.0))


func _pose_ko(u: float) -> void:
	_rot("Torso", Vector3(55.0 * u, 0, 18.0 * u))
	_rot("Head", Vector3(30.0 * u, 0, 0))
	_rot("LThigh", Vector3(50.0 * u, 0, -10.0))
	_rot("RThigh", Vector3(45.0 * u, 0, 10.0))
	_rot("LUpperArm", Vector3(-30.0, 0, -50.0 * u))
	_rot("RUpperArm", Vector3(-30.0, 0, 50.0 * u))
	var hip: Node3D = _parts.get("Hip")
	if hip:
		hip.position.y = float(_rest["Hip"]["position"].y) - 0.2 * u


func _pose_victory(phase: float) -> void:
	_rot("RUpperArm", Vector3(-140.0 + sin(phase) * 8.0, 0, 20.0))
	_rot("LUpperArm", Vector3(-20.0, 0, -25.0))
	_rot("Chest", Vector3(-8.0, 12.0, 0))
	_rot("Head", Vector3(-5.0, sin(phase * 0.5) * 10.0, 0))


func _pose_defeat() -> void:
	_rot("Torso", Vector3(22.0, 0, 0))
	_rot("Head", Vector3(18.0, 8.0, 0))
	_rot("LUpperArm", Vector3(15.0, 0, -20.0))
	_rot("RUpperArm", Vector3(15.0, 0, 20.0))
	_rot("LThigh", Vector3(35.0, 0, 0))
	_rot("RThigh", Vector3(35.0, 0, 0))
	var hip: Node3D = _parts.get("Hip")
	if hip:
		hip.position.y = float(_rest["Hip"]["position"].y) - 0.12
