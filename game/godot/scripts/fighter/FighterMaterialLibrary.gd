extends RefCounted
class_name FighterMaterialLibrary

static func toon(base: Color, rim: Color = Color(1, 1, 1, 0.35)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.roughness = 0.42
	mat.metallic = 0.05
	mat.rim_enabled = true
	mat.rim = 0.55
	mat.rim_tint = 0.35
	mat.emission_enabled = base.a > 0.4
	mat.emission = base * 0.25
	mat.emission_energy_multiplier = 0.8
	return mat

static func glow(base: Color) -> StandardMaterial3D:
	var mat := toon(base, Color(1, 0.9, 0.7))
	mat.emission_enabled = true
	mat.emission = base
	mat.emission_energy_multiplier = 1.4
	return mat
