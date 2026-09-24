extends RefCounted
class_name DirectionalHitReaction

## Presentation-only directional hurt families. CombatMath formulas stay untouched.

const FAMILY_LIGHT := "LIGHT_HIT"
const FAMILY_HEAVY := "HEAVY_HIT"
const FAMILY_LAUNCH := "LAUNCH_HIT"
const FAMILY_ELEMENTAL := "ELEMENTAL_SPECIAL_HIT"
const FAMILY_SUPER := "SUPER_HIT"
const FAMILY_CLASH_LOSE := "CLASH_LOSE"

const _Facing := preload("res://scripts/combat/fighter_facing_contract.gd")

const ACCENTS := {
	"ember-vale": "warm_edge_flash_heat_splash",
	"rook-ironside": "body_compression_dust_ring",
	"juno-spark": "sharp_twitch_branch_arc",
	"kaia-windrow": "curved_drift_pressure_stream",
	"nix-calder": "rigid_frost_lock_crystal_trace",
	"orion-vell": "inward_compression_orbit_release",
	"vesper-nyx": "phase_smear_displaced_silhouette",
}


static func family_for(info: Dictionary) -> String:
	var dmg := float(info.get("damage", 0.0))
	var launch: Vector2 = info.get("launch", Vector2.ZERO)
	var move_id := str(info.get("move_id", ""))
	var tier := str(info.get("feedback_tier", info.get("tier", "")))
	if tier == "super" or move_id == "aura_burst":
		return FAMILY_SUPER
	if bool(info.get("clash_lose", false)):
		return FAMILY_CLASH_LOSE
	if move_id in ["side_special", "down_special", "neutral_special_projectile"]:
		return FAMILY_ELEMENTAL
	if launch.length() > 14.0:
		return FAMILY_LAUNCH
	if dmg >= 8.0 or tier == "heavy":
		return FAMILY_HEAVY
	return FAMILY_LIGHT


static func resolve(fighter_id: String, incoming: Vector2, info: Dictionary) -> Dictionary:
	var family := family_for(info)
	var away := _Facing.hurt_away_from_force(incoming)
	return {
		"fighter_id": fighter_id,
		"family": family,
		"incoming": incoming,
		"react_dir": away.get("react_dir"),
		"logical_facing": away.get("logical_facing"),
		"mesh_yaw_deg": away.get("mesh_yaw_deg"),
		"readable_hurt_before_launch": true,
		"launch_follows_force": _Facing.launch_follows_force(incoming),
		"accent": str(ACCENTS.get(fighter_id, "generic_hit")),
		"head_along_force": true,
		"chest_breaks": family != FAMILY_LIGHT,
		"pelvis_counter_rotates": family in [FAMILY_HEAVY, FAMILY_LAUNCH, FAMILY_SUPER],
		"guard_opens": true,
		"legs_lose_balance": family in [FAMILY_LAUNCH, FAMILY_SUPER, FAMILY_ELEMENTAL],
	}


static func families() -> Array:
	return [FAMILY_LIGHT, FAMILY_HEAVY, FAMILY_LAUNCH, FAMILY_ELEMENTAL, FAMILY_SUPER, FAMILY_CLASH_LOSE]
