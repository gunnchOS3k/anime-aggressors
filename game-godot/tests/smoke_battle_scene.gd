extends RefCounted
class_name SmokeBattleScene

static func run() -> bool:
	for path in [
		"res://scenes/battle/BattleScene.tscn",
		"res://scenes/menus/MainMenuScene.tscn",
		"res://scenes/ui/ResultsScene.tscn",
	]:
		SmokeAssert.ok(ResourceLoader.exists(path), "missing %s" % path)
		var packed := load(path) as PackedScene
		SmokeAssert.ok(packed != null, "failed to load %s" % path)
		var inst := packed.instantiate()
		SmokeAssert.ok(inst != null, "failed to instantiate %s" % path)
		inst.queue_free()
	return SmokeAssert.passed()
