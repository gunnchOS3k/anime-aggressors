extends RefCounted
class_name SmokeMatchLoop
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

## Route-graph + critical scene load acceptance for the authoritative Godot match loop.
## Avoids compile-time GameState/SceneRouter identifiers so -s runner can load this suite.

static func run() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		_SmokeAssert.ok(false, "no SceneTree")
		return _SmokeAssert.passed()
	var sr = tree.root.get_node_or_null("SceneRouter")
	var gs = tree.root.get_node_or_null("GameState")
	_SmokeAssert.ok(sr != null, "SceneRouter autoload missing")
	_SmokeAssert.ok(gs != null, "GameState autoload missing")
	if sr == null:
		return _SmokeAssert.passed()

	var scenes: Dictionary = sr.SCENES
	for key in [
		"boot", "main_menu", "mode_select", "ruleset", "fighter_select",
		"stage_select", "versus", "battle", "results", "training", "settings",
	]:
		_SmokeAssert.ok(scenes.has(key), "missing route %s" % key)
		if scenes.has(key):
			var path: String = scenes[key]
			_SmokeAssert.ok(ResourceLoader.exists(path), "missing scene %s" % path)
			var packed := load(path) as PackedScene
			_SmokeAssert.ok(packed != null, "failed load %s" % path)
			var inst := packed.instantiate()
			_SmokeAssert.ok(inst != null, "failed instantiate %s" % path)
			inst.queue_free()

	if gs != null:
		var roster: Array = gs.roster_ids()
		_SmokeAssert.ok(roster.size() == 7, "expected 7 fighters, got %d" % roster.size())
		var stages: Array = gs.production_stage_ids()
		_SmokeAssert.ok(stages.size() > 0, "no production stages")
	return _SmokeAssert.passed()
