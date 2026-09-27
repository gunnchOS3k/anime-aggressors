extends RefCounted
class_name ElementalVfxFamily

## Visual-only elemental accents. Hierarchy: body → contact → defender → primary → trail → particles.
## VFX amplify the hit; they do not create the hit.

const FAMILIES := {
	"ember-vale": {
		"primary": "flame_tongues",
		"secondary": "heat_trail_embers",
		"hit": "warm_edge_flash",
		"charge": "core_brighten",
		"clash": "furnace_pressure",
		"particle_budget": 18,
	},
	"rook-ironside": {
		"primary": "impact_ring",
		"secondary": "dust_burst",
		"hit": "armor_compression",
		"charge": "mass_settle",
		"clash": "impact_shock",
		"particle_budget": 14,
	},
	"juno-spark": {
		"primary": "jagged_arc",
		"secondary": "short_afterimage",
		"hit": "branch_arc_snap",
		"charge": "current_flicker",
		"clash": "unstable_current",
		"particle_budget": 16,
	},
	"kaia-windrow": {
		"primary": "wind_ribbon",
		"secondary": "crescent_stream",
		"hit": "pressure_curve",
		"charge": "lifted_scarf",
		"clash": "crosswind",
		"particle_budget": 16,
	},
	"nix-calder": {
		"primary": "crystal_lance",
		"secondary": "frost_mist",
		"hit": "rigid_lock_trace",
		"charge": "facet_growth",
		"clash": "frost_lattice",
		"particle_budget": 14,
	},
	"orion-vell": {
		"primary": "constellation_nodes",
		"secondary": "orbit_ring",
		"hit": "inward_then_out",
		"charge": "orbit_tighten",
		"clash": "gravity_warp",
		"particle_budget": 16,
	},
	"vesper-nyx": {
		"primary": "void_seam",
		"secondary": "ghost_offset",
		"hit": "phase_smear",
		"charge": "partial_phase",
		"clash": "phase_tear",
		"particle_budget": 12,
	},
}

const READ_ORDER := [
	"body_pose",
	"contact_point",
	"defender_reaction",
	"primary_elemental_effect",
	"secondary_trail",
	"particles",
	"camera",
	"hud",
]


static func family(fighter_id: String) -> Dictionary:
	return FAMILIES.get(fighter_id, {})


static func complete() -> bool:
	return FAMILIES.size() == 7


static func particle_budget(fighter_id: String) -> int:
	return int(family(fighter_id).get("particle_budget", 12))
