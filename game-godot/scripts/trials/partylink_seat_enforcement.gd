extends RefCounted
class_name TrialsPartyLinkSeats
## Honest PartyLink seat-count enforcement for Trials modes that promise multiplayer.
## Never enables SHIPPING_ROLLBACK. Caps to catalog truth, not aspirational marketing.
## Connected humans only for live PartyLink — never invent seats. 2-fighter BattleScene ≠ 4 humans.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Allocator = preload("res://scripts/net/partylink_variant_allocator.gd")

## Modes that currently accept live PartyLink seating (honest playable seats may be < max).
const PLAYABLE_SEATS := {
	"resonance_trial": {"min": 1, "max": 2, "live_max": 2},
	"fractured_accord": {"min": 2, "max": 4, "live_max": 4},
	"prism_weave": {"min": 2, "max": 10, "live_max": 4},
	"riftline_defense": {"min": 1, "max": 2, "live_max": 2},
	"echoes_gauntlet": {"min": 1, "max": 2, "live_max": 2},
	"convergence_unbound": {"min": 2, "max": 8, "live_max": 4},
}

## Shared BattleScene currently hosts two fighter actors. Extra PartyLink seats are
## lobby/roster truth only until multi-actor depth lands — never fabricate humans.
const BATTLE_SCENE_FIGHTER_SLOTS := 2


static func truth_for(mode_id: String) -> Dictionary:
	var catalog: Dictionary = Authority.player_count_truth(mode_id)
	var live: Dictionary = PLAYABLE_SEATS.get(mode_id, {"min": 1, "max": 2, "live_max": 2})
	return {
		"mode_id": mode_id,
		"catalog_min": int(catalog.get("min", 1)),
		"catalog_max": int(catalog.get("max", 1)),
		"live_min": int(live.get("min", catalog.get("min", 1))),
		"live_max": int(live.get("live_max", live.get("max", 2))),
		"battle_scene_fighter_slots": BATTLE_SCENE_FIGHTER_SLOTS,
		"honest_note": str(catalog.get("honest_note", "")),
		"SHIPPING_ROLLBACK_ENABLED": false,
	}


static func enforce(mode_id: String, requested_seats: int, connected_humans: int = -1) -> Dictionary:
	## Returns ok + seated count. Rejects underfilled multiplayer promises honestly.
	## connected_humans >= 0: live PartyLink — seated never exceeds connected humans.
	## connected_humans < 0: local/sim journey only (CPU fill allowed); not a human PartyLink claim.
	var t: Dictionary = truth_for(mode_id)
	var want: int = requested_seats
	var live_min: int = int(t.live_min)
	var live_max: int = int(t.live_max)
	var catalog_min: int = int(t.catalog_min)
	var catalog_max: int = int(t.catalog_max)
	if want < catalog_min or want > catalog_max:
		return {
			"ok": false,
			"reason": "outside_catalog_range",
			"requested": want,
			"seated": 0,
			"truth": t,
			"SHIPPING_ROLLBACK_ENABLED": false,
			"feeds_ranked_mmr": false,
		}
	var live_partylink: bool = connected_humans >= 0
	var humans: int = connected_humans if live_partylink else want
	var capped_want: int = mini(want, humans) if live_partylink else want
	if catalog_min >= 2 and humans < live_min:
		return {
			"ok": false,
			"reason": "multiplayer_seat_underfill",
			"requested": want,
			"connected_humans": humans if live_partylink else -1,
			"seated": 0,
			"truth": t,
			"note": "Mode promises multiplayer; refusing premature single-seat live session",
			"SHIPPING_ROLLBACK_ENABLED": false,
			"feeds_ranked_mmr": false,
		}
	if live_partylink and capped_want < live_min and catalog_min >= 2:
		return {
			"ok": false,
			"reason": "multiplayer_seat_underfill",
			"requested": want,
			"connected_humans": humans,
			"seated": 0,
			"truth": t,
			"note": "Connected humans below live minimum after honest clamp",
			"SHIPPING_ROLLBACK_ENABLED": false,
			"feeds_ranked_mmr": false,
		}
	## Aspirational catalog max (e.g. Prism 10 / Unbound 8) is not yet live — clamp honestly.
	var seated: int = clampi(capped_want, live_min, live_max)
	if live_partylink:
		seated = mini(seated, humans)
	var degraded: bool = seated < want
	var scene_note := ""
	if seated > BATTLE_SCENE_FIGHTER_SLOTS:
		scene_note = "PartyLink seats=%d exceed 2-fighter BattleScene; extra seats are lobby/roster only until multi-actor depth" % seated
	return {
		"ok": true,
		"reason": "clamped_to_live_max" if degraded else "accepted",
		"requested": want,
		"connected_humans": humans if live_partylink else -1,
		"seated": seated,
		"degraded_from_catalog_max": degraded,
		"live_partylink": live_partylink,
		"battle_scene_fighter_slots": BATTLE_SCENE_FIGHTER_SLOTS,
		"scene_seat_honesty": scene_note,
		"truth": t,
		"partylink_allocator_safe": seated in [2, 4, 6, 8] or seated <= 2,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"feeds_ranked_mmr": false,
	}


static func allocate_variants(mode_id: String, roster_picks: Array) -> Dictionary:
	## PartyLink body_variant allocation only after seat enforcement passes.
	## roster_picks must be connected humans only — size is the connected count.
	var humans: int = roster_picks.size()
	var gate: Dictionary = enforce(mode_id, humans, humans)
	if not bool(gate.get("ok", false)):
		return {"ok": false, "gate": gate, "assigned": []}
	## Only allocate for the honestly seated prefix — never pad invented seats.
	var seated: int = int(gate.get("seated", 0))
	var picks: Array = roster_picks.slice(0, seated) if seated < roster_picks.size() else roster_picks
	var assigned: Array = Allocator.allocate(picks)
	return {
		"ok": true,
		"gate": gate,
		"assigned": assigned,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"feeds_ranked_mmr": false,
	}
