extends RefCounted
class_name SmokeBattleScene
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

static func run() -> bool:
	for path in [
		"res://scenes/battle/BattleScene.tscn",
		"res://scenes/menus/MainMenuScene.tscn",
		"res://scenes/ui/ResultsScene.tscn",
	]:
		_SmokeAssert.ok(ResourceLoader.exists(path), "missing %s" % path)
		var packed := load(path) as PackedScene
		_SmokeAssert.ok(packed != null, "failed to load %s" % path)
		var inst := packed.instantiate()
		_SmokeAssert.ok(inst != null, "failed to instantiate %s" % path)
		inst.queue_free()
	return _SmokeAssert.passed()
