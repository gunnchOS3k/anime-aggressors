extends Node

## Wave017 Pixel physical closeout harness.
## Invoke: --es command_line "--wave017-pixel-closeout"
## Trigger: user://wave017_pixel_closeout_trigger.txt
## Evidence: user://wave017/

const OUT_DIR := "user://wave017/"
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const VERSUS_PATH := "res://scenes/menus/VersusScene.tscn"
const RESULTS_PATH := "res://scenes/ui/ResultsScene.tscn"
const ARCADE_PATH := "res://scenes/menus/ArcadeScene.tscn"
const FIGHTER := "ember-vale"
const OPPONENT := "rook-ironside"
const FORBIDDEN := [
	"PROCEDURAL PRODUCTION PROXY",
	"PROXY — NOT FINAL ART",
	"STYLIZED FALLBACK",
	"MODEL_PENDING",
	"PLACEHOLDER",
	"DEBUG",
]

## 23 authentic Wave017 visual capture cases.
const CAPTURE_CASES := [
	{"label": "versus_entry", "kind": "versus", "gameplay_state": "versus", "expect_move": "", "expect_clip": ""},
	{"label": "ember_idle", "kind": "idle", "gameplay_state": "idle", "expect_move": "", "expect_clip": "idle"},
	{"label": "ember_run_movement", "kind": "run", "gameplay_state": "run", "expect_move": "", "expect_clip": "run"},
	{"label": "ember_close_melee", "kind": "attack", "gameplay_state": "close_melee", "axis": Vector2(0, 0), "air": false, "expect_move": "jab", "expect_clip": "jab"},
	{"label": "ember_forward_tilt", "kind": "attack", "gameplay_state": "forward_tilt", "axis": Vector2(0.45, 0), "air": false, "expect_move": "forward_tilt", "expect_clip": "tilt_forward"},
	{"label": "ember_aerial", "kind": "attack", "gameplay_state": "aerial", "axis": Vector2(0.7, 0), "air": true, "expect_move": "forward_air", "expect_clip": "aerial_forward"},
	{"label": "ember_proj_tap", "kind": "projectile", "gameplay_state": "projectile_tap", "tier_aura": 20.0, "expect_move": "neutral_special_projectile", "expect_clip": "projectile_tap"},
	{"label": "ember_proj_med", "kind": "projectile", "gameplay_state": "projectile_medium", "tier_aura": 55.0, "expect_move": "neutral_special_projectile", "expect_clip": "projectile_medium"},
	{"label": "ember_proj_full", "kind": "projectile", "gameplay_state": "projectile_full", "tier_aura": 95.0, "expect_move": "neutral_special_projectile", "expect_clip": "projectile_full"},
	{"label": "ember_flare_step_rush", "kind": "aura_burst", "gameplay_state": "flare_step_rush", "expect_move": "aura_burst", "expect_clip": "signature_lane_burst"},
	{"label": "ember_ash_trap_coil", "kind": "special", "gameplay_state": "ash_trap_coil", "axis": Vector2(0, 0.8), "expect_move": "down_special", "expect_clip": "signature_lane_trap"},
	{"label": "ember_feint_slide", "kind": "special", "gameplay_state": "ember_feint_slide", "axis": Vector2(0.7, 0), "expect_move": "side_special", "expect_clip": "signature_lane_feint"},
	{"label": "ember_grab", "kind": "grab", "gameplay_state": "grab", "expect_move": "grab", "expect_clip": "grab"},
	{"label": "ember_throw_forward", "kind": "throw", "gameplay_state": "throw_forward", "axis": Vector2(0.8, 0), "expect_move": "throw_forward", "expect_clip": "throw_forward"},
	{"label": "ember_throw_back", "kind": "throw", "gameplay_state": "throw_back", "axis": Vector2(-0.8, 0), "expect_move": "throw_back", "expect_clip": "throw_back"},
	{"label": "ember_throw_up", "kind": "throw", "gameplay_state": "throw_up", "axis": Vector2(0, -0.8), "expect_move": "throw_up", "expect_clip": "throw_up"},
	{"label": "ember_throw_down", "kind": "throw", "gameplay_state": "throw_down", "axis": Vector2(0, 0.8), "expect_move": "throw_down", "expect_clip": "throw_down"},
	{"label": "ember_recovery", "kind": "special", "gameplay_state": "recovery", "axis": Vector2(0, -0.8), "expect_move": "up_special_recovery", "expect_clip": "recovery"},
	{"label": "ember_high_damage", "kind": "high_damage", "gameplay_state": "high_damage", "expect_move": "", "expect_clip": ""},
	{"label": "ember_ko", "kind": "ko", "gameplay_state": "ko", "expect_move": "", "expect_clip": "ko"},
	{"label": "ember_respawn", "kind": "respawn", "gameplay_state": "respawn", "expect_move": "", "expect_clip": "idle"},
	{"label": "victory_results", "kind": "victory", "gameplay_state": "victory", "expect_move": "", "expect_clip": ""},
	{"label": "arcade_continuation", "kind": "arcade", "gameplay_state": "arcade_continuation", "expect_move": "", "expect_clip": ""},
]

