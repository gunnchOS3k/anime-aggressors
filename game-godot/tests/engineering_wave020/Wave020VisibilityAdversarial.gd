extends SceneTree

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/VISIBILITY_ADVERSARIAL_RESULT.json",
	"../artifacts/engineering_wave020/VISIBILITY_ADVERSARIAL_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	var roster: Array = gs.roster_ids()
	var host := Node2D.new()
	root.add_child(host)
	var preview: Node2D = MODEL_SCRIPT.new()
	host.add_child(preview)
	await process_frame
	var transitions := 0
	var ghosts := 0
	var idx := 0
	var direction := 1
	while transitions < 80:
		var id: String = str(roster[idx])
		preview.configure(gs.load_fighter(id))
		preview.set_select_mode(true)
		preview.heal_visibility_if_needed()
		if not preview.is_visible_renderable_body():
			ghosts += 1
			break
		transitions += 1
		idx += direction
		if idx >= roster.size():
			direction = -1
			idx = roster.size() - 1
		elif idx < 0:
			direction = 1
			idx = 0
		if transitions % 11 == 0:
			idx = randi() % roster.size()
		await process_frame
	host.queue_free()
	var payload := {
		"ok": ghosts == 0,
		"ADVERSARIAL_VISIBILITY_PASS": ghosts == 0,
		"SELECT_PREVIEW_TRANSITIONS_TESTED": transitions,
		"SELECT_PREVIEW_GHOST_OCCURRENCES": ghosts,
	}
	_write(payload)
	print(JSON.stringify(payload))
	quit(0 if ghosts == 0 else 1)


func _write(payload: Dictionary) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return
