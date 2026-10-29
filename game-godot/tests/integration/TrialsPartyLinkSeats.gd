extends SceneTree
## PartyLink honest seat-count enforcement for Trials multiplayer promises.

const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")

var failures: Array = []
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	var prism: Dictionary = Seats.enforce("prism_weave", 10, 10)
	check(bool(prism.get("ok", false)), "prism_10_ok_clamped")
	check(int(prism.get("seated", 0)) == 4, "prism_live_max_4")
	check(bool(prism.get("degraded_from_catalog_max", false)), "prism_degraded_honest")

	var unbound8: Dictionary = Seats.enforce("convergence_unbound", 8, 8)
	check(bool(unbound8.get("ok", false)), "unbound_8_ok_clamped")
	check(int(unbound8.get("seated", 0)) == 4, "unbound_live_max_4")

	var under: Dictionary = Seats.enforce("fractured_accord", 2, 1)
	check(not bool(under.get("ok", true)), "flagline_underfill_reject")
	check(str(under.get("reason", "")) == "multiplayer_seat_underfill", "underfill_reason")
	check(not bool(under.get("SHIPPING_ROLLBACK_ENABLED", true)), "no_rollback_on_reject")

	var oob: Dictionary = Seats.enforce("riftline_defense", 5, 5)
	check(not bool(oob.get("ok", true)), "rift_oob_reject")

	var solo: Dictionary = Seats.enforce("resonance_trial", 1, 1)
	check(bool(solo.get("ok", false)), "derby_solo_ok")
	check(int(solo.get("seated", 0)) == 1, "derby_solo_seated")

	var alloc: Dictionary = Seats.allocate_variants("fractured_accord", [
		{"seat_id": 1, "fighter_id": "ember-vale", "team_id": 0},
		{"seat_id": 2, "fighter_id": "rook-ironside", "team_id": 1},
		{"seat_id": 3, "fighter_id": "juno-spark", "team_id": 0},
		{"seat_id": 4, "fighter_id": "kaia-windrow", "team_id": 1},
	])
	check(bool(alloc.get("ok", false)), "allocator_ok")
	check((alloc.get("assigned", []) as Array).size() == 4, "four_variants")
	check(not bool(alloc.get("SHIPPING_ROLLBACK_ENABLED", true)), "alloc_no_rollback")
	check(not bool(alloc.get("feeds_ranked_mmr", true)), "alloc_no_mmr")

	print("TRIALS_PARTYLINK_SEATS ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
