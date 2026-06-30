extends RefCounted
class_name FighterSilhouetteProfile

const PROFILES := {
	"ember-vale": {
		"shape": "athletic",
		"accent": "flame_gauntlets",
		"hair": "angular_crest",
		"hand_scale": 1.35,
		"foot_scale": 1.1,
		"head_scale": 1.05,
	},
	"juno-spark": {
		"shape": "compact",
		"accent": "volt_scarf",
		"hair": "bolt_tufts",
		"hand_scale": 1.2,
		"foot_scale": 1.0,
		"head_scale": 1.15,
	},
	"rook-ironside": {
		"shape": "broad",
		"accent": "impact_shoulders",
		"hair": "helm",
		"hand_scale": 1.25,
		"foot_scale": 1.3,
		"head_scale": 0.95,
	},
	"kaia-windrow": {
		"shape": "athletic",
		"accent": "gale_sash",
		"hair": "flow",
		"hand_scale": 1.1,
		"foot_scale": 1.05,
		"head_scale": 1.0,
	},
	"nix-calder": {
		"shape": "broad",
		"accent": "frost_mantle",
		"hair": "angular_crest",
		"hand_scale": 1.2,
		"foot_scale": 1.25,
		"head_scale": 1.0,
	},
	"orion-vell": {
		"shape": "athletic",
		"accent": "gravity_rings",
		"hair": "helm",
		"hand_scale": 1.1,
		"foot_scale": 1.05,
		"head_scale": 1.0,
	},
	"vesper-nyx": {
		"shape": "compact",
		"accent": "void_hood",
		"hair": "hood",
		"hand_scale": 1.1,
		"foot_scale": 1.0,
		"head_scale": 1.1,
	},
}

static func get(fighter_id: String) -> Dictionary:
	return PROFILES.get(fighter_id, PROFILES["ember-vale"]).duplicate(true)
