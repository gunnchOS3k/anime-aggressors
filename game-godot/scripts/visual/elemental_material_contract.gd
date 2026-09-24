extends RefCounted
class_name ElementalMaterialContract

## Single elemental presentation source of truth.
## Select tiles, showcase preview, Labs review, and in-match spawn all derive here.

const _DATA_PATH := "res://data/runtime/elemental_material_language.json"
const _TOON_SHADER := "res://shaders/fighter_toon.gdshader"

const CTX_SELECT_CARD := "SELECT_CARD"
const CTX_SELECT_PREVIEW := "SELECT_PREVIEW"
const CTX_VERSUS := "VERSUS"
const CTX_MOVE_PREVIEW := "MOVE_PREVIEW"
const CTX_REVIEW := "REVIEW"

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


static func has_layered_identity(fighter_id: String) -> bool:
	var entry := fighter_entry(fighter_id)
	return (
		has_three_value_groups(fighter_id)
		and entry.has("emission")
		and entry.has("rim")
		and entry.has("family_hue_deg")
		and entry.has("bible_detail")
	)


static func color_from_arr(arr: Variant, fallback: Color) -> Color:
	if typeof(arr) != TYPE_ARRAY:
		return fallback
	var a: Array = arr
	if a.size() < 3:
		return fallback
	var alpha := fallback.a
	if a.size() >= 4:
		alpha = float(a[3])
	return Color(float(a[0]), float(a[1]), float(a[2]), alpha)


static func is_preview_context(context: String) -> bool:
	return context in [
		CTX_SELECT_CARD,
		CTX_SELECT_PREVIEW,
		CTX_VERSUS,
		CTX_MOVE_PREVIEW,
		CTX_REVIEW,
	]


static func identity_colors(fighter_id: String) -> Dictionary:
	var entry := fighter_entry(fighter_id)
	var core := color_from_arr(entry.get("core"), Color(0.18, 0.12, 0.14, 0.82))
	var structure := color_from_arr(entry.get("structure"), Color(0.36, 0.32, 0.30, 0.94))
	var accent := color_from_arr(entry.get("accent"), Color(0.90, 0.78, 0.40, 1.0))
	var emission := color_from_arr(entry.get("emission"), accent)
	var rim := color_from_arr(entry.get("rim"), accent)
	var tile_primary := color_from_arr(entry.get("tile_primary"), Color(core.r, core.g, core.b, 1.0))
	var tile_accent := color_from_arr(entry.get("tile_accent"), Color(accent.r, accent.g, accent.b, 1.0))
	return {
		"core": core,
		"structure": structure,
		"accent": accent,
		"emission": emission,
		"rim": rim,
		"tile_primary": tile_primary,
		"tile_accent": tile_accent,
		"element": str(entry.get("element", "")),
		"roygbiv_family": str(entry.get("roygbiv_family", "")),
		"family_hue_deg": float(entry.get("family_hue_deg", 0.0)),
		"bible_detail": str(entry.get("bible_detail", "")),
		"charge": str(entry.get("charge", "")),
		"source": _DATA_PATH,
	}


static func apply_to_root(
	root: Node,
	fighter_id: String,
	charge: float = 0.0,
	vfx_on: bool = true,
	context: String = ""
) -> int:
	var entry := fighter_entry(fighter_id)
	if entry.is_empty() or root == null:
		return 0
	var shader_res: Resource = load(_TOON_SHADER)
	var cel: Dictionary = _cache.get("cel_shading", {})
	var preview_cfg: Dictionary = _cache.get("preview", {})
	var gameplay_cfg: Dictionary = _cache.get("gameplay", {})
	var colors := identity_colors(fighter_id)
	var core: Color = colors["core"]
	var structure: Color = colors["structure"]
	var accent: Color = colors["accent"]
	var emission_col: Color = colors["emission"]
	var charged := clampf(charge, 0.0, 1.0)
	var preview := is_preview_context(context)
	var rim_mul := float((preview_cfg if preview else gameplay_cfg).get("rim_multiplier", 1.0))
	var emit_mul := float((preview_cfg if preview else gameplay_cfg).get("emission_multiplier", 1.0))
	var emission := (float(cel.get("emission_idle", 0.16)) + charged * float(cel.get("emission_charge_max", 0.85))) * emit_mul
	if not vfx_on:
		emission *= 0.35
	var light := Vector3(-0.35, 0.85, 0.4)
	if preview:
		light = Vector3(-0.18, 0.72, 0.62)
	var applied := 0
	applied += _apply_recursive(
		root,
		shader_res,
		core,
		structure,
		accent,
		emission_col,
		cel,
		emission,
		charged,
		fighter_id,
		rim_mul,
		light,
		preview
	)
	return applied


static func charge_transforms_body(fighter_id: String) -> String:
	return str(fighter_entry(fighter_id).get("charge", ""))


