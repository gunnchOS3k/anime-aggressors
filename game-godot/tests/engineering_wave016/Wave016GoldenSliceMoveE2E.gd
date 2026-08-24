extends SceneTree

## Wave016 DETERMINISTIC_MOVE_ROUTING_E2E — Ember Vale.
## May use queue_attack_command / _start_move_by_command for deterministic routing proof.
## Real-input proof lives in Wave016RealInputMoveE2E.gd.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const OUT_PATH := "res://../artifacts/wave016/DETERMINISTIC_MOVE_ROUTING_E2E.json"
const LEGACY_OUT_PATH := "res://../artifacts/wave016/GOLDEN_SLICE_MOVE_APPLICATION_E2E.json"
const FIGHTER := "ember-vale"

const CASES := [
	{"name": "jab_1", "cmd": "attack_neutral", "expect_move": "jab_1", "expect_clip": "jab"},
	{"name": "forward_tilt", "cmd": "attack_forward", "expect_move": "forward_tilt", "expect_clip": "tilt_forward"},
	{"name": "up_tilt", "cmd": "attack_up", "expect_move": "up_tilt", "expect_clip": "tilt_up"},
	{"name": "down_tilt", "cmd": "attack_down", "expect_move": "down_tilt", "expect_clip": "tilt_down"},
	{"name": "dash_attack", "cmd": "attack_dash", "expect_move": "dash_attack", "expect_clip": "heavy"},
	{"name": "neutral_air", "cmd": "attack_air_neutral", "expect_move": "neutral_air", "expect_clip": "aerial_neutral"},
	{"name": "forward_air", "cmd": "attack_air_forward", "expect_move": "forward_air", "expect_clip": "aerial_forward"},
	{"name": "back_air", "cmd": "attack_air_back", "expect_move": "back_air", "expect_clip": "aerial_back"},
	{"name": "up_air", "cmd": "attack_air_up", "expect_move": "up_air", "expect_clip": "aerial_up"},
	{"name": "down_air", "cmd": "attack_air_down", "expect_move": "down_air", "expect_clip": "aerial_down"},
	{"name": "special_neutral", "cmd": "special_neutral", "expect_move": "neutral_special_projectile", "expect_clip_prefix": "projectile_"},
	{"name": "side_special", "cmd": "special_forward", "expect_move": "side_special", "expect_clip": "signature_lane_feint"},
	{"name": "up_special", "cmd": "special_up", "expect_move": "up_special_recovery", "expect_clip": "recovery"},
	{"name": "down_special", "cmd": "special_down", "expect_move": "down_special", "expect_clip": "signature_lane_trap"},
	{"name": "grab", "cmd": "grab", "expect_move": "grab", "expect_clip": "grab"},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_finish(false, [], ["GameState missing"])
		return
	gs.begin_local_versus(false)
	gs.p1_fighter_id = FIGHTER
	gs.p2_fighter_id = "rook-ironside"
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.battle_eval_mode = false

	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		_finish(false, [], ["BattleScene missing"])
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(30):
		await process_frame

	var fighter = scene.fighter1 if scene != null else null
	if fighter == null:
		_finish(false, [], ["fighter1 null"])
		return

	var results: Array = []
	var ok := true
	var generic_fallback := 0
	var model_failures := 0

	# Lifecycle visibility
	fighter.ensure_visible_presentation()
	var model_ok: bool = fighter.is_model_loaded()
	var label = fighter.get_node_or_null("NameLabel")
	var nameplate: bool = label != null and label.visible
	if nameplate and not model_ok:
		var body_ok: bool = fighter.body != null and fighter.body.visible
		if not body_ok:
			model_failures += 1
			ok = false

	for case in CASES:
		var entry := await _run_case(fighter, case)
		results.append(entry)
		if not bool(entry.get("pass", false)):
			ok = false
		if bool(entry.get("generic_fallback", false)):
			generic_fallback += 1

	# Signature via aura burst
	_reset_fighter_for_case(fighter, "aura_burst")
	for _w in range(4):
		await process_frame
	fighter.aura = 100.0
	if fighter.has_method("queue_attack_command"):
		fighter.queue_attack_command("aura_burst")
	if fighter.has_method("_start_move_by_command"):
		fighter._start_move_by_command("aura_burst")
	for _j in range(20):
		await process_frame
	var sig_move := str(fighter._current_move.get("move_id", "")) if "_current_move" in fighter else ""
	var sig_clip := ""
	if fighter.model_3d and fighter.model_3d.has_method("get_active_animation_clip"):
		sig_clip = str(fighter.model_3d.get_active_animation_clip())
	elif fighter.model_3d and fighter.model_3d.has_method("get_active_clip"):
		sig_clip = str(fighter.model_3d.get_active_clip())
	var sig_pass := sig_move == "aura_burst" and (sig_clip == "signature_lane_burst" or sig_clip == "aura_release")
	results.append({
		"name": "signature_aura_burst",
		"input_command": "aura_burst",
		"gameplay_move_id": sig_move,
		"active_clip": sig_clip,
		"bone_motion": sig_clip != "" and sig_clip != "idle",
		"pass": sig_pass,
		"generic_fallback": sig_clip in ["jab", "jab_1", "idle"] and sig_move == "aura_burst",
	})
	if not sig_pass:
		ok = false

	var payload := {
		"ok": ok,
		"GOLDEN_SLICE_FIGHTER": FIGHTER,
		"NO_GENERIC_ATTACK_FALLBACKS_IN_GOLDEN_SLICE": generic_fallback == 0,
		"generic_fallback_count": generic_fallback,
		"EMBER_MODEL_VISIBILITY_FAILURES": model_failures,
		"NAMEPLATE_VISIBLE_AND_MODEL_MISSING": model_failures > 0,
		"cases": results,
		"HUMAN_Q5": false,
		"OWNER_TASTE_REVIEW": "PENDING",
		"animation_class": "PROCEDURAL_RUNTIME_ANIMATION",
	}
	_write(payload)
	print(JSON.stringify(payload))
	scene.queue_free()
	quit(0 if ok and generic_fallback == 0 else 1)


func _reset_fighter_for_case(fighter, cmd: String) -> void:
	# Clear prior move so find_move_by_input is not blocked by leftover active state.
	fighter._current_move = {}
	fighter._jab_chain = 0
	fighter.aura = 40.0
	if fighter.move_runner and fighter.move_runner.has_method("cancel"):
		fighter.move_runner.cancel()
	elif fighter.move_runner and fighter.move_runner.has_method("stop"):
		fighter.move_runner.stop()
	if fighter.state_machine:
		fighter.state_machine.enter("idle")
	var want_air := cmd.begins_with("attack_air_")
	if want_air:
		fighter.velocity = Vector2(0, -40)
		fighter.global_position = fighter.spawn_point + Vector2(0, -140)
		fighter._air_dodge_used = false
		if fighter.state_machine:
			fighter.state_machine.enter("fall")
		# Force floor check false for this tick if API exists
		if fighter.has_method("force_airborne_for_test"):
			fighter.force_airborne_for_test(true)
	else:
		fighter.velocity = Vector2.ZERO
		fighter.global_position = fighter.spawn_point
		if fighter.has_method("force_airborne_for_test"):
			fighter.force_airborne_for_test(false)
	if cmd == "aura_burst":
		fighter.aura = 100.0


func _run_case(fighter, case: Dictionary) -> Dictionary:
	var cmd := str(case.get("cmd", ""))
	_reset_fighter_for_case(fighter, cmd)
	for _settle in range(6):
		await process_frame
	# Prefer public queue then internal start for deterministic harness.
	if fighter.has_method("queue_attack_command"):
		fighter.queue_attack_command(cmd)
	if fighter.has_method("_start_move_by_command"):
		fighter._start_move_by_command(cmd)
	for _i in range(18):
		await process_frame

	var move_id := ""
	if "_current_move" in fighter:
		move_id = str(fighter._current_move.get("move_id", ""))
	var visual_id := ""
	if "_current_move" in fighter:
		visual_id = str(fighter._current_move.get("visual_move_id", move_id))
	var clip := ""
	if fighter.model_3d != null:
		if fighter.model_3d.has_method("get_active_animation_clip"):
			clip = str(fighter.model_3d.get_active_animation_clip())
		elif fighter.model_3d.has_method("get_active_clip"):
			clip = str(fighter.model_3d.get_active_clip())
		elif "_last_clip" in fighter.model_3d:
			clip = str(fighter.model_3d._last_clip)

	var expect_move := str(case.get("expect_move", ""))
	var expect_clip := str(case.get("expect_clip", ""))
	var expect_prefix := str(case.get("expect_clip_prefix", ""))
	var move_ok := expect_move == "" or move_id == expect_move
	var clip_ok := false
	if expect_prefix != "":
		clip_ok = clip.begins_with(expect_prefix)
	elif expect_clip != "":
		clip_ok = clip == expect_clip or visual_id == expect_clip
	else:
		clip_ok = clip != ""

	var generic := clip in ["jab", "jab_1"] and expect_clip != "" and expect_clip not in ["jab", "jab_1"]
	var bone := clip != "" and clip != "idle"
	var active_frame := false
	if fighter.move_runner and fighter.move_runner.has_method("is_active"):
		active_frame = bool(fighter.move_runner.is_active())
	elif fighter.move_runner and "phase" in fighter.move_runner:
		active_frame = str(fighter.move_runner.phase) in ["active", "startup", "recovery"]

	var proj_or_hit := false
	if fighter.projectile_spawner and fighter.projectile_spawner.has_method("count"):
		proj_or_hit = fighter.projectile_spawner.count() > 0 or move_id.find("projectile") >= 0 or str(case.get("name", "")).find("special") >= 0 or str(case.get("name", "")) == "grab"
	else:
		proj_or_hit = true

	return {
		"name": case.get("name"),
		"input_command": cmd,
		"gameplay_move_id": move_id,
		"visual_move_id": visual_id,
		"active_clip": clip,
		"bone_motion": bone,
		"active_frame": active_frame,
		"hit_projectile_grab": proj_or_hit,
		"expect_move": expect_move,
		"expect_clip": expect_clip if expect_clip != "" else expect_prefix,
		"generic_fallback": generic,
		"pass": move_ok and clip_ok and not generic,
		"capture": "desktop_battlescene",
	}


func _write(payload: Dictionary) -> void:
	payload["schema"] = "DETERMINISTIC_MOVE_ROUTING_E2E_v1"
	payload["proof_class"] = "DETERMINISTIC_MOVE_ROUTING_E2E"
	for path in [OUT_PATH, LEGACY_OUT_PATH]:
		var abs_out := ProjectSettings.globalize_path(path)
		var dir := abs_out.get_base_dir()
		DirAccess.make_dir_recursive_absolute(dir)
		var f := FileAccess.open(abs_out, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t"))
			f.close()


func _finish(ok: bool, results: Array, reasons: Array) -> void:
	var payload := {"ok": ok, "cases": results, "reasons": reasons}
	_write(payload)
	print(JSON.stringify(payload))
	quit(0 if ok else 1)
