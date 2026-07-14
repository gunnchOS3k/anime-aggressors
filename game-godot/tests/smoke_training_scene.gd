extends RefCounted
class_name SmokeTrainingScene
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

static func run() -> bool:
	for path in [
		"res://scenes/training/TrainingMenuScene.tscn",
		"res://scenes/training/TrainingBattleScene.tscn",
	]:
		_SmokeAssert.ok(ResourceLoader.exists(path), "missing %s" % path)
		var packed := load(path) as PackedScene
		_SmokeAssert.ok(packed != null, "failed to load %s" % path)
		var inst := packed.instantiate()
		_SmokeAssert.ok(inst != null, "failed to instantiate %s" % path)
		inst.queue_free()
	var hud_path := "res://scenes/ui/DebugHud.tscn"
	var hud_packed := load(hud_path) as PackedScene
	_SmokeAssert.ok(hud_packed != null, "DebugHud.tscn failed to load")
	var hud := hud_packed.instantiate()
	_SmokeAssert.ok(hud.get_script() != null and str(hud.get_script().resource_path).ends_with("debug_hud.gd"), "DebugHud root type mismatch")
	hud.queue_free()
	return _SmokeAssert.passed()