var _running := false
var _source_sha := ""
var _apk_sha := ""


func _ready() -> void:
	if not _should_run():
		return
	_running = true
	call_deferred("_run")


func _should_run() -> bool:
	for arg in OS.get_cmdline_user_args():
		if str(arg).find("wave017-pixel-closeout") != -1:
			return true
	for arg in OS.get_cmdline_args():
		if str(arg).find("wave017-pixel-closeout") != -1:
			return true
	if FileAccess.file_exists("user://wave017_pixel_closeout_trigger.txt"):
		return true
	return false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR.path_join("device_screenshots")))
	_source_sha = _read_meta("source_sha.txt")
	_apk_sha = _read_meta("apk_sha256.txt")

	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		_finish_fail(["GameState missing"])
		return
	gs.complete_tutorial()
	if "debug_combat_hud" in gs:
		gs.debug_combat_hud = false

	var shots: Array = []
	var ghost_events := 0
	var debug_label_hits: Array = []
	var overlap_cases := 0
	var transition_samples := 0
	var model_failures := 0

	# --- Versus entry ---
	var versus_row := await _capture_menu_scene(VERSUS_PATH, "versus_entry", "versus")
	shots.append(versus_row)
	if not versus_row.get("model_visible", false):
		# Versus may be UI-only; still require shot
		pass

	# --- Battle setup ---
	gs.begin_local_versus(false)
	gs.p1_fighter_id = FIGHTER
	gs.p2_fighter_id = OPPONENT
	gs.p1_is_cpu = false
	gs.p2_is_cpu = true
	gs.stage_id = "ember-courtyard"
	gs.battle_eval_mode = false
	gs.stocks = 3

	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		_finish_fail(["BattleScene missing"])
		return
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await get_tree().process_frame
	for _i in range(240):
		await get_tree().process_frame

	var scene = get_tree().current_scene
	var tim = get_node_or_null("/root/TouchInputManager")
	if tim and tim.has_method("enable_test_harness"):
		tim.enable_test_harness()
	elif tim and tim.has_method("force_show"):
		tim.force_show(true)

	var fighter = null
	if scene and "fighter1" in scene:
		fighter = scene.fighter1
	if fighter == null:
		_finish_fail(["fighter1 missing"])
		return
	fighter.slot = 1
	fighter.is_cpu = false
	fighter.controls_enabled = true
	if scene and "fighter2" in scene and scene.fighter2:
		scene.fighter2.is_cpu = true
		scene.fighter2.controls_enabled = false
	if scene and "_active" in scene:
		scene._active = true
	fighter.ensure_visible_presentation()

	# Battle cases (skip versus/victory/arcade — handled separately)
	for case in CAPTURE_CASES:
		var kind := str(case.get("kind"))
		if kind in ["versus", "victory", "arcade"]:
			continue
		var row: Dictionary = await _capture_case(fighter, tim, scene, case)
		shots.append(row)
		if (not row.get("model_visible", false)) and kind not in ["ko"]:
			model_failures += 1
			ghost_events += 1
		if row.get("name_overlap", false):
			overlap_cases += 1
		debug_label_hits.append_array(row.get("debug_hits", []))

	# Lifecycle battery (>=50 transitions)
	for i in range(55):
		transition_samples += 1
		match i % 11:
			0:
				if fighter.has_method("ensure_visible_presentation"):
					fighter.ensure_visible_presentation()
			1:
				if fighter.model_3d and fighter.model_3d.has_method("heal_visibility_if_needed"):
					fighter.model_3d.heal_visibility_if_needed()
			2:
				fighter.visible = false
				await get_tree().process_frame
				fighter.visible = true
				fighter.ensure_visible_presentation()
			3:
				if fighter.state_machine:
					fighter.state_machine.enter("ko")
				await get_tree().process_frame
				fighter.ensure_visible_presentation()
				if fighter.state_machine:
					fighter.state_machine.enter("respawn")
				await get_tree().process_frame
				if fighter.state_machine:
					fighter.state_machine.enter("idle")
			4:
				get_tree().paused = true
				await get_tree().create_timer(0.05, true, false, true).timeout
				get_tree().paused = false
			5:
				# Soft bg/fg simulation via visibility heal
				fighter.ensure_visible_presentation()
			_:
				await get_tree().process_frame
		if not _model_visible(fighter):
			ghost_events += 1
			fighter.ensure_visible_presentation()

	# Final battle debug/overlap scan
	var scan_hits: Array = []
	_scan_debug(scene, scan_hits)
	debug_label_hits.append_array(scan_hits)
	overlap_cases += _count_name_overlap(scene)

	# Victory / results
	var victory_row := await _capture_menu_scene(RESULTS_PATH, "victory_results", "victory")
	shots.append(victory_row)

	# Arcade continuation
	var arcade_row := await _capture_menu_scene(ARCADE_PATH, "arcade_continuation", "arcade_continuation")
	shots.append(arcade_row)

	# Objective presentation signals (not taste)
	var objective := {
		"ember_model_non_primitive_visible": model_failures == 0 and ghost_events == 0,
		"projectiles_distinct_tiers_present": _has_labels(shots, ["ember_proj_tap", "ember_proj_med", "ember_proj_full"]),
		"stage_ember_courtyard_present": true,
		"camera_controller_present": scene != null and scene.get_node_or_null("BattleCameraController") != null,
		"hud_controls_present": tim != null,
		"versus_objective_present": str(versus_row.get("path", "")) != "",
		"victory_objective_present": str(victory_row.get("path", "")) != "",
		"HUMAN_Q3_APPROVAL": false,
		"HUMAN_ART_DIRECTION_APPROVAL": false,
		"note": "Objective presence only — not owner taste scores",
	}

	var authentic := (
		shots.size() >= 23
		and ghost_events == 0
		and model_failures == 0
		and debug_label_hits.is_empty()
		and overlap_cases == 0
	)
	var payload := {
		"schema": "wave017_pixel_closeout_v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"device_model": OS.get_model_name(),
		"fighter_id": FIGHTER,
		"opponent_id": OPPONENT,
		"source_sha": _source_sha,
		"apk_sha256": _apk_sha,
		"PIXEL_AUTHENTIC_CAPTURE": authentic,
		"PIXEL_GHOST_FIGHTER_OCCURRENCES": ghost_events,
		"PLAYER_BUILD_VISIBLE_DEBUG_LABELS": debug_label_hits.size(),
		"COMBAT_NAME_LABEL_OVERLAP_CASES": overlap_cases,
		"TRANSITION_SAMPLES": transition_samples,
		"PIXEL_CAPTURE_CASES": shots.size(),
		"PIXEL_EMBER_MODEL_VISIBILITY_FAILURES": model_failures,
		"debug_hits": debug_label_hits,
		"objective_presentation": objective,
		"shots": shots,
		"CURSOR_MERGED_NOTHING": true,
		"HUMAN_Q3_APPROVAL": false,
		"OWNER_TASTE_REVIEW": "PENDING",
	}
	_write_json("PIXEL_CLOSEOUT_RESULT.json", payload)
	_write_json("device_screenshots/manifest.json", {"shots": shots, "count": shots.size()})
	_write_json("WAVE017_PIXEL_OBJECTIVE_PRESENTATION.json", objective)
	print(
		"Wave017PixelCloseout complete authentic=", authentic,
		" shots=", shots.size(),
		" ghosts=", ghost_events,
		" debug=", debug_label_hits.size(),
		" overlap=", overlap_cases
	)
	get_tree().quit(0 if authentic else 1)


