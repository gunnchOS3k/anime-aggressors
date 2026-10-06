extends Node

## Skinned facial morphs share the combat and Story clocks. Candidate acting, owner gate false.
const EXPRESSIONS := ["battle_intent", "attack_effort", "pain", "shock", "fear", "grief", "determination", "victory", "defeat", "cinematic_closeup"]
const ALIASES := {"focused":"battle_intent", "confident":"determination", "charging":"attack_effort", "hurt":"pain", "angry":"battle_intent", "smirk":"victory", "calm":"neutral"}
var meshes: Array[MeshInstance3D] = []
var expression := "neutral"
var form := "BASE"
var fighter_id := ""
var _targets: Dictionary = {}
var _stone_texture: NoiseTexture2D

func configure(body: Node3D, id: String, state_form: String) -> void:
	fighter_id = id
	form = state_form
	meshes.clear()
	_collect(body)
	if id == "rook-ironside":
		_apply_stone_surface(body)
	set_expression("neutral")

func _collect(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null and node.mesh.get_blend_shape_count() > 0:
		meshes.append(node)
	for child in node.get_children():
		_collect(child)

func set_expression(value: String, immediate: bool = false) -> void:
	expression = str(ALIASES.get(value, value))
	if expression != "neutral" and expression not in EXPRESSIONS:
		expression = "neutral"
	_targets.clear()
	for mesh in meshes:
		for index in range(mesh.mesh.get_blend_shape_count()):
			var name := str(mesh.mesh.get_blend_shape_name(index))
			var weight := 1.0 if name == expression else 0.0
			# Possession suppresses free affect without erasing the original facial identity.
			if "PUPPET" in form:
				weight *= 0.18 if expression in ["victory", "cinematic_closeup"] else 0.48
			_targets[name] = weight
			if immediate:
				mesh.set_blend_shape_value(index, weight)

func _process(delta: float) -> void:
	for mesh in meshes:
		if not is_instance_valid(mesh):
			continue
		for index in range(mesh.mesh.get_blend_shape_count()):
			var target := float(_targets.get(str(mesh.mesh.get_blend_shape_name(index)), 0.0))
			mesh.set_blend_shape_value(index, move_toward(mesh.get_blend_shape_value(index), target, delta * 9.0))

func evidence() -> Dictionary:
	return {"fighter_id":fighter_id, "form":form, "expression":expression, "morph_meshes":meshes.size(), "owner_approved":false}


func _apply_stone_surface(body: Node) -> void:
	if body is MeshInstance3D and body.mesh != null:
		for surface in range(body.mesh.get_surface_count()):
			var material = body.get_active_material(surface)
			if material is StandardMaterial3D and str(material.resource_name).begins_with("Elemental porcelain"):
				var stone = material.duplicate() as StandardMaterial3D
				if _stone_texture == null:
					var noise := FastNoiseLite.new()
					noise.seed = 1827
					noise.frequency = 0.055
					_stone_texture = NoiseTexture2D.new()
					_stone_texture.width = 128
					_stone_texture.height = 128
					_stone_texture.as_normal_map = true
					_stone_texture.noise = noise
				stone.normal_enabled = true
				stone.normal_texture = _stone_texture
				stone.normal_scale = 0.35
				stone.roughness = 0.67
				stone.uv1_triplanar = true
				body.set_surface_override_material(surface, stone)
	for child in body.get_children():
		_apply_stone_surface(child)
