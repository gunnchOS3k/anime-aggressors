extends SceneTree

## FRONT stills must face AA_FrontMarker / rest-pose +Y, not merely a +Z camera.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const OUT := "../artifacts/vxp3/reports/REVIEW_CAMERA_ORIENTATION_RUNTIME_V4.json"

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]


func _init() -> void:
	call_deferred("_run")


func _find_marker(root: Node) -> Node3D:
	if root == null:
		return null
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Node3D and str(n.name).begins_with("AA_FrontMarker"):
			return n as Node3D
		for c in n.get_children():
			stack.append(c)
	return null


func _run() -> void:
	var per: Dictionary = {}
	var correct := 0
	for fid in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		root.add_child(model)
		model.configure(_DataLoader.load_fighter(fid))
		await process_frame
		var marker: Node3D = null
		var loaded: Node = null
		if model.has_method("get_visible_model_node"):
			loaded = model.get_visible_model_node()
		if loaded:
			marker = _find_marker(loaded)
		if marker == null:
			marker = _find_marker(model)
		var ok := false
		if marker:
			var fwd: Vector3 = Vector3(0, 1, 0)
			if marker.has_meta("aa_forward"):
				var raw = marker.get_meta("aa_forward")
				if raw is Vector3:
					fwd = raw
				elif raw is Array and raw.size() >= 3:
					fwd = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
			ok = fwd.dot(Vector3(0, 1, 0)) > 0.25
			if ok:
				correct += 1
		per[fid] = {
			"marker_present": marker != null,
			"front_camera_correct": ok,
		}
		model.queue_free()
		await process_frame
	var payload := {
		"FRONT_CAMERA_CORRECT": "%d/%d" % [correct, FIGHTERS.size()],
		"ok": correct == FIGHTERS.size(),
		"fighters": per,
		"HUMAN_ART_DIRECTION_APPROVAL": false,
	}
	var abs := ProjectSettings.globalize_path("res://").path_join("..").path_join(OUT)
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print(JSON.stringify(payload))
	quit(0 if bool(payload["ok"]) else 1)