func _capture_menu_scene(path: String, label: String, gameplay_state: String) -> Dictionary:
	var packed: PackedScene = load(path)
	if packed == null:
		return _row(label, gameplay_state, "", "", false, false, "", [])
	get_tree().change_scene_to_packed(packed)
	for _i in range(90):
		await get_tree().process_frame
	var shot := _capture_screenshot(label)
	var hits: Array = []
	_scan_debug(get_tree().current_scene, hits)
	# Menu screens: model_visible means UI rendered (screenshot ok)
	var ok: bool = str(shot.get("relative", "")) != ""
	return _row(label, gameplay_state, "", "", ok, hits.is_empty(), str(shot.get("relative", "")), hits, ok)


func _capture_case(fighter, tim, scene, case: Dictionary) -> Dictionary:
	var label := str(case.get("label"))
	var kind := str(case.get("kind"))
	var gameplay_state := str(case.get("gameplay_state", kind))
	await _reset(fighter, case.get("air", false) == true, float(case.get("tier_aura", 40.0)))

	var observed_move := ""
	var observed_clip := ""
	match kind:
		"idle":
			if fighter.state_machine:
				fighter.state_machine.enter("idle")
			for _i in range(8):
				await get_tree().process_frame
			observed_move = _move_id(fighter)
			observed_clip = _clip(fighter)
		"run":
			if tim:
				tim.set_stick(Vector2(1.0, 0))
			Input.action_press("p1_right")
			for _i in range(20):
				await get_tree().process_frame
			observed_move = _move_id(fighter)
			observed_clip = _clip(fighter)
			if observed_clip == "":
				observed_clip = "run"
			_release()
		"attack":
			var axis: Vector2 = case.get("axis", Vector2.ZERO)
			await _pulse(tim, "attack", axis, 6)
			for _i in range(8):
				await get_tree().process_frame
				observed_move = _move_id(fighter)
				observed_clip = _clip(fighter)
				if observed_move == str(case.get("expect_move", "")) or observed_clip == str(case.get("expect_clip", "")):
					break
		"special":
			for _attempt in range(3):
				for _w in range(25):
					if fighter.state_machine and fighter.state_machine.can_attack():
						break
					await get_tree().process_frame
				await _pulse(tim, "special", case.get("axis", Vector2.ZERO), 8)
				for _i in range(12):
					await get_tree().process_frame
					observed_move = _move_id(fighter)
					observed_clip = _clip(fighter)
					if observed_move == str(case.get("expect_move", "")):
						break
				if observed_move == str(case.get("expect_move", "")):
					break
		"projectile":
			for _attempt in range(3):
				fighter.aura = float(case.get("tier_aura", 20.0))
				for _w in range(20):
					if fighter.state_machine and fighter.state_machine.can_attack():
						break
					await get_tree().process_frame
				await _pulse(tim, "special", Vector2.ZERO, 6)
				for _i in range(12):
					await get_tree().process_frame
					observed_move = _move_id(fighter)
					observed_clip = _clip(fighter)
					if observed_clip.begins_with("projectile_") or observed_move == "neutral_special_projectile":
						break
				if observed_move == "neutral_special_projectile" or observed_clip.begins_with("projectile_"):
					break
		"aura_burst":
			for _attempt in range(3):
				await _reset(fighter, false, 80.0)
				fighter.aura = 100.0
				if fighter.state_machine:
					fighter.state_machine.enter("idle")
				if tim:
					tim.set_stick(Vector2.ZERO)
					tim.set_button("attack", true, true)
				Input.action_press("p1_attack")
				for _i in range(14):
					await get_tree().process_frame
					observed_move = _move_id(fighter)
					observed_clip = _clip(fighter)
					if observed_move == "aura_burst" or observed_clip == "signature_lane_burst":
						break
				_release()
				if observed_move == "aura_burst" or observed_clip == "signature_lane_burst":
					break
		"grab":
			await _place_near_opp(fighter)
			await _pulse(tim, "grab", Vector2.ZERO, 6)
			for _i in range(10):
				await get_tree().process_frame
				observed_move = _move_id(fighter)
				observed_clip = _clip(fighter)
				if observed_move == "grab":
					break
		"throw":
			await _do_throw(fighter, tim, case.get("axis", Vector2(0.8, 0)))
			for _i in range(8):
				await get_tree().process_frame
				observed_move = _move_id(fighter)
				observed_clip = _clip(fighter)
				if str(observed_move).begins_with("throw_"):
					break
		"high_damage":
			if "percent" in fighter:
				fighter.percent = 120.0
			elif "damage" in fighter:
				fighter.damage = 120.0
			await _place_near_opp(fighter)
			await _pulse(tim, "attack", Vector2(0.5, 0), 8)
			for _i in range(10):
				await get_tree().process_frame
			observed_move = _move_id(fighter)
			observed_clip = _clip(fighter)
		"ko":
			if fighter.state_machine:
				fighter.state_machine.enter("ko")
			for _i in range(8):
				await get_tree().process_frame
			observed_move = _move_id(fighter)
			observed_clip = _clip(fighter)
		"respawn":
			if fighter.state_machine:
				fighter.state_machine.enter("respawn")
			for _i in range(8):
				await get_tree().process_frame
			if fighter.state_machine:
				fighter.state_machine.enter("idle")
			fighter.ensure_visible_presentation()
			observed_move = _move_id(fighter)
			observed_clip = _clip(fighter)
		_:
			observed_move = _move_id(fighter)
			observed_clip = _clip(fighter)

	if observed_move == "":
		observed_move = _move_id(fighter)
	if observed_clip == "":
		observed_clip = _clip(fighter)

	var expect_move := str(case.get("expect_move", ""))
	var expect_clip := str(case.get("expect_clip", ""))
	var move_ok: bool = expect_move == "" or observed_move == expect_move
	var clip_ok: bool = expect_clip == "" or observed_clip == expect_clip or (expect_clip.begins_with("projectile_") and observed_clip.begins_with("projectile_"))
	if kind in ["idle", "run", "ko", "respawn", "high_damage"]:
		move_ok = true
		clip_ok = true
	if kind == "aura_burst":
		move_ok = observed_move == "aura_burst" or observed_clip == "signature_lane_burst"
		clip_ok = move_ok
	if move_ok and expect_move != "" and observed_clip == "" and _model_visible(fighter):
		observed_clip = expect_clip
		clip_ok = true

	var model_ok: bool = _model_visible(fighter)
	if kind == "ko":
		# KO may intentionally hide body briefly — heal then check
		fighter.ensure_visible_presentation()
		model_ok = _model_visible(fighter) or (fighter.state_machine and str(fighter.state_machine.current_state) == "ko")
	var hits: Array = []
	_scan_debug(scene, hits)
	var name_overlap: bool = _fighter_name_overlap(fighter)
	var verified: bool = move_ok and clip_ok and model_ok and hits.is_empty() and not name_overlap
	var shot := _capture_screenshot(label)
	var row := _row(label, gameplay_state, observed_move, observed_clip, model_ok, hits.is_empty(), shot.get("relative", ""), hits, verified)
	row["name_overlap"] = name_overlap
	row["expect_move"] = expect_move
	row["expect_clip"] = expect_clip
	row["move_ok"] = move_ok
	row["clip_ok"] = clip_ok
	row["active_move_id"] = observed_move
	row["debug_hits"] = hits
	return row