static func preview_lighting() -> Dictionary:
	_ensure()
	return _cache.get("preview", {})


static func _apply_recursive(
	node: Node,
	shader_res: Resource,
	core: Color,
	structure: Color,
	accent: Color,
	emission_col: Color,
	cel: Dictionary,
	emission: float,
	charged: float,
	fighter_id: String,
	rim_mul: float,
	light: Vector3,
	preview: bool
) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var source: Material = mesh.get_active_material(0)
		var detail_tex: Texture2D = _extract_detail_texture(source)
		var role := _mesh_role(mesh, source)
		var body := core
		var struct_col := structure
		var accent_col := accent
		if charged > 0.35:
			body = body.lerp(accent, charged * 0.28)
			struct_col = struct_col.lerp(accent, charged * 0.18)
		if role == "structure":
			body = struct_col
		elif role == "accent":
			body = accent_col
		var alpha := clampf(body.a if role == "body" else struct_col.a, 0.72, 0.96)
		if preview:
			alpha = clampf(alpha + 0.04, 0.74, 0.94)
		if shader_res is Shader:
			var mat := ShaderMaterial.new()
			mat.resource_local_to_scene = true
			mat.shader = shader_res as Shader
			mat.set_shader_parameter("base_color", Color(body.r, body.g, body.b, 1.0))
			mat.set_shader_parameter("team_tint", struct_col.lerp(Color.WHITE, 0.06))
			mat.set_shader_parameter("core_color", body)
			mat.set_shader_parameter("structure_color", struct_col)
			mat.set_shader_parameter("accent_color", accent_col)
			mat.set_shader_parameter("emission_color", emission_col)
			mat.set_shader_parameter("toon_bands", float(cel.get("toon_bands", 3.0)))
			mat.set_shader_parameter("rim_strength", (float(cel.get("rim_strength", 0.32)) + charged * 0.18) * rim_mul)
			mat.set_shader_parameter("aura_emission", emission * (0.7 if fighter_id == "vesper-nyx" and charged > 0.4 else 1.0))
			mat.set_shader_parameter("outline_width", float(cel.get("outline_width", 0.018)))
			mat.set_shader_parameter("outline_color", Color(0.04, 0.04, 0.06, 1.0))
			mat.set_shader_parameter("body_alpha", alpha)
			mat.set_shader_parameter("light_dir", light)
			mat.set_shader_parameter("use_detail", detail_tex != null)
			if detail_tex != null:
				mat.set_shader_parameter("detail_albedo", detail_tex)
			mesh.material_override = mat
			count += 1
		elif source is StandardMaterial3D:
			var local: StandardMaterial3D = (source as StandardMaterial3D).duplicate(true)
			local.resource_local_to_scene = true
			local.albedo_color = Color(body.r, body.g, body.b, alpha)
			local.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			local.emission_enabled = true
			local.emission = emission_col
			local.emission_energy_multiplier = emission
			local.rim_enabled = true
			local.rim = clampf(0.35 * rim_mul, 0.2, 0.85)
			local.rim_tint = 0.4
			mesh.material_override = local
			count += 1
	for child in node.get_children():
		count += _apply_recursive(
			child,
			shader_res,
			core,
			structure,
			accent,
			emission_col,
			cel,
			emission,
			charged,
			fighter_id,
			rim_mul,
			light,
			preview
		)
	return count


static func _extract_detail_texture(source: Material) -> Texture2D:
	if source is StandardMaterial3D:
		var tex: Texture2D = (source as StandardMaterial3D).albedo_texture
		return tex
	if source is ShaderMaterial:
		var tex_v: Variant = (source as ShaderMaterial).get_shader_parameter("detail_albedo")
		if tex_v is Texture2D:
			return tex_v
	return null


static func _mesh_role(mesh: MeshInstance3D, source: Material) -> String:
	var token := ("%s %s" % [mesh.name, mesh.get_parent().name if mesh.get_parent() else ""]).to_lower()
	for key in ["glove", "gauntlet", "boot", "shoe", "chest", "armor", "plate", "pauldron", "helm", "belt"]:
		if token.contains(key):
			return "structure"
	for key in ["crown", "crest", "crystal", "halo", "scarf", "ribbon", "arc", "orbit"]:
		if token.contains(key):
			return "accent"
	var luma := 0.45
	if source is StandardMaterial3D:
		var alb: Color = (source as StandardMaterial3D).albedo_color
		luma = alb.r * 0.3 + alb.g * 0.59 + alb.b * 0.11
	elif source is ShaderMaterial:
		var bc: Variant = (source as ShaderMaterial).get_shader_parameter("base_color")
		if bc is Color:
			luma = (bc as Color).r * 0.3 + (bc as Color).g * 0.59 + (bc as Color).b * 0.11
	if luma < 0.22:
		return "body"
	if luma > 0.72:
		return "accent"
	return "body"


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
