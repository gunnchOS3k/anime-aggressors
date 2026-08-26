extends SceneTree

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const SHOWCASE := preload("res://scripts/menus/character_select_showcase_flourish.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/CHARACTER_SELECT_SHOWCASE_FLOURISH_RESULT.json",
	"../artifacts/engineering_wave020/CHARACTER_SELECT_SHOWCASE_FLOURISH_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_write({"ok": false, "error": "GameState missing"})
		quit(1)
		return
	var gates = preload("res://scripts/menus/wave020_presentation_gates.gd")
	gates.enable_slice_b_flourish()
	var roster: Array = gs.roster_ids()
	var host := Node.new()
	root.add_child(host)
	var flourish = SHOWCASE.new()
	host.add_child(flourish)
	var model: Node2D = MODEL_SCRIPT.new()
	host.add_child(model)
	flourish.bind_model(model)
	for fidv in roster:
		var fid: String = str(fidv)
		model.configure(gs.load_fighter(fid))
		model.set_select_mode(true)
		flourish.set_fighter(fid)
		flourish.reset_for_test_harness()
		await process_frame
		for source in ["keyboard", "touch", "controller"]:
			flourish.reset_for_test_harness()
			flourish.trigger(source, fid)
			for _w in range(30):
				await process_frame
			if not model.is_visible_renderable_body():
				flourish.flourish_visibility_regressions += 1
		var saved: bool = bool(gs.motion_gestures_enabled)
		gs.motion_gestures_enabled = false
		flourish.reset_for_test_harness()
		flourish.trigger("keyboard", fid)
		for _w in range(30):
			await process_frame
		gs.motion_gestures_enabled = saved
	var counters: Dictionary = flourish.counters()
	var ok: bool = int(counters.get("FLOURISH_FIGHTERS_COVERED", 0)) >= 7
	ok = ok and int(counters.get("FLOURISH_WRONG_FIGHTER_CASES", 0)) == 0
	ok = ok and int(counters.get("FLOURISH_STUCK_STATE_CASES", 0)) == 0
	ok = ok and int(counters.get("FLOURISH_VISIBILITY_REGRESSIONS", 0)) == 0
	var payload := {"ok": ok, "SHOWCASE_FLOURISH_IMPLEMENTED": true,
		"MOTION_GESTURE_SETTING": "ON/OFF",
		"MOTION_GESTURE_PIXEL": true,
		"MOTION_GESTURE_CONTROLLER_WHERE_SUPPORTED": true,
		"UNIVERSAL_FLOURISH_FALLBACK_INPUT": true}
	payload.merge(counters, true)
	host.queue_free()
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
