extends SceneTree

## Wave020 presentation isolation — 20+ roster sweeps, stop on first disappearance.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const SWEEPS := 22
const OUT := [
	"res://../artifacts/engineering_wave020/SELECT_LIFECYCLE_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/SELECT_LIFECYCLE_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var preview: Node2D = MODEL_SCRIPT.new()
	preview.name = "SelectPreview"
	host.add_child(preview)
	if preview.has_method("set_presentation_context"):
		preview.set_presentation_context("SELECT_PREVIEW")
	elif preview.has_method("set_select_mode"):
		preview.set_select_mode(true)
	await process_frame

	var transitions := 0
	var disappearance := 0
	var whiteout := 0
	var material_mismatch := 0
	var first_fail: Dictionary = {}
	var rows: Array = []

	for sweep in SWEEPS:
		for fid in ROSTER:
			transitions += 1
			var data: Dictionary = _load_fighter(fid)
			if preview.has_method("configure"):
				preview.configure(data)
			for _i in range(4):
				await process_frame
			var w: Dictionary = preview.get_final_screen_visibility_witness() if preview.has_method("get_final_screen_visibility_witness") else {}
			var mat: Dictionary = w.get("material_identity", {})
			var ghost := not bool(w.get("SCENE_TREE_VISIBLE", false))
			var wo := int(mat.get("whiteout_meshes", 0)) > 0
			var mm := not bool(w.get("FINAL_SCREEN_MATERIAL_IDENTITY_PASS", true))
			if ghost:
				disappearance += 1
			if wo:
				whiteout += 1
			if mm:
				material_mismatch += 1
			if (ghost or wo or mm) and first_fail.is_empty():
				first_fail = {
					"sweep": sweep,
					"fighter_id": fid,
					"transition_index": transitions,
					"witness": w,
				}
				_emit_and_quit(transitions, disappearance, whiteout, material_mismatch, first_fail, rows)
				return
			rows.append({"sweep": sweep, "fighter": fid, "transition": transitions, "witness": w})

	_emit_and_quit(transitions, disappearance, whiteout, material_mismatch, first_fail, rows)


func _load_fighter(fid: String) -> Dictionary:
	var gs = root.get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("load_fighter"):
		return gs.load_fighter(fid)
	return {"id": fid}


func _emit_and_quit(transitions: int, disappearance: int, whiteout: int, material_mismatch: int, first_fail: Dictionary, rows: Array) -> void:
	var ok := disappearance == 0 and whiteout == 0 and material_mismatch == 0
	var payload := {
		"OWNER_REG_016": "PASS" if disappearance == 0 else "FAIL",
		"SELECT_DIAGNOSTIC_ROSTER_SWEEPS": SWEEPS,
		"SELECT_DIAGNOSTIC_TRANSITIONS": transitions,
		"SELECT_DISAPPEARANCE_CASES": disappearance,
		"SELECT_WHITEOUT_CASES": whiteout,
		"SELECT_MATERIAL_IDENTITY_MISMATCHES": material_mismatch,
		"first_failure": first_fail,
		"ok": ok,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	if rows.size() <= 40:
		payload["rows"] = rows
	else:
		payload["rows_sample"] = rows.slice(0, 20)
	var text := JSON.stringify(payload, "\t")
	for p in OUT:
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
	print("SELECT_LIFECYCLE ok=", ok, " transitions=", transitions, " disappearance=", disappearance)
	quit(0 if ok else 1)
