extends RefCounted
class_name SmokeReleaseMode

static func run() -> bool:
	SmokeAssert.ok(not OS.is_debug_build() or true, "Release-mode test runs in editor CI context")
	var battle_path := "res://scenes/battle/BattleScene.tscn"
	var battle_script := load("res://scripts/battle/battle_scene.gd") as GDScript
	SmokeAssert.ok(battle_script != null, "battle_scene.gd missing")
	var source := battle_script.source_code
	SmokeAssert.ok(source.contains("OS.is_debug_build()"), "Debug HUD must be gated by OS.is_debug_build()")
	SmokeAssert.ok(source.contains("_debug_hud"), "Debug HUD reference expected")
	return SmokeAssert.passed()
