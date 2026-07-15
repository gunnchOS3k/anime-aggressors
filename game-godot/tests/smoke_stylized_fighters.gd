extends SceneTree

## Headless check: build all stylized fighters and exercise pose/expression APIs.
const Builder = preload("res://scripts/fighters/stylized_fighter_builder.gd")
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ids := [
		"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
		"nix-calder", "orion-vell", "vesper-nyx",
	]
	var failed := 0
	for id in ids:
		var path := "res://data/fighters/%s.json" % id
		if not FileAccess.file_exists(path):
			push_error("missing fighter json: %s" % id)
			failed += 1
			continue
		var raw := FileAccess.get_file_as_string(path)
		var data: Dictionary = JSON.parse_string(raw)
		var built: Node3D = Builder.create(id, data)
		if built == null or built.name != "StylizedFighter":
			push_error("stylized build failed: %s" % id)
			failed += 1
			continue
		if built.get_node_or_null("Hip") == null:
			push_error("missing Hip on %s" % id)
			failed += 1
		if built.get_node_or_null("Hip/Torso/Chest/Neck/Head") == null:
			push_error("missing Head chain on %s" % id)
			failed += 1
		if built.get_node_or_null("Hip/Torso/Chest/LUpperArm/LForeArm/LHand") == null:
			push_error("missing L arm chain on %s" % id)
			failed += 1
		built.set_expression("confident")
		built.animate_pose("idle", 0.5)
		built.animate_pose("walk", 0.8)
		built.animate_pose("jab_1", 0.2)
		built.animate_pose("heavy_attack", 0.3)
		built.animate_pose("special", 0.4)
		built.animate_pose("aura_burst", 0.4)
		built.animate_pose("throw_up", 0.2)
		built.animate_pose("ko", 0.6)
		built.animate_pose("victory", 1.0)
		print("[stylized] OK %s height=%.2f" % [id, built.get_height_scale()])
		built.free()

		var host := Node.new()
		root.add_child(host)
		var presenter = Model.new()
		host.add_child(presenter)
		var ok: bool = presenter.configure(data)
		if not ok or not presenter.is_model_loaded():
			push_error("presenter configure failed: %s" % id)
			failed += 1
		else:
			presenter.play_for_state("idle")
			presenter.set_expression("focused")
			presenter.set_aura_level(3)
			print("[stylized] presenter OK %s" % id)
		host.queue_free()

	if failed > 0:
		push_error("stylized check failed: %d" % failed)
		quit(1)
	else:
		print("[stylized] all fighters built")
		quit(0)
