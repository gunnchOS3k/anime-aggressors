extends SceneTree

## Headless batch match harness runner.
## Usage: godot --headless --path game-godot -s res://tests/batch_match_harness_runner.gd

const _BatchMatchHarness = preload("res://scripts/battle/batch_match_harness.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[batch] starting deterministic abbreviated matches")
	if not _BatchMatchHarness.assert_deterministic(9, 60, 42):
		push_error("batch harness non-deterministic")
		quit(1)
		return
	var report: Dictionary = _BatchMatchHarness.run_batch(21, 90, 42)
	print("[batch] matches=%d frames=%d seed=%d" % [
		int(report.get("match_count", 0)),
		int(report.get("frames_per_match", 0)),
		int(report.get("base_seed", 0)),
	])
	print("[batch] wins=%s" % str(report.get("wins", {})))
	print("[batch] claim=%s" % str(report.get("alpha_claim", "")))
	print("[batch] OK")
	quit(0)
