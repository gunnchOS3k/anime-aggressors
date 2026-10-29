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
	print("RIFTLINE_SEEDED_WAVES ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
