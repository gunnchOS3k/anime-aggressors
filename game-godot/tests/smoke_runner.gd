extends SceneTree

## Headless smoke runner — `godot --path game-godot --headless -s res://tests/smoke_runner.gd`
## Always quits (never hang on suite errors). Prefer class_name suites under Godot 4.5 `-s`.


func _init() -> void:
	call_deferred("_run_all")


func _suites() -> Array:
	# Preload all suites: Godot 4.5 --script runs before global class_name registration.
	return [
		["boot", preload("res://tests/smoke_boot.gd")],
		["release_mode", preload("res://tests/smoke_release_mode.gd")],
		["data_load", preload("res://tests/smoke_data_load.gd")],
		["combat_depth", preload("res://tests/smoke_combat_depth.gd")],
		["device_a11y_telemetry", preload("res://tests/smoke_device_a11y_telemetry.gd")],
		["fighter_scene", preload("res://tests/smoke_fighter_scene.gd")],
		["training_scene", preload("res://tests/smoke_training_scene.gd")],
		["battle_scene", preload("res://tests/smoke_battle_scene.gd")],
		["match_loop", preload("res://tests/smoke_match_loop.gd")],
	]


func _invoke(suite: GDScript) -> bool:
	# class_name scripts expose static run() on the Script resource under -s.
	if suite == null:
		push_error("smoke suite failed to load")
		return false
	if suite.has_method("run"):
		return bool(suite.call("run"))
	# Fallback: instantiate (covers non-static / broken static exposure).
	var inst = suite.new()
	if inst != null and inst.has_method("run"):
		return bool(inst.call("run"))
	push_error("smoke suite missing run()")
	return false


func _run_all() -> void:
	var Assert = preload("res://tests/smoke_assert.gd")
	var failed := 0
	for entry in _suites():
		var name: String = entry[0]
		var suite: GDScript = entry[1]
		Assert.reset()
		print("[smoke] running %s" % name)
		var ok := false
		# Isolate suite failures so later suites still run and we always quit.
		ok = _invoke(suite)
		if not ok:
			failed += 1
			print("[smoke] FAIL %s:\n%s" % [name, Assert.summary()])
		else:
			print("[smoke] OK %s" % name)
	if failed > 0:
		push_error("smoke_runner: %d suite(s) failed" % failed)
		quit(1)
	else:
		print("[smoke] all suites passed")
		quit(0)
