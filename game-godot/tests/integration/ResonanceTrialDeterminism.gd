extends SceneTree
## Resonance Trial / Impact Dummy Derby — 10s contract + deterministic replay.

const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")

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
	var a := Derby.create(17, "ember-vale")
	check(int(a.get("round_time_seconds_contract", 0)) == 10, "ten_second_contract")
	check(int(a.get("supersedes_prototype_seconds", 0)) == 45, "supersedes_45s_prototype")
	var inputs: Array = []
	for i in range(60 * 20):
		inputs.append({"right": true, "attack": i % 10 == 0})
	var r1 := Derby.replay(a, inputs)
	var r2 := Derby.replay(Derby.create(17, "ember-vale"), inputs)
	check(Derby.state_hash(r1) == Derby.state_hash(r2), "identical_replay_hash")
	var journey := Derby.run_solo_to_results(19, "kaia-windrow")
	check(str(journey.get("phase", "")) == "results", "journey_reaches_results")
	check(int(journey.get("score", -1)) >= 0, "score_computed")
	check(str(journey.get("grade", "")) != "—", "grade_assigned")
	## Ensure damage phase lasts 10s at 60Hz when not launching early.
	var s := Derby.create(3, "juno-spark")
	var damage_frames := 0
	while str(s.get("phase", "")) != "finalLaunch" and damage_frames < 60 * 20:
		s = Derby.step(s, {})
		if str(s.get("phase", "")) == "damage":
			damage_frames += 1
	check(damage_frames == Derby.DAMAGE_PHASE_FRAMES, "damage_phase_600_frames")
	print("RESONANCE_TRIAL_DETERMINISM ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
