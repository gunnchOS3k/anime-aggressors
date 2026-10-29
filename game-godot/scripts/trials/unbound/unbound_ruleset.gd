extends RefCounted
class_name UnboundRuleset
## Convergence Unbound — intentionally unbalanced Mythic/Mayhem-inspired ORIGINAL ruleset.
## Label: UNBALANCED MYTHIC. Never feeds ranked MMR. Opt-in spectacle only.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Eligibility = preload("res://scripts/trials/rosamere_trials_eligibility.gd")
const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")

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
			m["prismatic_actors"] = ["spectrum_ember", "spectrum_juno", "spectrum_kaia", "spectrum_nix", "spectrum_orion", "spectrum_vesper", "spectrum_rook"]
			m["projectile_mult"] = 2.0
			m["note"] = "Prismatic unique per spectrum fighter — original kits, not third-party copies"
		PRESET_COLOSSUS:
			m["name"] = "Colossus Clash"
			m["colossus_enabled"] = true
			m["colossus_actors"] = ["cosmic_colossus_yin", "cosmic_colossus_yang"]
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
			m["puppet_actors"] = ["puppet_echo_black", "puppet_echo_white"]
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
	## Local/sim session: connected_humans=-1. Live PartyLink callers pass real humans.
	var seat_gate: Dictionary = Seats.enforce(MODE_ID, seats, -1)
	var seat_truth: Dictionary = Seats.truth_for(MODE_ID)
	var seated: int = int(seat_gate.get("seated", 0))
	if not bool(seat_gate.get("ok", false)):
		## Still form a session for journey/sim, but mark PartyLink live as blocked.
		seated = clampi(seats, int(seat_truth.get("live_min", 2)), int(seat_truth.get("live_max", 4)))
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
		"seat_gate": seat_gate,
		"partylink_honest_seat_counts": true,
		"partylink_live_ok": bool(seat_gate.get("ok", false)),
		"feeds_ranked_mmr": false,
		"label": LABEL,
		"everlasting_permitted": bool(everlasting_gate.get("ok", false)),
		"colossus_rigs": [],
		"events": [],
		"result": {},
		"SHIPPING_ROLLBACK_ENABLED": false,
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


static func controllable_actors_for(preset_id: String) -> Array:
	## Controllable Mythic actors for live Unbound — never Versus/Story/ranked roster claims.
	var rules: Dictionary = preset(preset_id)
	var actors: Array = []
	match str(rules.get("preset_id", preset_id)):
		PRESET_PRISMATIC:
			for aid in rules.get("prismatic_actors", []):
				actors.append({
					"actor_id": aid,
					"kind": "prismatic_spectrum",
					"controllable": true,
					"trials_only": true,
					"contaminates_versus": false,
					"contaminates_story": false,
					"feeds_ranked_mmr": false,
				})
		PRESET_COLOSSUS:
			for aid in rules.get("controllable_avatars", []):
				actors.append({
					"actor_id": aid,
					"kind": "colossus_avatar",
					"controllable": true,
					"trials_only": true,
					"avatar_ko_is_true_defeat": false,
					"contaminates_versus": false,
					"contaminates_story": false,
					"feeds_ranked_mmr": false,
				})
		PRESET_KAIJU:
			for aid in rules.get("puppet_actors", []):
				actors.append({
					"actor_id": aid,
					"kind": "puppet_echo",
					"controllable": true,
					"trials_only": true,
					"is_yin_yang_rosamere_puppet": false,
					"contaminates_versus": false,
					"contaminates_story": false,
					"feeds_ranked_mmr": false,
				})
		_:
			actors.append({
				"actor_id": "unbound_fighter_slot",
				"kind": "unbound_ruleset_fighter",
				"controllable": true,
				"full_supers": true,
				"trials_only": true,
				"contaminates_versus": false,
				"contaminates_story": false,
				"feeds_ranked_mmr": false,
			})
	return actors


static func runtime_modifiers(preset_id: String) -> Dictionary:
	## Applied to GameState during live Unbound only; cleared by end_trial / Versus entry.
	var rules: Dictionary = preset(preset_id)
	return {
		"full_supers": bool(rules.get("full_supers", true)),
		"cooldown_mult": float(rules.get("cooldown_mult", 0.15)),
		"instant_resources": bool(rules.get("instant_resources", true)),
		"respawn_frames": int(rules.get("respawn_frames", 30)),
		"rapid_respawn": bool(rules.get("rapid_respawn", true)),
		"knockback_mult": float(rules.get("knockback_mult", 1.85)),
		"damage_mult": float(rules.get("damage_mult", 1.35)),
		"transform_duration_mult": float(rules.get("transform_duration_mult", 2.5)),
		"controllable_actors": controllable_actors_for(preset_id),
		"feeds_ranked_mmr": false,
		"contaminates_versus": false,
		"contaminates_story": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}
