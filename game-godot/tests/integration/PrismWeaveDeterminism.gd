extends SceneTree
## Prism Weave — 60s territorial; markers beyond color; deterministic.

const Prism = preload("res://scripts/trials/prism/prism_weave_sim.gd")

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
	var a := Prism.create(5, 4)
	var b := Prism.create(5, 4)
	for i in range(180):
		a = Prism.step(a)
		b = Prism.step(b)
	check(Prism.state_hash(a) == Prism.state_hash(b), "deterministic")
	check(bool(a.get("accessibility", {}).get("markers_beyond_color", false)), "a11y_markers")
	check(int(a.get("max_fighters", 0)) == 10, "ten_fighter_cap")
	check((a.get("harmonic_tiles", []) as Array).size() == 6, "bounded_harmonics")
	## Full match would be 3600 frames; smoke shorter path to results via timer drain.
	var short := Prism.create(8, 2)
	short["timer_frames"] = 5
	for i in range(10):
		short = Prism.step(short)
	check(str(short.get("phase", "")) == "results", "results_on_timer")
	print("PRISM_WEAVE_DETERMINISM ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
