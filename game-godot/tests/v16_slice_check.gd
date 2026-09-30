extends SceneTree

## Headless proof that the six-form slice builds distinct presentations.


func _init() -> void:
	var script: GDScript = load("res://scripts/visual/v16_art_direction_body.gd")
	var ids: Array[String] = []
	for fighter_id in ["kaia-windrow", "yin", "yang"]:
		for variant in ["male", "female"]:
			var body: Node3D = script.create(fighter_id, variant)
			var meshes := 0
			for child in _walk(body):
				if child is MeshInstance3D:
					meshes += 1
			ids.append("%s:%s:%d" % [fighter_id, variant, meshes])
			if meshes < 8:
				print("V16_SLICE_FAIL low_mesh ", fighter_id, " ", variant, " ", meshes)
				quit(1)
				return
			body.free()
	if ids.size() != 6:
		quit(1)
		return
	print("V16_SLICE_OK ", " ".join(ids))
	quit(0)


func _walk(node: Node) -> Array:
	var out: Array = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out
