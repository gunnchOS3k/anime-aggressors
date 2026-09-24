extends RefCounted
class_name ElementalMaterialContract

## Roster-wide cel language + per-fighter elemental body identity.
## Applies to candidate models without promoting HUMAN_APPROVED.

const _DATA_PATH := "res://data/runtime/elemental_material_language.json"
const _TOON_SHADER := "res://shaders/fighter_toon.gdshader"

static var _cache: Dictionary = {}


static func language() -> Dictionary:
	_ensure()
	return _cache


static func fighter_entry(fighter_id: String) -> Dictionary:
	_ensure()
	var fighters: Dictionary = _cache.get("fighters", {})
	return fighters.get(fighter_id, {})


static func has_three_value_groups(fighter_id: String) -> bool:
	var entry := fighter_entry(fighter_id)
	return entry.has("core") and entry.has("structure") and entry.has("accent")


static func color_from_arr(arr: Variant, fallback: Color) -> Color:
	if typeof(arr) != TYPE_ARRAY:
		return fallback
	var a: Array = arr
	if a.size() < 3:
		return fallback
	return Color(float(a[0]), float(a[1]), float(a[2]), 1.0)


static func apply_to_root(root: Node, fighter_id: String, charge: float = 0.0, vfx_on: bool = true) -> int:
	var entry := fighter_entry(fighter_id)
	if entry.is_empty() or root == null:
		return 0
	var shader_res: Resource = load(_TOON_SHADER)
	var cel: Dictionary = _cache.get("cel_shading", {})
	var core := color_from_arr(entry.get("core"), Color(0.12, 0.12, 0.14))
	var structure := color_from_arr(entry.get("structure"), Color(0.35, 0.35, 0.38))
	var accent := color_from_arr(entry.get("accent"), Color(0.85, 0.8, 0.7))
	var charged := clampf(charge, 0.0, 1.0)
	var emission := float(cel.get("emission_idle", 0.12)) + charged * float(cel.get("emission_charge_max", 0.85))
	if not vfx_on:
		emission *= 0.35
	var applied := 0
	applied += _apply_recursive(root, shader_res, core, structure, accent, cel, emission, charged, fighter_id)
	return applied


static func charge_transforms_body(fighter_id: String) -> String:
	return str(fighter_entry(fighter_id).get("charge", ""))


static func _apply_recursive(
	node: Node,
	shader_res: Resource,
	core: Color,
	structure: Color,
	accent: Color,
	cel: Dictionary,
	emission: float,
	charged: float,
	fighter_id: String
) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var source: Material = mesh.get_active_material(0)
		var luma := 0.45
		if source is StandardMaterial3D:
			var alb: Color = (source as StandardMaterial3D).albedo_color
			luma = alb.r * 0.3 + alb.g * 0.59 + alb.b * 0.11
		elif source is ShaderMaterial:
			var bc: Variant = (source as ShaderMaterial).get_shader_parameter("base_color")
			if bc is Color:
				luma = (bc as Color).r * 0.3 + (bc as Color).g * 0.59 + (bc as Color).b * 0.11
		var band := structure
		if luma < 0.28:
			band = core
		elif luma > 0.62:
			band = accent
		if charged > 0.35:
			band = band.lerp(accent, charged * 0.35)
		if shader_res is Shader:
			var mat := ShaderMaterial.new()
			mat.resource_local_to_scene = true
			mat.shader = shader_res as Shader
			mat.set_shader_parameter("base_color", band)
			mat.set_shader_parameter("team_tint", structure.lerp(Color.WHITE, 0.08))
			mat.set_shader_parameter("toon_bands", float(cel.get("toon_bands", 3.0)))
			mat.set_shader_parameter("rim_strength", float(cel.get("rim_strength", 0.32)) + charged * 0.18)
			mat.set_shader_parameter("aura_emission", emission)
			mat.set_shader_parameter("outline_width", float(cel.get("outline_width", 0.018)))
			mat.set_shader_parameter("outline_color", Color(0.04, 0.04, 0.06, 1.0))
			if fighter_id == "vesper-nyx" and charged > 0.4:
				mat.set_shader_parameter("aura_emission", emission * 0.7)
			mesh.material_override = mat
			count += 1
		elif source is StandardMaterial3D:
			var local: StandardMaterial3D = (source as StandardMaterial3D).duplicate(true)
			local.resource_local_to_scene = true
			local.albedo_color = band
			local.emission_enabled = true
			local.emission = accent
			local.emission_energy_multiplier = emission
			mesh.material_override = local
			count += 1
	for child in node.get_children():
		count += _apply_recursive(child, shader_res, core, structure, accent, cel, emission, charged, fighter_id)
	return count


static func _ensure() -> void:
	if not _cache.is_empty():
		return
	if not FileAccess.file_exists(_DATA_PATH):
		return
	var f := FileAccess.open(_DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = parsed