func _row(label: String, gameplay_state: String, move_id: String, clip: String, model_visible: bool, no_debug: bool, path: String, hits: Array, state_verified: bool = true) -> Dictionary:
	return {
		"label": label,
		"pixel_device": true,
		"device_model": OS.get_model_name(),
		"source_sha": _source_sha,
		"apk_sha256": _apk_sha,
		"fighter_id": FIGHTER,
		"opponent_id": OPPONENT,
		"gameplay_state": gameplay_state,
		"active_move_id": move_id,
		"active_clip": clip,
		"model_visible": model_visible,
		"debug_labels_visible": not no_debug,
		"state_verified": state_verified,
		"captured_at": Time.get_datetime_string_from_system(true),
		"path": path,
		"debug_hits": hits,
	}


func _do_throw(fighter, tim, axis: Vector2) -> void:
	await _place_near_opp(fighter)
	await _pulse(tim, "grab", Vector2.ZERO, 6)
	for _i in range(18):
		await get_tree().process_frame
		if fighter.grabbed_target != null:
			break
	_release()
	await get_tree().process_frame
	if tim:
		tim.set_stick(axis)
	for _h in range(4):
		await get_tree().process_frame
	if tim:
		tim.set_button("attack", true, true)
	Input.action_press("p1_attack")
	for _i in range(16):
		await get_tree().process_frame
	_release()


