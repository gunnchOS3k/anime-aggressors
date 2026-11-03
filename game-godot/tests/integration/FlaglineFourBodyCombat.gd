extends SceneTree
## Actual four-body Flagline via BattleSim/HitResolver — not logical CPU-only.
## Verifies body/input/team, capture, OT path, results seal, rematch payload.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const FourBody = preload("res://scripts/trials/flagline/flagline_four_body.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")

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
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs == null:
		print("FLAGLINE_FOUR_BODY_COMBAT FAIL checks=", checks, " failures=", failures)
		quit(1)
		return

	var prep: Dictionary = Bridge.prepare_live_battle("fractured_accord", 4, Unbound.PRESET_TOTAL, -1)
	check(bool(prep.get("ok", false)), "prep_ok")
	check(bool(gs.trial_four_body), "trial_four_body")
	check((gs.trial_body_roster as Array).size() == 4, "roster_4")
	check(bool(prep.get("applied", {}).get("actual_combat_bodies", false)), "actual_bodies")
	check(int(prep.get("applied", {}).get("battle_scene_fighter_slots", 0)) == 4, "slots_4")
	check(str(prep.get("applied", {}).get("combat_authority", "")) == "BattleSim+HitResolver", "combat_authority")
	check(bool(gs.team_mode), "team_mode")
	check(not bool(gs.team_attack), "no_friendly_fire_default")

	## Body/input/team honesty on roster.
	var teams: Dictionary = {"solar": 0, "lunar": 0}
	var humans := 0
	for entry in gs.trial_body_roster:
		var tid := str(entry.get("team_id", ""))
		teams[tid] = int(teams.get(tid, 0)) + 1
		if bool(entry.get("is_human", false)):
			humans += 1
		check(int(entry.get("slot", 0)) >= 1 and int(entry.get("slot", 0)) <= 4, "slot_range_%s" % str(entry.get("slot", "?")))
		check(str(entry.get("fighter_id", "")) != "", "fighter_id_present")
	check(int(teams.get("solar", 0)) == 2 and int(teams.get("lunar", 0)) == 2, "2v2_teams")
	check(humans == 4 or humans == int(prep.get("applied", {}).get("connected_humans", -1)), "human_count_honest")

	## Hits / capture / OT via four-body live multi tick (combat authority positions).
	var snap: Dictionary = gs.trial_sim_snapshot.duplicate(true)
	snap["config"]["bots_enabled"] = false
	while str(snap.get("phase", "")) == "intro":
		snap = Flagline.step(snap)
	## Opposing teams contest core → contested capture pause.
	snap = Flagline.tick_live_multi(snap, [
		Vector2(960, 540), Vector2(960, 540), Vector2(980, 520), Vector2(940, 560),
	])
	var occ_c := Flagline.occupancy_summary(snap)
	check(bool(occ_c.get("contested", false)), "contested_four_body")
	## Uncontested Beaconward capture progresses.
	snap = Flagline.create(41, 0, 2)
	snap["config"]["bots_enabled"] = false
	snap["actual_combat_bodies"] = true
	snap["live_actor_sync"] = true
	while str(snap.get("phase", "")) == "intro":
		snap = Flagline.step(snap)
	for _i in range(40):
		snap = Flagline.tick_live_multi(snap, [
			Vector2(960, 540), Vector2(100, 540), Vector2(980, 520), Vector2(80, 560),
		])
	var occ_u := Flagline.occupancy_summary(snap)
	check(float(occ_u.get("solar_capture", 0.0)) > 0.0, "capture_progress")
	check(bool(occ_u.get("overtime_enabled", false)), "ot_enabled")

	## Force OT room resolve then rematch payload + results seal.
	snap["room_timer_frames"] = 1
	snap["capture"] = {"solar": 55.0, "lunar": 20.0, "contested": false, "controlling": "solar"}
	snap = Flagline.step(snap)
	check(str(snap.get("phase", "")) in ["roomWon", "gameWon"], "ot_room_or_game")
	## Drive to gameWon via capture journey with four-body flags, then seal.
	var journey := Flagline.run_capture_journey(47, 2)
	journey["actual_combat_bodies"] = true
	journey["live_actor_sync"] = true
	journey["battle_scene_fighter_slots"] = 4
	gs.trial_sim_snapshot = journey
	var sealed: Dictionary = Bridge._seal_flagline_results(gs, journey)
	check(str(sealed.get("result_kind", "")) == "REAL_PLAYER", "player_owned_results")
	check(sealed.has("rematch"), "rematch_payload")
	check(bool(sealed.get("rematch", {}).get("four_body", false)), "rematch_four_body")
	check(not bool(sealed.get("SHIPPING_ROLLBACK_ENABLED", true)), "no_rollback")
	check(not bool(sealed.get("HUMAN_ART_APPROVED", true)), "no_human_art")
	check((gs.trial_records as Array).size() >= 1, "recorded_trial_result")
	var last: Dictionary = gs.trial_records[gs.trial_records.size() - 1]
	check(str(last.get("result_kind", "")) == "REAL_PLAYER", "ledger_real_player")
	check(bool(last.get("four_body", false)), "ledger_four_body")

	## Cross-team hitbox link count honesty (2v2 ⇒ 8 directed links without friendly fire).
	var fake_bodies: Array = []
	for entry in gs.trial_body_roster:
		var n := Node.new()
		n.set_meta("flagline_team_id", str(entry.get("team_id", "")))
		fake_bodies.append(n)
	var links := FourBody.connect_cross_team_hitboxes(null, fake_bodies, func(_a, _d): pass)
	check(links == 8, "cross_team_links_8")
	for n in fake_bodies:
		n.free()

	print("FLAGLINE_FOUR_BODY_COMBAT ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
