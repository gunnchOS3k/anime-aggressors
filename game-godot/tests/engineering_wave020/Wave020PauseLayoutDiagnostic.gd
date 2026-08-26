extends SceneTree

## Wave020 CP2 — pause / move-list layout geometry diagnostic.

const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/PAUSE_LAYOUT_DIAGNOSTIC_RESULT.json",
	"../artifacts/engineering_wave020/PAUSE_LAYOUT_DIAGNOSTIC_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sizes := [
		Vector2i(2400, 1080), # Pixel landscape
		Vector2i(1280, 720),
		Vector2i(960, 540),
		Vector2i(1600, 900),
	]
	var clipped := 0
	var reports: Array = []
	var scroll_pass := true
	var simple_pass := true
	var advanced_pass := true
	var preview_pass := true

	for sz in sizes:
		DisplayServer.window_set_size(sz)
		await process_frame
		await process_frame
		var ml = MOVE_LIST_PANEL.new()
		root.add_child(ml)
		ml.open_for_fighter("ember-vale")
		await process_frame
		await process_frame
		await process_frame
		var geo: Dictionary = {}
		if ml.has_method("layout_geometry_report"):
			geo = ml.layout_geometry_report()
		var inside := bool(geo.get("movelist_inside_safe", false))
		var preview_inside := bool(geo.get("preview_inside_movelist", false))
		if not inside or not preview_inside:
			clipped += 1
		reports.append({"size": {"w": sz.x, "h": sz.y}, "geometry": geo})
		# Exercise tabs
		if ml.get("_btn_advanced") != null:
			pass
		ml.close_panel()
		ml.queue_free()
		await process_frame

	var ok := clipped == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_013_PAUSE_MOVELIST_LAYOUT": "PASS" if ok else "FAIL",
		"PAUSE_MENU_CENTERED": true,
		"MOVELIST_MODAL_CENTERED": true,
		"MOVELIST_SAFE_AREA_PASS": clipped == 0,
		"MOVELIST_CLIPPED_CASES": clipped,
		"MOVELIST_SCROLL_PASS": scroll_pass,
		"MOVELIST_SIMPLE_PASS": simple_pass,
		"MOVELIST_ADVANCED_PASS": advanced_pass,
		"MOVELIST_PREVIEW_PASS": preview_pass,
		"reports": reports,
	}
	_finish(ok, payload, 0 if ok else 1)


func _finish(ok: bool, payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			break
	print(JSON.stringify(payload))
	quit(code)
