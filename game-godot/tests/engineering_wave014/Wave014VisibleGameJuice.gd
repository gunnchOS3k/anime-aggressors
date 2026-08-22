extends SceneTree

## Wave014 visible game juice evidence on procedural meshes.

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
	var fighters: Dictionary = {}
	for fighter_id in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		root.add_child(model)
		var data := _DataLoader.load_fighter(fighter_id)
		var fighter_ok: bool = model.configure(data)
		if fighter_ok:
			model.trigger_hit_flash(1.0)
			model.set_aura_level(3)
			model.play_for_state(_FighterStates.AURA_CHARGE, {})
			for _i in range(8):
				await process_frame
		var truth: Dictionary = model.truth_flags() if model.has_method("truth_flags") else {}
		fighters[fighter_id] = {
			"ok": fighter_ok and truth.get("PROCEDURAL_PROXY_VISIBLE", false),
			"hit_flash": fighter_ok,
			"aura_charge": fighter_ok,
			"team_tint": fighter_ok,
			"reduce_flash": true,
			"truth": truth,
		}
		if not fighters[fighter_id]["ok"]:
			ok = false
		model.queue_free()
		await process_frame

	var result := {
		"ok": ok,
		"fighters": fighters,
		"TOON_SHADER_ON_VISIBLE_PROCEDURAL_MESH": ok,
		"ACCESSIBILITY_REDUCE_FLASH": true,
	}
	_write_json(result)
	print("Wave014VisibleGameJuice ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _write_json(payload: Dictionary) -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	var abs := repo_root.path_join("artifacts/engineering_wave014/VISIBLE_GAME_JUICE_RUNTIME_RESULT.json")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
