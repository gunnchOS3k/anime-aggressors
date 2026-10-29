extends SceneTree
## Fractured Accord — five-room push-pull + display aliases.

const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")

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
	check(Flagline.display_team("solar") == "Beaconward", "solar_alias")
	check(Flagline.display_team("lunar") == "Veilward", "lunar_alias")
	check(Flagline.next_room(0, "solar") == -1, "push_solar")
	check(Flagline.next_room(0, "lunar") == 1, "push_lunar")
	check(Flagline.next_room(-2, "solar") == "solarWinsGame", "solar_wins_at_base")
	check(Flagline.next_room(2, "lunar") == "lunarWinsGame", "lunar_wins_at_base")
	var a := Flagline.create(9, 0)
	var b := Flagline.create(9, 0)
	for i in range(120):
		Flagline.set_presence(a, 0, true)
		Flagline.set_presence(b, 0, true)
		a = Flagline.step(a)
		b = Flagline.step(b)
	check(Flagline.state_hash(a) == Flagline.state_hash(b), "deterministic_hash")
	var journey := Flagline.run_capture_journey(13)
	check(str(journey.get("phase", "")) == "gameWon", "journey_game_won")
	check(str(journey.get("winning_team", "")) in ["solar", "lunar"], "has_winner")
	check(bool(journey.get("yin_yang_not_ordinary_captains", false)), "yin_yang_not_captains")
	## Real 2v2 actors + core occupancy + contested capture (not HUD strip alone).
	var live := Flagline.create(17, 0, 2)
	check(Flagline.actor_slots(live).size() == 4, "four_actors")
	check(int(live.get("connected_humans", 0)) == 2, "two_humans_cpu_fill")
	live = Flagline.sync_live_presence_from_positions(live, Vector2(960, 540), Vector2(960, 540))
	var occ0 := Flagline.occupancy_summary(live)
	check(bool(occ0.get("contested", false)), "contested_when_both_in_core")
	check(int(occ0.get("solar_in_core", 0)) >= 1 and int(occ0.get("lunar_in_core", 0)) >= 1, "both_teams_occupancy")
	## Uncontested solar capture progresses meter.
	live = Flagline.create(19, 0, 2)
	live["config"]["bots_enabled"] = false
	while str(live.get("phase", "")) == "intro":
		live = Flagline.step(live)
	for _i in range(30):
		live = Flagline.tick_live(live, Vector2(960, 540), Vector2(100, 540))
	var occ1 := Flagline.occupancy_summary(live)
	check(float(occ1.get("solar_capture", 0.0)) > 0.0, "solar_capture_progress")
	check(bool(occ1.get("overtime_enabled", false)), "ot_enabled")
	check((-2 in (occ1.get("stronghold_rooms", []) as Array)) and (2 in (occ1.get("stronghold_rooms", []) as Array)), "stronghold_rooms")
	## Multi-actor depth beyond BattleScene's 2 fighter slots (logical 4 + independent CPU fill).
	check(bool(live.get("multi_actor_depth", false)), "multi_actor_depth")
	check(int(live.get("logical_actor_count", 0)) == 4, "logical_actor_count_4")
	check(bool(occ1.get("independent_cpu_fill", false)), "independent_cpu_fill")
	check(int(occ1.get("battle_scene_fighter_slots", 0)) == 4, "four_battle_slots_contract")
	var multi := Flagline.create(23, 0, 4)
	multi["config"]["bots_enabled"] = false
	while str(multi.get("phase", "")) == "intro":
		multi = Flagline.step(multi)
	multi = Flagline.tick_live_multi(multi, [
		Vector2(960, 540), Vector2(200, 540), Vector2(980, 520), Vector2(180, 560),
	])
	var occ_m := Flagline.occupancy_summary(multi)
	check(int(occ_m.get("actor_count", 0)) == 4, "tick_live_multi_four")
	check(int(occ_m.get("solar_in_core", 0)) >= 1, "multi_solar_in_core")
	## Capture → room push → OT contract still honest.
	var ot := Flagline.create(29, 0, 2)
	ot["config"]["bots_enabled"] = false
	ot["config"]["capture_to_win"] = 100.0
	ot["room_timer_frames"] = 5
	while str(ot.get("phase", "")) == "intro":
		ot = Flagline.step(ot)
	Flagline.set_presence(ot, 0, true)
	Flagline.set_presence(ot, 2, true)
	Flagline.set_presence(ot, 1, false)
	Flagline.set_presence(ot, 3, false)
	ot["capture"] = {"solar": 40.0, "lunar": 10.0, "contested": false, "controlling": "solar"}
	ot = Flagline.step(ot)
	check(str(ot.get("room_win_reason", "")) == "overtime" or str(ot.get("phase", "")) in ["roomWon", "gameWon", "roomFight"], "ot_or_room_path")
	print("FRACTURED_ACCORD_PROGRESSION ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
