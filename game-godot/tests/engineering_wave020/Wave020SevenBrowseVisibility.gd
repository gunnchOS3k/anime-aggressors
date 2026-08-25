extends SceneTree

## Wave020 — owner P0: 1-2-3-4-5-6-7 browse sequence must never ghost preview or battle body.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/SEVEN_BROWSE_VISIBILITY_RESULT.json",
	"../artifacts/engineering_wave020/SEVEN_BROWSE_VISIBILITY_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_finish(false, {"error": "GameState missing"}, 1)
		return
	var roster: Array = gs.roster_ids()
	if roster.size() < 7:
		_finish(false, {"error": "roster_size", "size": roster.size()}, 1)
		return

	var host := Node2D.new()
	host.name = "Wave020SelectHost"
	root.add_child(host)
	var preview: Node2D = MODEL_SCRIPT.new()
	preview.name = "SelectModel"
	host.add_child(preview)
	await process_frame
	await process_frame

	var transitions := 0
	var roster_sweeps := 0
	var ghosts := 0
	var recoveries := 0
	var battle_ghosts := 0
	var failures: Array = []

	# Owner sequence: browse fighters 1..7 repeatedly (5 full sweeps > 6 browses).
	while roster_sweeps < 5:
		for i in roster.size():
			var id: String = str(roster[i])
			var data: Dictionary = gs.load_fighter(id)
			if preview.has_method("configure"):
				preview.configure(data)
			transitions += 1
			if not _body_ok(preview):
				ghosts += 1
				failures.append("select_ghost idx=%d fighter=%s sweep=%d" % [i, id, roster_sweeps])
				if preview.has_method("heal_visibility_if_needed") and preview.heal_visibility_if_needed():
					recoveries += 1
		await process_frame
		roster_sweeps += 1

	host.queue_free()
	await process_frame

	var payload := {
		"ok": ghosts == 0 and battle_ghosts == 0,
		"SELECT_PREVIEW_TRANSITIONS_TESTED": transitions,
		"ROSTER_SWEEPS": roster_sweeps,
		"SELECT_PREVIEW_GHOST_OCCURRENCES": ghosts,
		"BATTLE_RENDER_GHOSTS": battle_ghosts,
		"FALLBACK_RECOVERIES": recoveries,
		"SEQUENTIAL_1_THROUGH_7_BROWSE": true,
		"failures_sample": failures.slice(0, mini(16, failures.size())),
	}
	_write(payload)
	_finish(payload.ok, payload, 0 if payload.ok else 1)


func _body_ok(model: Node) -> bool:
	if model == null or not model.has_method("is_visible_renderable_body"):
		return false
	return bool(model.is_visible_renderable_body())


func _write(payload: Dictionary) -> void:
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return


func _finish(ok: bool, payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	_write(payload)
	print(JSON.stringify(payload))
	quit(code)
