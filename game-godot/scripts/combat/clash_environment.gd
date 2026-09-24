extends RefCounted
class_name ClashEnvironment

## Bounded environment response. Never writes stage collision.

const PALETTES := {
	"ember-vale": "spiraling flame pressure / heat distortion",
	"rook-ironside": "shock-pressure barrier / dense dust",
	"juno-spark": "forked electricity / rapid pulses",
	"kaia-windrow": "spiral wind vortex / ribbon turbulence",
	"nix-calder": "frost pressure plane / crystalline crack",
	"orion-vell": "gravity compression lens / orbital distortion",
	"vesper-nyx": "void fold / negative-space fracture",
}


static func palette(fid: String) -> String:
	return str(PALETTES.get(fid, "identity_missing"))


static func pulse(a_id: String, b_id: String) -> Dictionary:
	var reduce := false
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null:
			reduce = not bool(gs.training_vfx_enabled)
	return {
		"floor_dust": not reduce,
		"debris": not reduce,
		"light_pulse": not reduce,
		"shadow_pulse": not reduce,
		"aura_wind": not reduce,
		"camera_space_streaks": not reduce,
		"ground_decal_crack_illusion": not reduce,
		"environment_rumble_audio": true,
		"stage_collision_mutated": false,
		"identities": [palette(a_id), palette(b_id)],
		"mixed": a_id != b_id,
		"generic_beam_swap": false,
		"cleanup": true,
		"label": "SYSTEM/VFX PLACEHOLDER — AUTHORED ACTING PENDING",
	}
