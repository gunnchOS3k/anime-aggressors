extends SceneTree

## Headless batch match harness runner.
## Usage: godot --headless --path game-godot -s res://tests/batch_match_harness_runner.gd
## Writes 7×7×tiers evidence JSON under res://../playtest-evidence/ and user://.

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

	print("[batch] running full 7x7 matrix @ tiers 1,3,5")
	var matrix: Dictionary = _BatchMatchHarness.run_full_matrix([1, 3, 5], 72, 42)
	print("[batch] matrix_matches=%d deadlock_rate=%.3f diversity=%s" % [
		int(matrix.get("match_count", 0)),
		float(matrix.get("deadlock_rate", 0.0)),
		str(matrix.get("diversity", {})),
	])
	if int(matrix.get("match_count", 0)) < 7 * 7 * 3:
		push_error("matrix undersized")
		quit(1)
		return
	# Evidence paths: user:// + project-relative playtest-evidence.
	var user_path := _BatchMatchHarness.write_evidence_json(matrix, "user://cpu_batch_matrix.json")
	var evidence_dir := ProjectSettings.globalize_path("res://").path_join("../playtest-evidence")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var abs_path := evidence_dir.path_join("cpu_batch_matrix.json")
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(matrix, "\t"))
		f.close()
		print("[batch] evidence=%s" % abs_path)
	else:
		print("[batch] evidence_user=%s" % user_path)
	print("[batch] OK")
	quit(0)
