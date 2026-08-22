shader_type spatial;
render_mode cull_back, unshaded;

uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 team_tint : source_color = vec4(1.0);
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float toon_bands = 3.0;
uniform float rim_strength = 0.35;
uniform float aura_emission = 0.0;
uniform float hit_flash = 0.0;
uniform float outline_width = 0.015;
uniform bool accessibility_reduce_flash = false;

void fragment() {
	vec3 albedo = base_color.rgb * team_tint.rgb;
	vec3 light_dir = normalize(vec3(-0.35, 0.85, 0.4));
	float NdotL = clamp(dot(normalize(NORMAL), light_dir), 0.0, 1.0);
	float band = floor(NdotL * toon_bands) / toon_bands;
	vec3 toon = albedo * (0.35 + band * 0.65);
	vec3 rim = vec3(rim_strength) * pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
	float flash = accessibility_reduce_flash ? hit_flash * 0.25 : hit_flash;
	vec3 emissive = albedo * aura_emission + vec3(flash);
	ALBEDO = toon + rim;
	EMISSION = emissive;
}
