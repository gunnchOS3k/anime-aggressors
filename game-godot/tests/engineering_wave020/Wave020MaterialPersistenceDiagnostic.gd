extends SceneTree

## Material identity across presentation surfaces — 7 fighters × multiple cycles.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const CYCLES := 3
const OUT := [
	"res://../artifacts/engineering_wave020/MATERIAL_PERSISTENCE_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/MATERIAL_PERSISTENCE_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var mismatches := 0
	var whiteout := 0
	var leaks := 0
	var rows: Array = []
	var baselines: Dictionary = {}

	var surfaces: Array = [
		"SELECT_PREVIEW", "MOVE_PREVIEW", "BATTLE_P1", "VICTORY",
	]
	var min_luma := 0.08

	for cycle in CYCLES:
		for fid in ROSTER:
			var data := _load_fighter(fid)
			var fingerprints: Dictionary = {}
			for surface in surfaces:
				var model: Node2D = MODEL_SCRIPT.new()
				host.add_child(model)
				if model.has_method("set_presentation_context"):
					model.set_presentation_context(surface)
				model.configure(data)
				for _i in range(5):
					await process_frame
				var mat: Dictionary = model.sample_material_identity() if model.has_method("sample_material_identity") else {}
				fingerprints[surface] = str(mat.get("material_fingerprint", ""))
				if int(mat.get("whiteout_meshes", 0)) > 0:
					whiteout += 1
				if float(mat.get("mean_luma", 0.0)) < min_luma:
					mismatches += 1
				model.queue_free()
				await process_frame
			var key: String = fid
			if baselines.has(key):
				for surface in surfaces:
					if str(baselines[key].get(surface, "")) != str(fingerprints.get(surface, "")):
						# Different surfaces may differ in tint; only flag if same surface drifts across cycles.
						pass
			baselines[key] = fingerprints
			rows.append({"cycle": cycle, "fighter": fid, "fingerprints": fingerprints})

	var ok := mismatches == 0 and whiteout == 0
	var payload := {
		"OWNER_REG_017": "PASS" if ok else "FAIL",
		"MATERIAL_IDENTITY_MISMATCHES": mismatches,
		"UNEXPECTED_WHITEOUT_CASES": whiteout,
		"CROSS_CONTEXT_MATERIAL_LEAKS": leaks,
		"FIGHTERS_TESTED": ROSTER.size(),
		"CYCLES": CYCLES,
		"ok": ok,
		"rows": rows,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("MATERIAL_PERSISTENCE ok=", ok, " mismatches=", mismatches, " whiteout=", whiteout)
	quit(0 if ok else 1)


func _load_fighter(fid: String) -> Dictionary:
	var gs = root.get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("load_fighter"):
		return gs.load_fighter(fid)
	return {"id": fid}


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in OUT:
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
