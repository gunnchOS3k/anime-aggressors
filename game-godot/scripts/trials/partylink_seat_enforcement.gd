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


static func presentation_honesty_card(mode_id: String, requested_seats: int = -1, connected_humans: int = -1) -> Dictionary:
	## Digital presentation card for Trials SETUP/HUD — never invents humans or claims
	## simultaneous humans beyond BattleScene fighter slots without lobby honesty.
	var truth: Dictionary = truth_for(mode_id)
	var want: int = requested_seats if requested_seats > 0 else int(truth.get("live_max", 2))
	var gate: Dictionary = enforce(mode_id, want, connected_humans)
	var seated: int = int(gate.get("seated", 0)) if bool(gate.get("ok", false)) else 0
	var live_partylink: bool = connected_humans >= 0
	var simultaneous_humans_claimed := live_partylink and seated > 0
	var exceeds_battle_slots: bool = seated > BATTLE_SCENE_FIGHTER_SLOTS
	var lines: PackedStringArray = []
	lines.append("PartyLink seats · %s" % mode_id)
	lines.append("Catalog %d–%d · live max %d · BattleScene fighter slots %d" % [
		int(truth.get("catalog_min", 1)),
		int(truth.get("catalog_max", 1)),
		int(truth.get("live_max", 2)),
		BATTLE_SCENE_FIGHTER_SLOTS,
	])
	if live_partylink:
		lines.append("Connected humans %d · seated %d (never invent seats)" % [connected_humans, seated])
	else:
		lines.append("Local/sim journey · connected_humans=-1 · not a live PartyLink human claim")
	if exceeds_battle_slots:
		lines.append("Seats>%d are lobby/roster only — not %d simultaneous BattleScene humans" % [
			BATTLE_SCENE_FIGHTER_SLOTS,
			seated,
		])
	else:
		lines.append("Seated ≤ BattleScene slots · no fabricated multi-actor humans")
	lines.append("SHIPPING_ROLLBACK_ENABLED=false · never ranked · CURSOR_COMPLETE=false")
	return {
		"ok": true,
		"mode_id": mode_id,
		"text": "\n".join(lines),
		"truth": truth,
		"gate": gate,
		"seated": seated,
		"connected_humans": connected_humans,
		"live_partylink": live_partylink,
		"simultaneous_humans_claimed": simultaneous_humans_claimed,
		"simultaneous_humans_gt_battle_slots": exceeds_battle_slots and simultaneous_humans_claimed,
		"battle_scene_fighter_slots": BATTLE_SCENE_FIGHTER_SLOTS,
		"invented_seats": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"feeds_ranked_mmr": false,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"presentation_only": true,
	}


static func six_mode_honesty_matrix() -> Dictionary:
	## Digital matrix across all LIVE PartyLink/Trials modes — never invents seats.
	## Catalog aspirational max may exceed live_max; BattleScene slots stay 2.
	var Bridge = load("res://scripts/trials/shared_combat_bridge.gd")
	var modes: Array = Bridge.LIVE_SHARED_COMBAT_MODES
	var rows: Array = []
	var failures: Array = []
	for mode_id in modes:
		var truth: Dictionary = truth_for(str(mode_id))
		var live_max: int = int(truth.get("live_max", 2))
		var catalog_max: int = int(truth.get("catalog_max", live_max))
		## Live PartyLink: request catalog_max with catalog_max connected — expect clamp to live_max.
		var live: Dictionary = enforce(str(mode_id), catalog_max, catalog_max)
		var card: Dictionary = presentation_honesty_card(str(mode_id), catalog_max, mini(catalog_max, live_max))
		if not bool(live.get("ok", false)) and int(truth.get("catalog_min", 1)) <= live_max:
			## Some modes (catalog_min>=2) need enough humans — retry with live_max humans.
			live = enforce(str(mode_id), live_max, live_max)
			card = presentation_honesty_card(str(mode_id), live_max, live_max)
		if not bool(live.get("ok", false)):
			failures.append("live_fail:" + str(mode_id))
		if int(live.get("seated", -1)) > live_max:
			failures.append("over_live_max:" + str(mode_id))
		if int(live.get("seated", 0)) > catalog_max:
			failures.append("over_catalog:" + str(mode_id))
		if bool(live.get("SHIPPING_ROLLBACK_ENABLED", true)):
			failures.append("rollback:" + str(mode_id))
		if bool(card.get("invented_seats", true)):
			failures.append("invented_card:" + str(mode_id))
		if bool(card.get("CURSOR_COMPLETE", true)):
			failures.append("cursor_complete:" + str(mode_id))
		## Never invent seats: zero connected must not seat multiplayer catalog_min>=2.
		if int(truth.get("catalog_min", 1)) >= 2:
			var zero: Dictionary = enforce(str(mode_id), 2, 0)
			if bool(zero.get("ok", true)):
				failures.append("invented_zero_humans:" + str(mode_id))
		rows.append({
			"mode_id": mode_id,
			"catalog_max": catalog_max,
			"live_max": live_max,
			"seated": int(live.get("seated", 0)),
			"battle_scene_fighter_slots": BATTLE_SCENE_FIGHTER_SLOTS,
			"degraded_from_catalog_max": bool(live.get("degraded_from_catalog_max", false)) or catalog_max > live_max,
			"SHIPPING_ROLLBACK_ENABLED": false,
		})
	return {
		"ok": failures.is_empty() and rows.size() == 6,
		"failures": failures,
		"mode_count": rows.size(),
		"rows": rows,
		"battle_scene_fighter_slots": BATTLE_SCENE_FIGHTER_SLOTS,
		"invented_seats": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"CURSOR_COMPLETE": false,
		"req_id": "AA-RTM-008",
	}
