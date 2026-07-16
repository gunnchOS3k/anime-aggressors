extends SceneTree

## Regression: rapid fighter preview cycling must not leak models or viewports.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: PackedStringArray = []
	var model_script: GDScript = load("res://scripts/fighters/fighter_model_3d.gd") as GDScript
	if model_script == null:
		push_error("missing fighter_model_3d")
		quit(1)
		return
	var gm := root.get_node_or_null("GameState")
	if gm == null:
		push_error("GameState missing")
		quit(1)
		return
	var roster: Array = gm.roster_ids()
	if roster.size() < 7:
		failures.append("expected 7 fighters, got %d" % roster.size())

	var host := Node2D.new()
	root.add_child(host)
	var model: Node2D = model_script.new()
	host.add_child(model)
	await process_frame
	await process_frame

	for cycle in 3:
		for id in roster:
			var data: Dictionary = gm.load_fighter(str(id))
			if not model.has_method("configure") or not model.configure(data):
				failures.append("configure failed for %s" % id)
				continue
			if model.has_method("set_select_mode"):
				model.set_select_mode(true)
			await process_frame
			var vp_count := _count_named(model, "Fighter3DViewport")
			var style_count := _count_prefix(model, "StylizedFighter")
			if vp_count != 1:
				failures.append("%s cycle %d has %d SubViewports" % [id, cycle, vp_count])
			if style_count != 1:
				failures.append("%s cycle %d has %d stylized roots" % [id, cycle, style_count])
			if model.has_method("is_model_loaded") and not model.is_model_loaded():
				failures.append("%s not loaded after configure" % id)

	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("preview_cycle_regression: PASS")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)


func _count_named(node: Node, name: String) -> int:
	var n := 0
	if node.name == name:
		n += 1
	for c in node.get_children():
		n += _count_named(c, name)
	return n


func _count_prefix(node: Node, prefix: String) -> int:
	var n := 0
	if String(node.name).begins_with(prefix):
		n += 1
	for c in node.get_children():
		n += _count_prefix(c, prefix)
	return n