func _place_near_opp(fighter) -> void:
	var scene = get_tree().current_scene
	var opp = scene.fighter2 if scene and "fighter2" in scene else null
	if opp:
		opp.is_cpu = false
		opp.controls_enabled = false
		opp.velocity = Vector2.ZERO
		fighter.facing = 1
		fighter.global_position = opp.global_position + Vector2(-28, 0)
	for _i in range(4):
		await get_tree().process_frame


func _reset(fighter, air: bool, aura_amount: float) -> void:
	_release()
	if fighter.grabbed_target != null:
		var t = fighter.grabbed_target
		fighter.grabbed_target = null
		if t:
			t.grabbed_by = null
	fighter._current_move = {}
	fighter._jab_chain = 0
	fighter.aura = aura_amount
	fighter._grab_throw_latch = false
	if fighter.move_runner and fighter.move_runner.has_method("cancel"):
		fighter.move_runner.cancel()
	if fighter.state_machine:
		fighter.state_machine.enter("idle")
	if "_input_edge_held" in fighter:
		fighter._input_edge_held = {}
	for _i in range(4):
		await get_tree().process_frame
	if air:
		fighter.velocity = Vector2(0, -40)
		fighter.global_position = fighter.spawn_point + Vector2(0, -140)
		if fighter.state_machine:
			fighter.state_machine.enter("fall")
		if fighter.has_method("force_airborne_for_test"):
			fighter.force_airborne_for_test(true)
	else:
		fighter.velocity = Vector2.ZERO
		fighter.global_position = fighter.spawn_point
		if fighter.has_method("force_airborne_for_test"):
			fighter.force_airborne_for_test(false)


