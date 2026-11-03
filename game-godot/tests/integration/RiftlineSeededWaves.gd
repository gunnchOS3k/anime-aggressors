extends SceneTree
## Riftline Defense — seeded waves; fighter-identity projectiles; Fracture Echoes lore.

const Riftline = preload("res://scripts/trials/riftline/riftline_defense_sim.gd")

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
	var a := Riftline.run_seeded_smoke(11)
	var b := Riftline.run_seeded_smoke(11)
	check(Riftline.state_hash(a) == Riftline.state_hash(b), "seeded_determinism")
	check(bool(a.get("lore", {}).get("fracture_echoes", false)), "fracture_echoes_lore")
	check(not bool(a.get("lore", {}).get("enslaved_fighters", true)), "not_enslaved")
	var s := Riftline.create(4, "vesper-nyx", 1)
	check(str(s["players"][0].get("projectile_id", "")) == "veil_dart", "fighter_identity_projectile")
	for echo in a.get("echoes", []):
		check(not bool(echo.get("is_real_puppet", true)), "echo_not_real_puppet")
	## Live deepen: attack-driven fire + player-owned echo hit path.
	var live := Riftline.create(7, "ember-vale", 2)
	for _i in range(70):
		live = Riftline.tick_live_from_battle(live, Vector2(400, 200), Vector2(400, 560), true, true, true)
	check(bool(live.get("live_shared_combat", false)), "rift_live_flag")
	check(bool(live.get("real_attacks", false)), "rift_real_attacks")
	if (live.get("echoes", []) as Array).size() > 0:
		var lane: int = int(live["echoes"][0].get("lane", 0))
		var before: int = (live.get("echoes", []) as Array).size()
		live = Riftline.notify_echo_hit(live, lane, 100)
		check((live.get("echoes", []) as Array).size() == before - 1, "player_owned_echo_hit")
	var hud := Riftline.live_hud(live)
	check(not bool(hud.get("enslaved_fighters", true)), "hud_not_enslaved")
	print("RIFTLINE_SEEDED_WAVES ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
