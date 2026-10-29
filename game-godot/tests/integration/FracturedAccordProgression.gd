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
	print("FRACTURED_ACCORD_PROGRESSION ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