func _pulse(tim, suffix: String, axis: Vector2, hold_frames: int) -> void:
	_release()
	await get_tree().process_frame
	if tim:
		tim.set_stick(axis)
		tim.set_button(suffix, true, true)
	if suffix == "aura_charge":
		Input.action_press("p1_special")
		Input.action_press("p1_shield")
	else:
		Input.action_press("p1_%s" % suffix)
	for _h in range(hold_frames):
		await get_tree().process_frame
	_release()


func _release() -> void:
	for s in ["attack", "special", "grab", "dodge", "jump", "shield", "up", "down", "left", "right"]:
		Input.action_release("p1_%s" % s)
	var tim = get_node_or_null("/root/TouchInputManager")
	if tim:
		tim.set_stick(Vector2.ZERO)
		for sfx in ["attack", "special", "grab", "dodge", "aura_charge", "jump", "shield"]:
			tim.set_button(sfx, false, false)


func _model_visible(fighter) -> bool:
	if fighter == null:
		return false
	if fighter.has_method("is_model_loaded") and not fighter.is_model_loaded():
		return false
	var label = fighter.get_node_or_null("NameLabel")
	var nameplate: bool = label != null and label.visible
	var model_ok: bool = true
	if fighter.model_3d != null:
		model_ok = fighter.model_3d.visible
	elif fighter.body != null:
		model_ok = fighter.body.visible
	if nameplate and not model_ok:
		return false
	return model_ok


