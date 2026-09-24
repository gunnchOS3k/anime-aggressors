extends Node
class_name FighterMaterialController

## Cel/toon material runtime controls for roster fighters, including elemental charge.

const _ElementalMaterial = preload("res://scripts/visual/elemental_material_contract.gd")

@export var team_color: Color = Color.WHITE
@export var accessibility_reduce_flash: bool = false

var _mesh_instances: Array[MeshInstance3D] = []
var _base_colors: Dictionary = {}
var _bound_root: Node3D
var _fighter_id: String = ""
var _presentation_context: String = ""


func bind_model(root: Node3D, fighter_id: String = "") -> void:
	_bound_root = root
	_fighter_id = fighter_id
	_mesh_instances.clear()
	_base_colors.clear()
	_localize_materials(root)
	_collect_meshes(root)
	_apply_team_tint()
	if not fighter_id.is_empty():
		_ElementalMaterial.apply_to_root(root, fighter_id, 0.0, true, _presentation_context)


func set_presentation_context(context: String) -> void:
	_presentation_context = context
	if _bound_root != null and not _fighter_id.is_empty():
		_ElementalMaterial.apply_to_root(_bound_root, _fighter_id, 0.0, true, _presentation_context)


func _localize_materials(node: Node) -> void:
	## Wave020 isolation: duplicate shared GLB materials so runtime tint never whiteouts siblings.
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var active: Material = mesh.get_active_material(0)
		if active != null:
			var local: Material = active.duplicate(true)
			if local is Resource:
				(local as Resource).resource_local_to_scene = true
			mesh.material_override = local
	for child in node.get_children():
		_localize_materials(child)


func set_hit_flash(intensity: float = 1.0) -> void:
	if accessibility_reduce_flash:
		intensity *= 0.25
	for mesh in _mesh_instances:
		if mesh == null:
			continue
		var mat: Material = mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("hit_flash", clampf(intensity, 0.0, 1.0))


func set_charge_emission(level: float) -> void:
	var charged := clampf(level, 0.0, 2.0)
	if _bound_root != null and not _fighter_id.is_empty():
		_ElementalMaterial.apply_to_root(_bound_root, _fighter_id, clampf(charged / 2.0, 0.0, 1.0), true, _presentation_context)
	for mesh in _mesh_instances:
		if mesh == null:
			continue
		var mat: Material = mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("aura_emission", charged)


func set_team_color(color: Color) -> void:
	team_color = color
	_apply_team_tint()


func set_accessibility_reduce_flash(enabled: bool) -> void:
	accessibility_reduce_flash = enabled
	for mesh in _mesh_instances:
		if mesh == null:
			continue
		var mat: Material = mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("accessibility_reduce_flash", enabled)


func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_mesh_instances.append(node)
		var mat: Material = node.get_active_material(0)
		if mat and mat is ShaderMaterial:
			_base_colors[node.get_instance_id()] = mat.get_shader_parameter("base_color")
	for child in node.get_children():
		_collect_meshes(child)


func _apply_team_tint() -> void:
	for mesh in _mesh_instances:
		if mesh == null:
			continue
		var mat: Material = mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			var base: Color = _base_colors.get(mesh.get_instance_id(), Color.WHITE)
			(mat as ShaderMaterial).set_shader_parameter("team_tint", base.lerp(team_color, 0.18))
