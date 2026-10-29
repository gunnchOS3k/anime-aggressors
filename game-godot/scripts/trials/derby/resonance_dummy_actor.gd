extends RefCounted
class_name ResonanceDummyActor
## Dedicated Resonance Trial impact-dummy identity — not a roster fighter stand-in.
## Presentation/sim contract only; HUMAN_ART stays false until Codex art lands.

const DUMMY_ID := "resonance_impact_dummy"
const DISPLAY_NAME := "Impact Dummy"
const ROLE := "training_dummy"

## Kinetic Bat launch + distance scoring are owned by ResonanceTrialSim.
## This actor describes the dummy body for live BattleScene / journey honesty.


static func identity() -> Dictionary:
	return {
		"actor_id": DUMMY_ID,
		"display_name": DISPLAY_NAME,
		"role": ROLE,
		"is_roster_fighter": false,
		"not_rook_standin": true,
		"supports_bat_launch": true,
		"supports_distance_scoring": true,
		"HUMAN_ART": false,
		"art_status": "SCAFFOLD_PROCEDURAL",
	}


static func battle_standin_fighter_id() -> String:
	## Until a dedicated dummy mesh exists, reuse rook collision silhouette ONLY as
	## physics body geometry — identity fields above remain the true actor claim.
	return "rook-ironside"


static func live_cpu_config() -> Dictionary:
	var idn: Dictionary = identity()
	idn["standin_fighter_id"] = battle_standin_fighter_id()
	idn["training_dummy_mode"] = "idle"
	idn["p2_is_cpu"] = true
	idn["controls_enabled"] = false
	idn["honesty"] = "Geometry stand-in only; ResonanceDummyActor is the named trial actor"
	return idn
