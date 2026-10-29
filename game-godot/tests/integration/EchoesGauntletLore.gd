extends SceneTree
## Echoes of Convergence — simulations; no canonical cosmic defeat.

const Echoes = preload("res://scripts/trials/echoes/echoes_gauntlet_sim.gd")

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
	var s := Echoes.create(5, false)
	check(not bool(s.get("lore", {}).get("echoes_are_real_puppets", true)), "not_puppets")
	check(not bool(s.get("lore", {}).get("echoes_are_souls", true)), "not_souls")
	check(bool(s.get("lore", {}).get("bosses_are_simulations", false)), "bosses_sims")
	check(bool(s.get("lore", {}).get("kaia_philosophical_victory_preserved", false)), "kaia_preserved")
	check(bool(s.get("lore", {}).get("yin_not_evil", false)), "yin_nuance")
	check(bool(s.get("lore", {}).get("yang_not_simple_good", false)), "yang_nuance")
	var cleared := Echoes.run_clear_smoke(5, false)
	check(str(cleared.get("phase", "")) in ["cleared", "defeated"], "terminal_phase")
	check(not bool(cleared.get("canonical_cosmic_defeat", true)), "no_canonical_cosmic_defeat")
	var coop := Echoes.create(6, true)
	check((coop.get("players", []) as Array).size() == 2, "coop_seats")
	print("ECHOES_GAUNTLET_LORE ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