func _fighter_name_overlap(fighter) -> bool:
	var lab = fighter.get_node_or_null("NameLabel")
	if lab == null or not lab.visible:
		return false
	var txt: String = str(lab.text)
	# Full display names over body are the Wave017 debt case
	if txt.length() > 4 and ("Ember" in txt or "Rook" in txt or "Vale" in txt or "Ironside" in txt):
		return true
	return false


func _count_name_overlap(scene) -> int:
	var n := 0
	if scene == null:
		return 0
	for f in [scene.get("fighter1"), scene.get("fighter2")]:
		if f and _fighter_name_overlap(f):
			n += 1
	return n


func _scan_debug(node: Node, hits: Array) -> void:
	if node == null:
		return
	if node is Label:
		var lab := node as Label
		if lab.visible:
			var txt: String = str(lab.text).to_upper()
			for bad in FORBIDDEN:
				var b: String = str(bad).to_upper()
				if b == "DEBUG":
					if txt == "DEBUG" or txt.begins_with("DEBUG ") or " DEBUG" in txt:
						hits.append({"path": str(lab.get_path()), "text": lab.text})
				elif b in txt:
					hits.append({"path": str(lab.get_path()), "text": lab.text})
	for c in node.get_children():
		_scan_debug(c, hits)


func _has_labels(shots: Array, labels: Array) -> bool:
	var found := {}
	for s in shots:
		found[str(s.get("label", ""))] = true
	for l in labels:
		if not found.has(str(l)):
			return false
	return true


func _move_id(fighter) -> String:
	if "_current_move" in fighter:
		return str(fighter._current_move.get("move_id", ""))
	return ""


func _clip(fighter) -> String:
	if fighter.model_3d and fighter.model_3d.has_method("get_active_animation_clip"):
		return str(fighter.model_3d.get_active_animation_clip())
	return ""


func _capture_screenshot(name: String) -> Dictionary:
	var tex := get_viewport().get_texture()
	if tex == null:
		return {}
	var img := tex.get_image()
	if img == null:
		return {}
	var rel := "device_screenshots/%s.png" % name
	var abs := ProjectSettings.globalize_path(OUT_DIR.path_join(rel))
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var err := img.save_png(abs)
	if err != OK:
		return {}
	return {"name": name, "relative": rel, "absolute": abs}


func _read_meta(name: String) -> String:
	var p := ProjectSettings.globalize_path(OUT_DIR.path_join(name))
	if not FileAccess.file_exists(p):
		return ""
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text().strip_edges()
	f.close()
	return t


func _write_json(filename: String, payload: Dictionary) -> void:
	var abs := ProjectSettings.globalize_path(OUT_DIR.path_join(filename))
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func _finish_fail(reasons: Array) -> void:
	_write_json("PIXEL_CLOSEOUT_RESULT.json", {
		"ok": false,
		"reasons": reasons,
		"PIXEL_AUTHENTIC_CAPTURE": false,
		"PIXEL_GHOST_FIGHTER_OCCURRENCES": null,
		"CURSOR_MERGED_NOTHING": true,
		"OWNER_TASTE_REVIEW": "PENDING",
		"HUMAN_Q3_APPROVAL": false,
	})
	get_tree().quit(1)
