extends RefCounted
class_name SmokeFighterScene
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

static func run() -> bool:
	var path := "res://scenes/fighters/Fighter.tscn"
	_SmokeAssert.ok(ResourceLoader.exists(path), "Fighter.tscn missing")
	var packed := load(path) as PackedScene
	_SmokeAssert.ok(packed != null, "Fighter.tscn failed to load")
	var fighter := packed.instantiate()
	_SmokeAssert.ok(fighter != null, "Fighter.tscn failed to instantiate")
	for node_name in ["Body", "Hitbox", "Hurtbox", "HitboxDebug", "HurtboxDebug", "AuraVfx"]:
		_SmokeAssert.ok(fighter.get_node_or_null(node_name) != null, "Fighter missing node %s" % node_name)
	_SmokeAssert.ok(fighter.get_script() != null and str(fighter.get_script().resource_path).ends_with("fighter.gd"), "Fighter root must use fighter.gd")
	fighter.queue_free()
	return _SmokeAssert.passed()
