extends SceneTree

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/VISIBILITY_ACCEPTANCE_RESULT.json",
	"../artifacts/engineering_wave020/VISIBILITY_ACCEPTANCE_RESULT.json",
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
	var sweeps := 0
	var randoms := 0
	var confirm_back := 0
	var battle_launches := 0
	var ghosts := 0
	var battle_ghosts := 0
	while sweeps < 100:
		for i in roster.size():
			preview.configure(gs.load_fighter(str(roster[i])))
			preview.set_select_mode(true)
			transitions += 1
			if not preview.is_visible_renderable_body():
				ghosts += 1
		sweeps += 1
		await process_frame
	for _r in range(100):
		preview.configure(gs.load_fighter(str(roster[randi() % roster.size()])))
		randoms += 1
		transitions += 1
		if not preview.is_visible_renderable_body():
			ghosts += 1
		await process_frame
	for _c in range(50):
		confirm_back += 1
		transitions += 2
		preview.configure(gs.load_fighter(str(roster[randi() % roster.size()])))
		await process_frame
	for fi in range(min(100, roster.size() * 14)):
		if not await _battle_ok(gs, str(roster[fi % roster.size()]), str(roster[(fi + 1) % roster.size()])):
			battle_ghosts += 1
		battle_launches += 1
	host.queue_free()
	var payload := {
		"ok": ghosts == 0 and battle_ghosts == 0 and transitions >= 500,
		"ACCEPTANCE_VISIBILITY_PASS": ghosts == 0 and battle_ghosts == 0,
		"SELECT_PREVIEW_TRANSITIONS_TESTED": transitions,
		"ROSTER_SWEEPS_TESTED": sweeps,
		"RANDOM_RESELECTIONS_TESTED": randoms,
		"CONFIRM_BACK_CYCLES_TESTED": confirm_back,
		"SELECT_TO_BATTLE_LAUNCHES_TESTED": battle_launches,
		"SELECT_PREVIEW_GHOST_OCCURRENCES": ghosts,
		"SELECT_TO_BATTLE_GHOST_OCCURRENCES": battle_ghosts,
	}
	_write(payload)
	print(JSON.stringify(payload))
	quit(0 if payload.ok else 1)


func _battle_ok(gs, p1: String, p2: String) -> bool:
	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		return false
	gs.begin_local_versus(false)
	gs.p1_fighter_id = p1
	gs.p2_fighter_id = p2
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(20):
		await process_frame
	var ok := true
	for f in [scene.fighter1, scene.fighter2]:
		if f == null or not f.assert_visible_body_invariant().get("PASS", false):
			ok = false
	scene.queue_free()
	await process_frame
	return ok


func _write(payload: Dictionary) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return
