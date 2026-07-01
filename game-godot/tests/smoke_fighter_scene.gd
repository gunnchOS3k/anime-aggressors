extends RefCounted
class_name SmokeFighterScene

static func run() -> bool:
	var path := "res://scenes/fighters/Fighter.tscn"
	SmokeAssert.ok(ResourceLoader.exists(path), "Fighter.tscn missing")
	var packed := load(path) as PackedScene
	SmokeAssert.ok(packed != null, "Fighter.tscn failed to load")
	var fighter := packed.instantiate()
	SmokeAssert.ok(fighter != null, "Fighter.tscn failed to instantiate")
	for node_name in ["Body", "Hitbox", "Hurtbox", "HitboxDebug", "HurtboxDebug", "AuraVfx"]:
		SmokeAssert.ok(fighter.get_node_or_null(node_name) != null, "Fighter missing node %s" % node_name)
	SmokeAssert.ok(fighter is AAFighter, "Fighter root must be AAFighter")
	fighter.queue_free()
	return SmokeAssert.passed()
