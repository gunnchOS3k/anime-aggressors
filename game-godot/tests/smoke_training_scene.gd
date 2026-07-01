extends RefCounted
class_name SmokeTrainingScene

static func run() -> bool:
	for path in [
		"res://scenes/training/TrainingMenuScene.tscn",
		"res://scenes/training/TrainingBattleScene.tscn",
	]:
		SmokeAssert.ok(ResourceLoader.exists(path), "missing %s" % path)
		var packed := load(path) as PackedScene
		SmokeAssert.ok(packed != null, "failed to load %s" % path)
		var inst := packed.instantiate()
		SmokeAssert.ok(inst != null, "failed to instantiate %s" % path)
		inst.queue_free()
	var hud_path := "res://scenes/ui/DebugHud.tscn"
	var hud_packed := load(hud_path) as PackedScene
	SmokeAssert.ok(hud_packed != null, "DebugHud.tscn failed to load")
	var hud := hud_packed.instantiate()
	SmokeAssert.ok(hud is DebugHud, "DebugHud root type mismatch")
	hud.queue_free()
	return SmokeAssert.passed()
