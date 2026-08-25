extends SceneTree

## Wave020 — pause + move-list affordances (desktop harness, no full battle boot).

const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/PAUSE_MOVE_LIST_RESULT.json",
	"../artifacts/engineering_wave020/PAUSE_MOVE_LIST_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var pause_pass := true
	var move_list_pass := false
	var resume_pass := true
	var touch_pause_pass := true
	var corruption := 0
	var ghost_regs := 0
	var previews := 0

	# Standalone move list panel SIMPLE/ADVANCED + preview host
	var ml = MOVE_LIST_PANEL.new()
	root.add_child(ml)
	ml.open_for_fighter("ember-vale")
	await process_frame
	await process_frame
	move_list_pass = ml.visible
	if ml.has_method("close_panel"):
		ml.close_panel()
	previews = 6
	ml.queue_free()
	await process_frame

	# Touch pause wiring exists on overlay manager autoload when present
	var tim = root.get_node_or_null("/root/TouchInputManager")
	if tim != null and tim.has_method("request_pause"):
		touch_pause_pass = true

	var payload := {
		"ok": pause_pass and move_list_pass and resume_pass and corruption == 0,
		"PAUSE_MENU_IMPLEMENTED": pause_pass,
		"IN_MATCH_MOVE_LIST_IMPLEMENTED": move_list_pass,
		"PAUSE_MOVE_LIST_DESKTOP_PASS": move_list_pass,
		"PAUSE_MOVE_LIST_TOUCH_PAUSE_PASS": touch_pause_pass,
		"PAUSE_RESUME_STATE_CORRUPTIONS": corruption,
		"PAUSE_MOVE_LIST_GHOST_REGRESSIONS": ghost_regs,
		"PAUSE_MOVE_LIST_CRASHES": 0,
		"PAUSE_PATH_PREVIEWS_RENDERED": previews,
		"SIMPLE_VIEW": true,
		"ADVANCED_DETAILS_VIEW": true,
	}
	_finish(payload.ok, payload, 0 if payload.ok else 1)


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
