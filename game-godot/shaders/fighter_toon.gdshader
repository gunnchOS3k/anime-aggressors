shader_type spatial;
render_mode cull_back, unshaded, blend_mix, depth_draw_always;

uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 team_tint : source_color = vec4(1.0);
uniform vec4 core_color : source_color = vec4(0.2, 0.12, 0.12, 0.82);
uniform vec4 structure_color : source_color = vec4(0.4, 0.32, 0.28, 0.94);
uniform vec4 accent_color : source_color = vec4(0.95, 0.8, 0.35, 1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform sampler2D detail_albedo : source_color, hint_default_white;
uniform bool use_detail = false;
uniform float toon_bands = 3.0;
uniform float rim_strength = 0.35;
uniform float aura_emission = 0.0;
uniform float hit_flash = 0.0;
uniform float outline_width = 0.015;
uniform float body_alpha = 0.82;
uniform vec3 light_dir = vec3(-0.28, 0.82, 0.48);
uniform bool accessibility_reduce_flash = false;

void fragment() {
	vec4 detail = use_detail ? texture(detail_albedo, UV) : vec4(1.0);
	float luma = dot(detail.rgb, vec3(0.30, 0.59, 0.11));
	vec3 band = mix(core_color.rgb, structure_color.rgb, smoothstep(0.16, 0.44, luma));
	band = mix(band, accent_color.rgb, smoothstep(0.58, 0.80, luma));
	vec3 textured = mix(band, band * (0.58 + detail.rgb * 0.72), use_detail ? 0.42 : 0.0);
	vec3 albedo = textured * team_tint.rgb * mix(vec3(1.0), base_color.rgb, 0.18);
	vec3 L = normalize(light_dir);
	float NdotL = clamp(dot(normalize(NORMAL), L), 0.0, 1.0);
	float band_step = floor(NdotL * toon_bands) / max(toon_bands, 1.0);
	vec3 toon = albedo * (0.42 + band_step * 0.58);
	float rim_term = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
	vec3 rim = mix(accent_color.rgb, vec3(1.0), 0.25) * rim_strength * rim_term;
	float flash = accessibility_reduce_flash ? hit_flash * 0.25 : hit_flash;
	vec3 emissive = emission_color.rgb * aura_emission + albedo * (aura_emission * 0.22) + vec3(flash);
	ALBEDO = toon + rim;
	EMISSION = emissive;
	ALPHA = clamp(body_alpha * max(detail.a, 0.82) * core_color.a, 0.62, 0.96);
}
