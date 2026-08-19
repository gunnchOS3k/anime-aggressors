extends SceneTree

## Headless: godot --headless --path game-godot --script res://tests/input_persistence_test.gd

const InputPersistence = preload("res://scripts/input/InputPersistenceService.gd")


func _initialize() -> void:
	var failures: PackedStringArray = []
	var defaults := InputPersistence.default_bindings()
	if defaults.is_empty():
		failures.append("default_bindings empty")
	if int(defaults.get("move_left", 0)) != KEY_A:
		failures.append("default move_left not KEY_A")

	var probe := InputPersistence.probe_roundtrip()
	if not probe.get("ok", false):
		failures.append("probe_roundtrip: %s" % JSON.stringify(probe.get("detail", {})))

	if not InputPersistence.set_binding("not_an_action", KEY_Z):
		pass
	else:
		failures.append("invalid action should be rejected")

	if InputPersistence.set_binding("attack", KEY_A):
		failures.append("conflicting binding should be rejected")

	InputPersistence.reset()

	if failures.is_empty():
		print("INPUT_PERSISTENCE_TEST_PASS")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		print("INPUT_PERSISTENCE_TEST_FAIL")
		quit(1)
