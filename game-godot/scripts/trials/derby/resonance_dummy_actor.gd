extends RefCounted
class_name ResonanceDummyActor
## Authored original Resonance Trial impact-dummy — NOT a roster fighter stand-in.
## Owns identity + procedural body geometry. HUMAN_ART stays false until Codex art lands.

const DUMMY_ID := "resonance-impact-dummy"
const DISPLAY_NAME := "Impact Dummy"
const ROLE := "training_dummy"

## Kinetic Bat launch + distance scoring are owned by ResonanceTrialSim.
## This actor is the named trial opponent for live BattleScene / journey honesty.


static func identity() -> Dictionary:
	return {
		"actor_id": DUMMY_ID,
		"display_name": DISPLAY_NAME,
		"role": ROLE,
		"is_roster_fighter": false,
		"not_rook_standin": true,
		"not_roster_standin": true,
		"supports_bat_launch": true,
		"supports_distance_scoring": true,
		"authored_body": body_profile(),
		"HUMAN_ART": false,
		"art_status": "SCAFFOLD_PROCEDURAL",
	}


static func body_profile() -> Dictionary:
	## Original procedural capsule — not Rook Ironside geometry or identity.
	return {
		"kind": "authored_procedural_capsule",
		"height_px": 96,
		"radius_px": 28,
		"mass": 100,
		"launch_affinity": 1.0,
		"color": Color(0.72, 0.74, 0.78),
		"not_rook_silhouette": true,
		"not_fighter_mesh_claim": true,
		"HUMAN_ART": false,
	}


static func battle_fighter_id() -> String:
	## Dedicated non-roster dummy id (data/fighters/resonance-impact-dummy.json).
	## Never rook-ironside. Not counted among the 10 roster fighters.
	return DUMMY_ID


static func live_cpu_config() -> Dictionary:
	var idn: Dictionary = identity()
	idn["fighter_id"] = battle_fighter_id()
	idn["training_dummy_mode"] = "idle"
	idn["p2_is_cpu"] = true
	idn["controls_enabled"] = false
	idn["honesty"] = "Authored ResonanceDummyActor body — not a roster fighter stand-in"
	return idn
