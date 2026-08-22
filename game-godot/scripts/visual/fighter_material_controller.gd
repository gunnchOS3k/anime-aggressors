extends Node
class_name FighterMaterialController

## Cel/toon material runtime controls for procedural roster fighters.

@export var team_color: Color = Color.WHITE
@export var accessibility_reduce_flash: bool = false

var _mesh_instances: Array[MeshInstance3D] = []
var _base_colors: Dictionary = {}


func bind_model(root: Node3D) -> void:
	_mesh_instances.clear()
	_base_colors.clear()
	_collect_meshes(root)
	_apply_team_tint()


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
	for mesh in _mesh_instances:
		if mesh == null:
			continue
		var mat: Material = mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("aura_emission", clampf(level, 0.0, 2.0))


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
