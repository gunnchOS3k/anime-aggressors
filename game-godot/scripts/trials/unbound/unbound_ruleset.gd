extends RefCounted
class_name UnboundRuleset
## Convergence Unbound — intentionally unbalanced Mythic/Mayhem-inspired ORIGINAL ruleset.
## Label: UNBALANCED MYTHIC. Never feeds ranked MMR. Opt-in spectacle only.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Eligibility = preload("res://scripts/trials/rosamere_trials_eligibility.gd")

const LABEL := "UNBALANCED MYTHIC"
const MODE_ID := "convergence_unbound"

const PRESET_TOTAL := "total_unbound"
const PRESET_PRISMATIC := "prismatic_storm"
const PRESET_COLOSSUS := "colossus_clash"
const PRESET_KAIJU := "kaiju_siege"
const PRESET_CUSTOM := "custom"


static func base_modifiers() -> Dictionary:
	return {
		"full_supers": true,
		"min_cooldowns": true,
		"cooldown_mult": 0.15,
		"instant_resources": true,
		"extended_transforms": true,
		"transform_duration_mult": 2.5,
		"rapid_respawn": true,
		"respawn_frames": 30,
		"amplified_knockback": true,
		"knockback_mult": 1.85,
		"damage_mult": 1.35,
		"stocks": 7,
		"timer_seconds": 0,  # 0 = infinite spectacle clock
		"feeds_ranked_mmr": false,
		"label": LABEL,
	}


static func preset(preset_id: String) -> Dictionary:
	var m: Dictionary = base_modifiers()
	m["preset_id"] = preset_id
	match preset_id:
		PRESET_TOTAL:
			m["name"] = "Total Unbound"
			m["knockback_mult"] = 2.2
			m["full_supers"] = true
		PRESET_PRISMATIC:
			m["name"] = "Prismatic Storm"
			m["prismatic_unique_per_spectrum"] = true
			m["projectile_mult"] = 2.0
			m["note"] = "Prismatic unique per spectrum fighter — original kits, not third-party copies"
		PRESET_COLOSSUS:
			m["name"] = "Colossus Clash"
			m["colossus_enabled"] = true
			m["scale_aware_collision"] = true
			m["camera_spectacle"] = true
			m["real_giant_engineering"] = true
			m["not_scale_up_transform_only"] = true
			m["controllable_avatars"] = ["cosmic_colossus_yin", "cosmic_colossus_yang", "rosamere_everlasting_origin"]
			m["avatar_ko_is_true_defeat"] = false
		PRESET_KAIJU:
			m["name"] = "Kaiju Siege"
			m["colossus_enabled"] = true
			m["kaiju_waves"] = true
			m["black_white_puppet_echoes"] = true
			m["black_white_are_yin_yang_rosamere_puppets"] = false
			m["requires_separate_approval_for_named_puppets"] = true
			m["spectacle_budget"] = {"vfx_cap": 24, "camera_shakes_per_10s": 4, "a11y_reduce_motion": true}
		PRESET_CUSTOM:
			m["name"] = "Custom Unbound"
			m["editor"] = true
			m["custom_fields"] = ["cooldown_mult", "knockback_mult", "damage_mult", "stocks", "colossus_enabled"]
		_:
			m["name"] = "Total Unbound"
			m["preset_id"] = PRESET_TOTAL
	m["shipping"] = Authority.shipping_flags_false()
	return m


static func all_presets() -> Array:
	return [PRESET_TOTAL, PRESET_PRISMATIC, PRESET_COLOSSUS, PRESET_KAIJU, PRESET_CUSTOM]


static func create_session(seed: int, preset_id: String, mythic_consent: bool = false, seats: int = 2) -> Dictionary:
	var rules: Dictionary = preset(preset_id)
	var seat_truth: Dictionary = Authority.player_count_truth(MODE_ID)
	var seated: int = clampi(seats, int(seat_truth.get("min", 2)), int(seat_truth.get("max", 8)))
	var everlasting_gate: Dictionary = Eligibility.evaluate("EVERLASTING_ORIGIN", MODE_ID, mythic_consent, true)
	return {
		"mode": MODE_ID,
		"frame": 0,
		"seed": seed,
		"phase": "select",
		"journey": ["select", "setup", "play", "results", "save"],
		"journey_index": 0,
		"rules": rules,
		"mythic_consent": mythic_consent,
		"seats": seated,
		"seat_honesty": seat_truth,
		"partylink_honest_seat_counts": true,
		"feeds_ranked_mmr": false,
		"label": LABEL,
		"everlasting_permitted": bool(everlasting_gate.get("ok", false)),
		"colossus_rigs": [],
		"events": [],
		"result": {},
		"shipping": Authority.shipping_flags_false(),
	}


static func advance_journey(session: Dictionary) -> Dictionary:
	var next: Dictionary = session.duplicate(true)
	var idx: int = int(next.get("journey_index", 0))
	var path: Array = next.get("journey", [])
	if idx >= path.size() - 1:
		next["phase"] = "save"
		return next
	idx += 1
	next["journey_index"] = idx
	next["phase"] = str(path[idx])
	if str(next["phase"]) == "play":
		next["frame"] = 0
		if bool(next["rules"].get("colossus_enabled", false)):
			var Colossus = load("res://scripts/trials/unbound/colossus_rig.gd")
			if Colossus != null:
				next["colossus_rigs"] = Colossus.spawn_for_preset(str(next["rules"].get("preset_id", "")), int(next.get("seed", 1)))
	if str(next["phase"]) == "results":
		next["result"] = {
			"label": LABEL,
			"preset": next["rules"].get("preset_id", ""),
			"feeds_ranked_mmr": false,
			"spectacle_only": true,
		}
	if str(next["phase"]) == "save":
		next["save_payload"] = Authority.empty_save_payload(MODE_ID, int(next.get("seed", 0)), next.get("result", {}))
	return next


static func simulate_play_frames(session: Dictionary, frames: int = 120) -> Dictionary:
	var next: Dictionary = session.duplicate(true)
	if str(next.get("phase", "")) != "play":
		return next
	var kb: float = float(next["rules"].get("knockback_mult", 1.0))
	for i in range(frames):
		next["frame"] = int(next.get("frame", 0)) + 1
		var events: Array = next.get("events", [])
		if int(next["frame"]) % 30 == 0:
			events.append({
				"type": "unbound_pulse",
				"frame": next["frame"],
				"knockback_mult": kb,
				"full_supers": next["rules"].get("full_supers", true),
			})
		next["events"] = events
	return next


static func never_feeds_ranked(session: Dictionary) -> bool:
	return not bool(session.get("feeds_ranked_mmr", true)) and not bool(session.get("rules", {}).get("feeds_ranked_mmr", true))
