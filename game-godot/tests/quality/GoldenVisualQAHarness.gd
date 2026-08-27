extends SceneTree

## GoldenVisualQA v1 desktop harness — non-invasive presentation sampling.
## Emits metadata for semantic contracts; does not mutate live materials.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const SURFACES := [
	"SELECT_PREVIEW", "MOVE_PREVIEW", "BATTLE_P1", "VICTORY",
]
const OUT_PATHS := [
	"res://../artifacts/visual_qa/latest/godot_harness.json",
	"../artifacts/visual_qa/latest/godot_harness.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var failures: Array = []
	var samples: Array = []
	var states_sampled := 0

	for fid in ROSTER:
		var data := _load_fighter(fid)
		if data.is_empty():
			failures.append({"fighter": fid, "class": "MISSING_MODEL", "reason": "fighter_data_missing"})
			continue
		for surface in SURFACES:
			var model: Node2D = MODEL_SCRIPT.new()
			host.add_child(model)
			if model.has_method("set_presentation_context"):
				model.set_presentation_context(surface)
			model.configure(data)
			for _i in range(6):
				await process_frame

			var mat: Dictionary = {}
			if model.has_method("sample_material_identity"):
				mat = model.sample_material_identity()
			var scale_info: Dictionary = {}
			if model.has_method("sample_scale_contract"):
				scale_info = model.sample_scale_contract()
			elif model.has_method("get_presentation_scale_contract"):
				scale_info = model.get_presentation_scale_contract()

			var root_scale := Vector3.ONE
			if model.has_method("get_model_root_scale"):
				root_scale = model.get_model_root_scale()
			elif model.get("model_root") != null:
				var mr = model.get("model_root")
				if mr is Node3D:
					root_scale = (mr as Node3D).scale

			var whiteout := int(mat.get("whiteout_meshes", 0))
			var luma := float(mat.get("mean_luma", 0.5))
			var overscale := bool(scale_info.get("display_overscale", false))
			var root_violation := bool(scale_info.get("model_root_scale_violation", false))
			if abs(root_scale.x - 1.0) > 0.01 or abs(root_scale.y - 1.0) > 0.01 or abs(root_scale.z - 1.0) > 0.01:
				root_violation = true

			var row := {
				"fighter_id": fid,
				"presentation_context": surface,
				"material_fingerprint": str(mat.get("material_fingerprint", "")),
				"mean_luma": luma,
				"whiteout_meshes": whiteout,
				"display_overscale": overscale,
				"model_root_scale": {"x": root_scale.x, "y": root_scale.y, "z": root_scale.z},
				"model_root_scale_violation": root_violation,
				"mesh_count": int(mat.get("mesh_count", 0)),
				"witness_non_invasive": true,
			}
			samples.append(row)
			states_sampled += 1

			if int(mat.get("mesh_count", 0)) <= 0:
				failures.append({"fighter": fid, "surface": surface, "class": "MISSING_MODEL"})
			if whiteout > 0 or luma > 0.85:
				failures.append({"fighter": fid, "surface": surface, "class": "MATERIAL_WHITEOUT"})
			if overscale or root_violation:
				failures.append({"fighter": fid, "surface": surface, "class": "OVERSCALE"})

			model.queue_free()
			await process_frame

	var ok := failures.is_empty()
	var payload := {
		"ok": ok,
		"GOLDEN_VISUAL_QA_HARNESS": "PASS" if ok else "FAIL",
		"states_sampled": states_sampled,
		"fighters": ROSTER.size(),
		"surfaces": SURFACES,
		"failures": failures,
		"samples": samples,
		"non_invasive": true,
		"OWNER_APPROVED_GOLDEN_COUNT": 0,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("GOLDEN_VISUAL_QA_HARNESS=", payload["GOLDEN_VISUAL_QA_HARNESS"], " sampled=", states_sampled, " failures=", failures.size())
	quit(0 if ok else 1)


func _load_fighter(fid: String) -> Dictionary:
	var gs = root.get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("load_fighter"):
		return gs.load_fighter(fid)
	return {"id": fid}


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in OUT_PATHS:
		var abs_path := ProjectSettings.globalize_path(p) if str(p).begins_with("res://") else str(p)
		if not abs_path.is_absolute_path():
			abs_path = ProjectSettings.globalize_path("res://../") + abs_path.trim_prefix("../")
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
			print("Wrote ", abs_path)
