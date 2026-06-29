extends RefCounted
class_name FighterRoster

const FIGHTERS := {
	"ember-vale": {
		"id": "ember-vale",
		"name": "Ember Vale",
		"element": "fire",
		"size": Vector2(1.02, 0.98),
		"movement_modifiers": {"run": 1.05, "dash": 1.08, "air": 0.96, "jump": 0.98},
		"weight": 1.01,
		"damage_modifiers": {"dealt": 1.06, "taken": 0.98},
		"aura_color": Color(1.0, 0.35, 0.22, 0.9)
	},
	"rook-ironside": {
		"id": "rook-ironside",
		"name": "Rook Ironside",
		"element": "earth",
		"size": Vector2(1.10, 1.04),
		"movement_modifiers": {"run": 0.90, "dash": 0.88, "air": 0.84, "jump": 0.90},
		"weight": 1.25,
		"damage_modifiers": {"dealt": 1.10, "taken": 0.92},
		"aura_color": Color(0.66, 0.42, 0.24, 0.9)
	},
	"juno-spark": {
		"id": "juno-spark",
		"name": "Juno Spark",
		"element": "lightning",
		"size": Vector2(0.96, 0.94),
		"movement_modifiers": {"run": 1.12, "dash": 1.14, "air": 1.06, "jump": 1.05},
		"weight": 0.89,
		"damage_modifiers": {"dealt": 1.00, "taken": 1.06},
		"aura_color": Color(1.0, 0.9, 0.18, 0.9)
	},
	"kaia-windrow": {
		"id": "kaia-windrow",
		"name": "Kaia Windrow",
		"element": "wind",
		"size": Vector2(0.94, 0.92),
		"movement_modifiers": {"run": 1.08, "dash": 1.05, "air": 1.14, "jump": 1.08},
		"weight": 0.85,
		"damage_modifiers": {"dealt": 0.96, "taken": 1.08},
		"aura_color": Color(0.36, 0.88, 0.42, 0.9)
	},
	"nix-calder": {
		"id": "nix-calder",
		"name": "Nix Calder",
		"element": "water",
		"size": Vector2(1.00, 1.00),
		"movement_modifiers": {"run": 0.98, "dash": 1.00, "air": 1.02, "jump": 1.00},
		"weight": 0.98,
		"damage_modifiers": {"dealt": 1.00, "taken": 1.00},
		"aura_color": Color(0.23, 0.64, 1.0, 0.9)
	},
	"orion-vell": {
		"id": "orion-vell",
		"name": "Orion Vell",
		"element": "arcane",
		"size": Vector2(1.04, 1.00),
		"movement_modifiers": {"run": 1.00, "dash": 0.98, "air": 1.04, "jump": 1.02},
		"weight": 1.04,
		"damage_modifiers": {"dealt": 1.03, "taken": 0.99},
		"aura_color": Color(0.42, 0.32, 0.92, 0.9)
	},
	"vesper-nyx": {
		"id": "vesper-nyx",
		"name": "Vesper Nyx",
		"element": "void",
		"size": Vector2(0.98, 1.02),
		"movement_modifiers": {"run": 1.03, "dash": 1.02, "air": 1.10, "jump": 0.96},
		"weight": 0.93,
		"damage_modifiers": {"dealt": 1.08, "taken": 1.03},
		"aura_color": Color(0.54, 0.16, 0.72, 0.9)
	}
}

static func get_ids() -> PackedStringArray:
	return PackedStringArray(FIGHTERS.keys())

static func has_fighter(fighter_id: String) -> bool:
	return FIGHTERS.has(fighter_id)

static func get_fighter(fighter_id: String) -> Dictionary:
	if not has_fighter(fighter_id):
		return {}
	return FIGHTERS[fighter_id].duplicate(true)

static func get_default_fighter() -> Dictionary:
	return get_fighter("ember-vale")
