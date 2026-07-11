extends RefCounted
class_name SmokeBoot

static func run() -> bool:
	SmokeAssert.ok(Engine.has_singleton("GameState") == false, "GameState should be autoload node, not Engine singleton")
	var tree := Engine.get_main_loop() as SceneTree
	SmokeAssert.ok(tree != null, "SceneTree missing")
	var gs := tree.root.get_node_or_null("/root/GameState")
	var sr := tree.root.get_node_or_null("/root/SceneRouter")
	SmokeAssert.ok(gs != null, "GameState autoload missing")
	SmokeAssert.ok(sr != null, "SceneRouter autoload missing")
	var boot_path := "res://scenes/boot/BootScene.tscn"
	SmokeAssert.ok(ResourceLoader.exists(boot_path), "BootScene.tscn missing")
	var boot_res := load(boot_path) as PackedScene
	SmokeAssert.ok(boot_res != null, "BootScene failed to load")
	var main_scene: Variant = ProjectSettings.get_setting("application/run/main_scene", "")
	SmokeAssert.ok(str(main_scene).ends_with("BootScene.tscn"), "main_scene must be BootScene")
	return SmokeAssert.passed()
