extends SceneTree

## Capture canonical Godot visible-model runtime renders for Wave014 evidence.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var renders: Array = []
	for fighter_id in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		root.add_child(model)
		var data := _DataLoader.load_fighter(fighter_id)
		if not model.configure(data):
			ok = false
			model.queue_free()
			continue
		var shots := [
			{"name": "battle_idle", "state": _FighterStates.IDLE, "move": {}},
			{"name": "aura_charge", "state": _FighterStates.AURA_CHARGE, "move": {}},
			{"name": "attack", "state": _FighterStates.ATTACK_ACTIVE, "move": {"move_id": "heavy_attack"}},
			{"name": "roster_view", "state": _FighterStates.IDLE, "move": {}, "select": true},
		]
		for shot in shots:
			if shot.get("select", false):
				model.set_select_mode(true)
			model.play_for_state(str(shot.state), shot.move)
			for _i in range(10):
				await process_frame
			var rel := "artifacts/engineering_wave014/runtime_renders/%s/%s.png" % [fighter_id, shot.name]
			var abs := ProjectSettings.globalize_path("res://").path_join("..").path_join(rel)
			DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
			var tex: Texture2D = model.get_node("ModelDisplay").texture
			if tex:
				var img := tex.get_image()
				if img:
					img.save_png(abs)
			renders.append({
				"fighter_id": fighter_id,
				"shot": shot.name,
				"path": rel,
				"RUNTIME_RENDER_SOURCE": "CANONICAL_GODOT_VISIBLE_MODEL",
			})
		model.queue_free()
		await process_frame

	var manifest := {
		"ok": ok,
		"RUNTIME_RENDER_SOURCE": "CANONICAL_GODOT_VISIBLE_MODEL",
		"renders": renders,
		"count": renders.size(),
	}
	_write_json(manifest)
	print("Wave014RuntimeRenders ", "PASS" if ok else "FAIL", " count=", renders.size())
	quit(0 if ok else 1)


func _write_json(payload: Dictionary) -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	var abs := repo_root.path_join("artifacts/engineering_wave014/runtime_renders/manifest.json")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
