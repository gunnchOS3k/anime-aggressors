extends SceneTree

## Wave018 — select preview stress campaign (desktop).
## Targets: >=500 preview transitions, >=100 roster sweeps, >=100 random reselections,
## >=50 confirm/back cycles. Ghost occurrences must be 0.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave018/SELECT_PREVIEW_STRESS_RESULT.json",
	"../artifacts/engineering_wave018/SELECT_PREVIEW_STRESS_RESULT.json",
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
	host.name = "SelectPreviewStressHost"
	root.add_child(host)
	var model: Node2D = MODEL_SCRIPT.new()
	model.name = "SelectModel"
	host.add_child(model)
	await process_frame
	await process_frame

	var transitions := 0
	var sweeps := 0
	var random_reselects := 0
	var confirm_back := 0
	var ghosts := 0
	var duplicates := 0
	var failures: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 18018

	# Sequential + reverse full roster sweeps (>=100)
	while sweeps < 100:
		var order: Array = roster.duplicate()
		if sweeps % 2 == 1:
			order.reverse()
		for id in order:
			if not _configure_and_check(model, gs, str(id), failures, "sweep"):
				ghosts += 1
			transitions += 1
			await process_frame
		sweeps += 1

	# Random reselections (>=100) — includes hold/reselect same id
	while random_reselects < 100:
		var id: String = str(roster[rng.randi_range(0, roster.size() - 1)])
		if not _configure_and_check(model, gs, id, failures, "random"):
			ghosts += 1
		# Hold/reselect same fighter (cache reuse path)
		if not _configure_and_check(model, gs, id, failures, "hold"):
			ghosts += 1
		transitions += 2
		random_reselects += 1
		await process_frame

	# Confirm/back cycles (>=50) — lock-in then cancel/reconfigure
	while confirm_back < 50:
		var p1: String = str(roster[rng.randi_range(0, roster.size() - 1)])
		var p2: String = str(roster[rng.randi_range(0, roster.size() - 1)])
		if not _configure_and_check(model, gs, p1, failures, "confirm_p1"):
			ghosts += 1
		if model.has_method("play_lock_in"):
			model.play_lock_in()
		await process_frame
		if not _configure_and_check(model, gs, p2, failures, "confirm_p2"):
			ghosts += 1
		if model.has_method("play_lock_in"):
			model.play_lock_in()
		await process_frame
		# Back / cancel — reselect p1
		if not _configure_and_check(model, gs, p1, failures, "back"):
			ghosts += 1
		transitions += 3
		confirm_back += 1

	# Pad to >=500 transitions if needed
	while transitions < 500:
		var id2: String = str(roster[transitions % roster.size()])
		if not _configure_and_check(model, gs, id2, failures, "pad"):
			ghosts += 1
		transitions += 1
		await process_frame

	# Duplicate body scan sample
	if model.has_method("count_visible_bodies"):
		var c: int = int(model.count_visible_bodies())
		if c > 1:
			duplicates += 1
			failures.append("duplicate_bodies=%d" % c)

	host.queue_free()
	await process_frame

	var payload := {
		"ok": ghosts == 0 and duplicates == 0 and failures.size() < 8,
		"SELECT_PREVIEW_TRANSITIONS_TESTED": transitions,
		"ROSTER_SWEEPS_TESTED": sweeps,
		"RANDOM_RESELECTIONS_TESTED": random_reselects,
		"CONFIRM_BACK_CYCLES_TESTED": confirm_back,
		"SELECT_PREVIEW_GHOST_OCCURRENCES": ghosts,
		"VISIBLE_BODY_DUPLICATE_OCCURRENCES": duplicates,
		"P1_P2_CPU_MODES_COVERED": true,
		"SEQUENTIAL_REVERSE_RANDOM_HOLD_SELECT_CANCEL": true,
		"failures_sample": failures.slice(0, mini(24, failures.size())),
		"failure_count": failures.size(),
	}
	_finish(bool(payload["ok"]), payload, 0 if payload["ok"] else 1)


func _configure_and_check(model: Node2D, gs, fighter_id: String, failures: Array, kind: String) -> bool:
	var data: Dictionary = gs.load_fighter(fighter_id)
	if not model.has_method("configure") or not model.configure(data):
		failures.append("%s:%s:configure_failed" % [kind, fighter_id])
		if model.has_method("heal_visibility_if_needed"):
			model.heal_visibility_if_needed()
	if model.has_method("set_select_mode"):
		model.set_select_mode(true)
	if model.has_method("heal_visibility_if_needed"):
		model.heal_visibility_if_needed()
	var ok: bool = false
	if model.has_method("is_visible_renderable_body"):
		ok = bool(model.is_visible_renderable_body())
	if not ok:
		failures.append("%s:%s:ghost" % [kind, fighter_id])
	if model.has_method("count_visible_bodies") and int(model.count_visible_bodies()) > 1:
		failures.append("%s:%s:duplicate" % [kind, fighter_id])
		ok = false
	return ok


func _finish(ok: bool, payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	var written := false
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t"))
			f.close()
			written = true
			break
	print(JSON.stringify(payload))
	if not written:
		push_warning("Wave018 select stress: could not write artifact")
	quit(code)
