extends RefCounted
class_name FighterAppearance

const APPEARANCES := {
	"ember-vale": {
		"primary": Color(0.92, 0.28, 0.20),
		"secondary": Color(0.24, 0.08, 0.06),
		"accent": Color(1.0, 0.65, 0.20),
		"outline": Color(0.10, 0.02, 0.02),
		"glow": Color(1.0, 0.36, 0.24, 0.55),
		"aura_width": 2.4
	},
	"rook-ironside": {
		"primary": Color(0.46, 0.34, 0.28),
		"secondary": Color(0.16, 0.14, 0.14),
		"accent": Color(0.72, 0.56, 0.38),
		"outline": Color(0.08, 0.08, 0.08),
		"glow": Color(0.72, 0.56, 0.38, 0.45),
		"aura_width": 1.8
	},
	"juno-spark": {
		"primary": Color(1.0, 0.90, 0.20),
		"secondary": Color(0.17, 0.18, 0.30),
		"accent": Color(0.80, 0.95, 1.0),
		"outline": Color(0.05, 0.05, 0.10),
		"glow": Color(1.0, 0.95, 0.45, 0.65),
		"aura_width": 2.2
	},
	"kaia-windrow": {
		"primary": Color(0.38, 0.86, 0.48),
		"secondary": Color(0.10, 0.24, 0.14),
		"accent": Color(0.72, 1.0, 0.84),
		"outline": Color(0.02, 0.10, 0.06),
		"glow": Color(0.42, 0.94, 0.58, 0.55),
		"aura_width": 2.6
	},
	"nix-calder": {
		"primary": Color(0.26, 0.66, 1.0),
		"secondary": Color(0.08, 0.15, 0.30),
		"accent": Color(0.70, 0.90, 1.0),
		"outline": Color(0.03, 0.06, 0.12),
		"glow": Color(0.38, 0.76, 1.0, 0.5),
		"aura_width": 2.0
	},
	"orion-vell": {
		"primary": Color(0.40, 0.32, 0.90),
		"secondary": Color(0.15, 0.09, 0.28),
		"accent": Color(0.86, 0.82, 1.0),
		"outline": Color(0.05, 0.02, 0.10),
		"glow": Color(0.58, 0.48, 1.0, 0.5),
		"aura_width": 2.1
	},
	"vesper-nyx": {
		"primary": Color(0.55, 0.15, 0.78),
		"secondary": Color(0.13, 0.05, 0.20),
		"accent": Color(0.92, 0.48, 0.98),
		"outline": Color(0.05, 0.01, 0.08),
		"glow": Color(0.66, 0.20, 0.88, 0.58),
		"aura_width": 2.3
	}
}

static func get_style(fighter_id: String) -> Dictionary:
	if APPEARANCES.has(fighter_id):
		return APPEARANCES[fighter_id].duplicate(true)
	return APPEARANCES["ember-vale"].duplicate(true)
