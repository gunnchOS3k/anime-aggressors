extends RefCounted
class_name FighterAssetLoader

## Loads production GLB or DEBUG FALLBACK rig with explicit content gate labeling.

static func load_fighter_visual(parent: Node2D, fighter_id: String) -> Node2D:
	var glb_path := FighterAssetContract.glb_path(fighter_id)
	if ResourceLoader.exists(glb_path):
		var scene: PackedScene = load(glb_path)
		if scene != null:
			var instance := scene.instantiate()
			parent.add_child(instance)
			if instance is Node2D:
				return instance as Node2D
			return _wrap_node3d(parent, instance as Node3D, fighter_id, false)

	return _spawn_debug_fallback(parent, fighter_id)

static func _spawn_debug_fallback(parent: Node2D, fighter_id: String) -> Node2D:
	var rig_scene: PackedScene = load("res://scenes/fighter/ProductionFighterRig.tscn")
	var rig: ProductionFighterRig = rig_scene.instantiate() as ProductionFighterRig
	rig.configure(fighter_id)
	parent.add_child(rig)

	var banner := Label.new()
	banner.name = "ContentGateBanner"
	banner.text = FighterAssetContract.DEBUG_FALLBACK_LABEL
	banner.add_theme_font_size_override("font_size", 10)
	banner.modulate = Color(1, 0.45, 0.35)
	banner.position = Vector2(-120, -92)
	parent.add_child(banner)
	return rig

static func _wrap_node3d(parent: Node2D, node: Node3D, fighter_id: String, _fallback: bool) -> Node2D:
	var holder := Node2D.new()
	holder.name = "ProductionFighter_%s" % fighter_id
	parent.add_child(holder)
	holder.add_child(node)
	return holder

static func get_content_status(fighter_id: String) -> Dictionary:
	return FighterAssetContract.validate(fighter_id, null)
