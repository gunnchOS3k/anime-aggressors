extends SceneTree

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/CHARACTER_SELECT_FRAMING_RESULT.json",
	"../artifacts/engineering_wave020/CHARACTER_SELECT_FRAMING_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	var gates = preload("res://scripts/menus/wave020_presentation_gates.gd")
	gates.enable_slice_a_framing()
	var roster: Array = gs.roster_ids()
	var host := Node2D.new()
	root.add_child(host)
	var per_fighter: Dictionary = {}
	var head_count := 0
	var feet_count := 0
	var silhouette_count := 0
	for fidv in roster:
		var fid: String = str(fidv)
		var model: Node2D = MODEL_SCRIPT.new()
		host.add_child(model)
		model.configure(gs.load_fighter(fid))
		model.set_select_mode(true)
		await process_frame
		await process_frame
		var report: Dictionary = model.get_select_framing_report() if model.has_method("get_select_framing_report") else {}
		report["fighter_id"] = fid
		per_fighter[fid] = report
		if bool(report.get("head_visible", false)):
			head_count += 1
		if bool(report.get("feet_visible", false)):
			feet_count += 1
		if bool(report.get("silhouette_readable", false)):
			silhouette_count += 1
		model.queue_free()
		await process_frame
	host.queue_free()
	var ok := head_count == roster.size() and feet_count == roster.size() and silhouette_count == roster.size()
	var payload := {
		"ok": ok,
		"DYNAMIC_PREVIEW_FRAMING_IMPLEMENTED": true,
		"FIGHTERS_WITH_HEAD_VISIBLE": head_count,
		"FIGHTERS_WITH_FEET_VISIBLE": feet_count,
		"FIGHTERS_WITH_READABLE_FULL_SILHOUETTE": silhouette_count,
		"FRAMING_OWNER_REVIEW": "PENDING",
		"per_fighter": per_fighter,
	}
	_write(payload)
	print(JSON.stringify(payload))
	quit(0 if ok else 1)


func _write(payload: Dictionary) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return
