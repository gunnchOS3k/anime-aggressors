extends SceneTree

## Headless smoke runner — `godot --path game-godot --headless -s res://tests/smoke_runner.gd`

func _init() -> void:
	call_deferred("_run_all")

func _suites() -> Array:
	var ReleaseMode = preload("res://tests/smoke_release_mode.gd")
	return [
		["boot", SmokeBoot],
		["release_mode", ReleaseMode],
		["data_load", SmokeDataLoad],
		["fighter_scene", SmokeFighterScene],
		["training_scene", SmokeTrainingScene],
		["battle_scene", SmokeBattleScene],
	]

func _run_all() -> void:
	var failed := 0
	for entry in _suites():
		var name: String = entry[0]
		var suite = entry[1]
		SmokeAssert.reset()
		print("[smoke] running %s" % name)
		if not suite.run():
			failed += 1
			print("[smoke] FAIL %s:\n%s" % [name, SmokeAssert.summary()])
		else:
			print("[smoke] OK %s" % name)
	if failed > 0:
		push_error("smoke_runner: %d suite(s) failed" % failed)
		quit(1)
	else:
		print("[smoke] all suites passed")
		quit(0)
