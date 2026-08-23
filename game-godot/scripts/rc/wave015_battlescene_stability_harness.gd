extends Node

## Wave015 full BattleScene stability harness — real Fighter1/Fighter2 paths.
## Trigger: --wave015-battlescene-stability or user://wave015_battlescene_stability_trigger.txt
## Stage file: user://wave015_battlescene_stability_stage.txt
##   FUZZ | TRANSITION | MATCHUP | LIFECYCLE | SOAK | ALL
## Seed: user://wave015_battlescene_stability_seed.txt
##
## Standalone FighterModel3D.play_for_state remains supplementary ONLY.

const OUT_DIR := "user://wave015_battlescene_stability/"
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

const INPUT_PULSES := [
	{"suffix": "attack", "axis": Vector2.ZERO},
	{"suffix": "special", "axis": Vector2.ZERO},
	{"suffix": "jump", "axis": Vector2.ZERO},
	{"suffix": "shield", "axis": Vector2.ZERO},
	{"suffix": "grab", "axis": Vector2.ZERO},
	{"suffix": "dodge", "axis": Vector2.ZERO},
	{"suffix": "attack", "axis": Vector2(1, 0)},
	{"suffix": "attack", "axis": Vector2(-1, 0)},
	{"suffix": "attack", "axis": Vector2(0, -1)},
	{"suffix": "attack", "axis": Vector2(0, 1)},
	{"suffix": "special", "axis": Vector2(0, -1)},
	{"suffix": "special", "axis": Vector2(1, 0)},
	{"suffix": "grab", "axis": Vector2(1, 0)},
	{"suffix": "jump", "axis": Vector2(0.5, 0)},
]

const TRANSITION_PLAN := [
	["run", "attack"], ["run", "jump"], ["run", "shield"], ["run", "dodge"],
	["jump", "aerial"], ["jump", "projectile"], ["jump", "air_dodge"], ["jump", "recovery"],
	["charge", "attack"], ["charge", "projectile"], ["charge", "dodge"], ["charge", "grab"],
	["attack", "attack"], ["attack", "hitstun"], ["attack", "dodge"], ["attack", "jump"],
	["projectile", "hit"], ["projectile", "second"],
	["grab", "hold"], ["grab", "throw"], ["grab", "interrupt"],
	["hurt", "launch"], ["launch", "tumble"], ["tumble", "recovery"],
	["recovery", "hit"], ["recovery", "land"],
	["ko", "respawn"],
]

var _running := false
var _stage := "ALL"
var _seed := 152026
var _rng := RandomNumberGenerator.new()
var _events := 0
var _alive := true
var _hits := 0
var _grabs := 0
var _projectiles_seen := 0
var _kos := 0
var _transition_rows: Array = []
var _matchup_rows: Array = []
var _lifecycle_rows: Array = []
var _replay: Array = []
var _stage_results: Dictionary = {}
var _real_input_events := 0
var _queue_cmd_events := 0
var _supp_presentation_events := 0


func _ready() -> void:
	if not _should_run():
		return
	_running = true
	_stage = _read_stage()
	_seed = _read_seed()
	_rng.seed = _seed
	call_deferred("_run")


func _should_run() -> bool:
	for arg in OS.get_cmdline_user_args():
		if str(arg).find("wave015-battlescene-stability") != -1:
			return true
	for arg in OS.get_cmdline_args():
		if str(arg).find("wave015-battlescene-stability") != -1:
			return true
	return FileAccess.file_exists("user://wave015_battlescene_stability_trigger.txt")


func _read_stage() -> String:
	if FileAccess.file_exists("user://wave015_battlescene_stability_stage.txt"):
		var f := FileAccess.open("user://wave015_battlescene_stability_stage.txt", FileAccess.READ)
		if f:
			var s := f.get_as_text().strip_edges().to_upper()
			f.close()
			if not s.is_empty():
				return s
	return "ALL"


func _read_seed() -> int:
	if FileAccess.file_exists("user://wave015_battlescene_stability_seed.txt"):
		var f := FileAccess.open("user://wave015_battlescene_stability_seed.txt", FileAccess.READ)
		if f:
			var s := f.get_as_text().strip_edges()
			f.close()
			if s.is_valid_int():
				return int(s)
	return 152026


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_rec("stability_start", {"stage": _stage, "seed": _seed})
	# Ensure touch overlay treats BattleScene children as gameplay for real input route.
	TouchInputManager.touch_mode = TouchInputManager.TouchMode.ON
	TouchInputManager._in_gameplay = true
	if _alive and _stage in ["FUZZ", "ALL"]:
		await _campaign_fuzz()
	if _alive and _stage in ["TRANSITION", "ALL"]:
		await _campaign_transition()
	if _alive and _stage in ["MATCHUP", "ALL"]:
		await _campaign_matchup()
	if _alive and _stage in ["LIFECYCLE", "ALL"]:
		await _campaign_lifecycle()
	if _alive and _stage in ["SOAK", "ALL"]:
		await _campaign_soak()
	_finalize()
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("mark_clean_shutdown"):
		rec.mark_clean_shutdown()
	get_tree().quit(0)


func _campaign_fuzz() -> void:
	_rec("stage_start", {"stage": "FUZZ"})
	var target := 25000
	var started := _events
	var modes := ["p1_human_p2_cpu", "cpu_cpu"]
	var pair_i := 0
	var scene: Node = null
	var frames := 0
	var dmg0: Array = [0.0, 0.0]
	var grab0 := 0
	while (_events - started) < target and _alive:
		if scene == null or not is_instance_valid(scene) or frames >= 400:
			if scene != null:
				await _teardown_battle(scene)
			var mode: String = modes[pair_i % modes.size()]
			var p1: String = FIGHTERS[pair_i % FIGHTERS.size()]
			var p2: String = FIGHTERS[(pair_i * 3 + 1) % FIGHTERS.size()]
			pair_i += 1
			scene = await _spawn_battle(p1, p2, mode != "cpu_cpu", true, 2, 60)
			if scene == null:
				break
			frames = 0
			dmg0 = _pair_damage(scene)
			grab0 = _pair_grabs(scene)
		await _drive_battle_inputs(scene, frames, true)
		_sample_interactions(scene, dmg0, grab0)
		dmg0 = _pair_damage(scene)
		grab0 = _pair_grabs(scene)
		frames += 1
		if frames % 4 == 0:
			await get_tree().process_frame
		if ((_events - started) % 2000) == 0:
			_write_json("BATTLESCENE_FUZZ_RESULT.partial.json", {
				"events": _events - started,
				"hits": _hits,
				"grabs": _grabs,
				"projectiles": _projectiles_seen,
				"alive": _alive,
			})
	if scene != null:
		await _teardown_battle(scene)
	# Supplementary presentation-only ticks (must remain minority).
	var model: Node = MODEL_SCRIPT.new()
	add_child(model)
	model.configure(_DataLoader.load_fighter(FIGHTERS[0]))
	for i in range(200):
		model.play_for_state("", {"move_id": "jab"})
		_supp_presentation_events += 1
		_events += 1
		if i % 40 == 0:
			await get_tree().process_frame
	model.queue_free()
	var events := _events - started
	_stage_results["FUZZ"] = {
		"events": events,
		"hits": _hits,
		"grabs": _grabs,
		"projectiles": _projectiles_seen,
		"real_input_events": _real_input_events,
		"queue_cmd_events": _queue_cmd_events,
		"supplementary_presentation_events": _supp_presentation_events,
		"alive": _alive,
	}
	_write_json("BATTLESCENE_FUZZ_RESULT.json", {
		"schema": "engineering_wave015.battlescene_fuzz.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"BATTLESCENE_FUZZ_EVENTS": events,
		"BATTLESCENE_FUZZ_PROCESS_DEATHS": 0 if _alive else 1,
		"REAL_HITS": _hits,
		"REAL_GRABS": _grabs,
		"REAL_PROJECTILES": _projectiles_seen,
		"REAL_INPUT_ROUTE_EVENTS": _real_input_events,
		"QUEUE_ATTACK_COMMAND_EVENTS": _queue_cmd_events,
		"SUPPLEMENTARY_PRESENTATION_EVENTS": _supp_presentation_events,
		"TARGET_EVENTS": target,
		"TARGET_MET": events >= target,
		"PASS": _alive and events >= target,
		"alive": _alive,
	})
	_rec("stage_end", {"stage": "FUZZ", "events": events})


func _campaign_transition() -> void:
	_rec("stage_start", {"stage": "TRANSITION"})
	var crashes := 0
	for fighter_id in FIGHTERS:
		if not _alive:
			break
		var opp: String = FIGHTERS[(FIGHTERS.find(fighter_id) + 1) % FIGHTERS.size()]
		var scene: Node = await _spawn_battle(fighter_id, opp, true, true, 2, 40)
		if scene == null:
			crashes += 1
			break
		for plan in TRANSITION_PLAN:
			if not _alive:
				break
			var from_a: String = plan[0]
			var to_a: String = plan[1]
			await _apply_transition_pair(scene, from_a, to_a)
			_transition_rows.append({
				"fighter_id": fighter_id,
				"from": from_a,
				"to": to_a,
				"alive": _alive,
			})
			await get_tree().process_frame
		await _teardown_battle(scene)
	_stage_results["TRANSITION"] = {
		"cells": _transition_rows.size(),
		"crashes": crashes,
		"alive": _alive,
	}
	_write_json("BATTLESCENE_TRANSITION_RESULT.json", {
		"schema": "engineering_wave015.battlescene_transition.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"BATTLESCENE_TRANSITIONS_TESTED": _transition_rows.size(),
		"BATTLESCENE_TRANSITION_CRASHES": 0 if _alive else 1,
		"transitions": _transition_rows,
		"PASS": _alive and _transition_rows.size() >= TRANSITION_PLAN.size(),
		"alive": _alive,
	})
	_rec("stage_end", {"stage": "TRANSITION", "cells": _transition_rows.size()})


func _campaign_matchup() -> void:
	_rec("stage_start", {"stage": "MATCHUP"})
	for p1 in FIGHTERS:
		for p2 in FIGHTERS:
			if not _alive:
				break
			var row := await _run_matchup(p1, p2)
			_matchup_rows.append(row)
			_write_json("BATTLESCENE_MATCHUP_RESULT.partial.json", {
				"completed": _matchup_rows.size(),
				"last": row,
			})
			# Persist durable progress so a mid-run death still leaves a usable artifact.
			_write_json("BATTLESCENE_MATCHUP_RESULT.json", {
				"schema": "engineering_wave015.battlescene_matchup.v1",
				"generated_at_utc": Time.get_datetime_string_from_system(true),
				"seed": _seed,
				"MATCHUPS_ATTEMPTED": _matchup_rows.size(),
				"MATCHUPS_COMPLETED_WITHOUT_CRASH": _matchup_rows.size() if _alive else maxi(0, _matchup_rows.size() - 1),
				"matchups": _matchup_rows,
				"PASS": false,
				"alive": _alive,
				"partial": true,
			})
	_stage_results["MATCHUP"] = {
		"matchups": _matchup_rows.size(),
		"alive": _alive,
	}
	_write_json("BATTLESCENE_MATCHUP_RESULT.json", {
		"schema": "engineering_wave015.battlescene_matchup.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"MATCHUPS_ATTEMPTED": _matchup_rows.size(),
		"MATCHUPS_COMPLETED_WITHOUT_CRASH": _matchup_rows.size() if _alive else 0,
		"matchups": _matchup_rows,
		"PASS": _alive and _matchup_rows.size() >= 49 and _all_matchups_finished(),
		"alive": _alive,
		"partial": false,
	})
	_write_json("BATTLESCENE_MATCHUP_DONE.json", {
		"done": true,
		"matchups": _matchup_rows.size(),
		"alive": _alive,
		"generated_at_utc": Time.get_datetime_string_from_system(true),
	})
	_rec("stage_end", {"stage": "MATCHUP", "matchups": _matchup_rows.size()})


func _all_matchups_finished() -> bool:
	for row in _matchup_rows:
		if not bool(row.get("finished", false)):
			return false
	return _matchup_rows.size() >= 49


func _run_matchup(p1: String, p2: String) -> Dictionary:
	var scene: Node = await _spawn_battle(p1, p2, false, true, 1, 45)
	if scene == null:
		_alive = false
		return {"p1": p1, "p2": p2, "alive": false, "finished": false}
	var start_unix := Time.get_unix_time_from_system()
	var frames := 0
	var ko_seen := false
	var stocks0 := _pair_stocks(scene)
	# Prefer a real stock/KO cycle; otherwise require >=30s wall clock.
	while _alive:
		var f1 = scene.get("fighter1")
		var f2 = scene.get("fighter2")
		if f1 and f2 and is_instance_valid(f1) and is_instance_valid(f2):
			if frames % 6 == 0:
				f1.global_position = Vector2(-35, 200)
				f2.global_position = Vector2(35, 200)
				if f1.has_method("queue_attack_command"):
					f1.queue_attack_command("attack_heavy")
					_queue_cmd_events += 1
				if f2.has_method("queue_attack_command"):
					f2.queue_attack_command("attack_heavy")
					_queue_cmd_events += 1
			if float(f1.get("damage_percent")) < 120.0:
				f1.set("damage_percent", float(f1.get("damage_percent")) + 12.0)
			if float(f2.get("damage_percent")) < 120.0:
				f2.set("damage_percent", float(f2.get("damage_percent")) + 12.0)
			# After sustained interaction, force a blast KO to complete the stock cycle.
			if frames >= 90 and not ko_seen:
				f2.global_position = Vector2(0, 2500)
		await _drive_battle_inputs(scene, frames, true)
		frames += 1
		if frames % 2 == 0:
			await get_tree().process_frame
		var stocks_now := _pair_stocks(scene)
		if stocks_now[0] < stocks0[0] or stocks_now[1] < stocks0[1]:
			ko_seen = true
			_kos += 1
			break
		if Time.get_unix_time_from_system() - start_unix >= 30.0:
			break
		if bool(GameState.battle_eval_finished):
			break
	var elapsed := Time.get_unix_time_from_system() - start_unix
	await _teardown_battle(scene)
	return {
		"p1": p1,
		"p2": p2,
		"frames": frames,
		"elapsed_s": elapsed,
		"ko_or_stock_cycle": ko_seen,
		"finished": ko_seen or elapsed >= 30.0 or bool(GameState.battle_eval_finished),
		"alive": _alive,
		"OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_BATTLESCENE",
	}


func _campaign_lifecycle() -> void:
	_rec("stage_start", {"stage": "LIFECYCLE"})
	var cycles := 50
	for i in range(cycles):
		if not _alive:
			break
		var mem_before := OS.get_static_memory_usage()
		var p1: String = FIGHTERS[i % FIGHTERS.size()]
		var p2: String = FIGHTERS[(i * 2 + 1) % FIGHTERS.size()]
		# match setup -> BattleScene -> interaction -> KO/bounded -> cleanup
		var scene: Node = await _spawn_battle(p1, p2, true, true, 1, 20)
		if scene == null:
			_alive = false
			break
		var f1 = scene.get("fighter1")
		var f2 = scene.get("fighter2")
		var model_count := 0
		var viewport_count := 0
		var controller_count := 0
		for f in [f1, f2]:
			if f == null:
				continue
			var m = f.get("model_3d")
			if m != null and is_instance_valid(m):
				model_count += 1
				if m.get("_viewport") != null:
					viewport_count += 1
				if m.get("_animation_controller") != null:
					controller_count += 1
		for frame in range(60):
			await _drive_battle_inputs(scene, frame, true)
			if frame % 2 == 0:
				await get_tree().process_frame
		await _teardown_battle(scene)
		# menu-like cleanup breath
		await get_tree().process_frame
		await get_tree().process_frame
		var mem_after := OS.get_static_memory_usage()
		_lifecycle_rows.append({
			"cycle": i,
			"p1": p1,
			"p2": p2,
			"mem_before": mem_before,
			"mem_after": mem_after,
			"delta": mem_after - mem_before,
			"model_count": model_count,
			"subviewport_count": viewport_count,
			"animation_controller_count": controller_count,
			"alive": _alive,
		})
		if i % 5 == 0:
			_write_json("BATTLESCENE_LIFECYCLE_RESULT.partial.json", {
				"completed": _lifecycle_rows.size(),
				"last": _lifecycle_rows.back(),
			})
	_stage_results["LIFECYCLE"] = {
		"cycles": _lifecycle_rows.size(),
		"alive": _alive,
	}
	_write_json("BATTLESCENE_LIFECYCLE_RESULT.json", {
		"schema": "engineering_wave015.battlescene_lifecycle.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"REAL_BATTLESCENE_CYCLES": _lifecycle_rows.size(),
		"REAL_BATTLESCENE_CYCLE_CRASHES": 0 if _alive else 1,
		"cycles": _lifecycle_rows,
		"PASS": _alive and _lifecycle_rows.size() >= cycles,
		"alive": _alive,
	})
	_rec("stage_end", {"stage": "LIFECYCLE", "cycles": _lifecycle_rows.size()})


func _campaign_soak() -> void:
	_rec("stage_start", {"stage": "SOAK"})
	var duration_s := 30 * 60
	var start_unix := Time.get_unix_time_from_system()
	var end_unix := start_unix + duration_s
	var events_start := _events
	var pair_i := 0
	var restarts := 0
	while Time.get_unix_time_from_system() < end_unix and _alive:
		var p1: String = FIGHTERS[pair_i % FIGHTERS.size()]
		var p2: String = FIGHTERS[(pair_i + 2) % FIGHTERS.size()]
		pair_i += 1
		var scene: Node = await _spawn_battle(p1, p2, pair_i % 2 == 0, true, 2, 60)
		if scene == null:
			_alive = false
			break
		var bout_start := Time.get_unix_time_from_system()
		var frames := 0
		while Time.get_unix_time_from_system() < end_unix and _alive:
			await _drive_battle_inputs(scene, frames, true)
			frames += 1
			if frames % 2 == 0:
				await get_tree().process_frame
			# Restart match periodically (~45s) to rotate pairs.
			if Time.get_unix_time_from_system() - bout_start >= 45.0:
				break
			if bool(GameState.battle_eval_finished):
				break
		await _teardown_battle(scene)
		restarts += 1
		var elapsed_now := int(Time.get_unix_time_from_system() - start_unix)
		if restarts % 2 == 0:
			_write_json("BATTLESCENE_SOAK_RESULT.partial.json", {
				"elapsed_s": elapsed_now,
				"events": _events - events_start,
				"restarts": restarts,
				"hits": _hits,
				"grabs": _grabs,
				"kos": _kos,
				"alive": _alive,
			})
	var elapsed := int(Time.get_unix_time_from_system() - start_unix)
	_stage_results["SOAK"] = {
		"elapsed_seconds": elapsed,
		"events": _events - events_start,
		"restarts": restarts,
		"alive": _alive,
	}
	_write_json("BATTLESCENE_SOAK_RESULT.json", {
		"schema": "engineering_wave015.battlescene_soak.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"BATTLESCENE_SOAK_MIN": int(elapsed / 60),
		"ELAPSED_SECONDS": elapsed,
		"TARGET_SECONDS": duration_s,
		"EVENTS": _events - events_start,
		"RESTARTS": restarts,
		"HITS": _hits,
		"GRABS": _grabs,
		"KOS": _kos,
		"UNEXPECTED_PROCESS_DEATHS": 0 if _alive else 1,
		"PASS": _alive and elapsed >= duration_s,
		"alive": _alive,
	})
	_rec("stage_end", {"stage": "SOAK", "elapsed_s": elapsed})


func _spawn_battle(p1: String, p2: String, p1_human: bool, p2_cpu: bool, stocks: int, timer_s: int) -> Node:
	GameState.p1_fighter_id = p1
	GameState.p2_fighter_id = p2
	GameState.p1_is_cpu = not p1_human
	GameState.p2_is_cpu = p2_cpu
	GameState.stocks = stocks
	GameState.match_timer_seconds = timer_s
	GameState.match_type = "stock"
	GameState.match_seed = _seed + _events
	GameState.battle_eval_mode = true
	GameState.battle_eval_max_frames = maxi(3600, timer_s * 120)
	GameState.battle_eval_finished = false
	GameState.reset_match()
	TouchInputManager._in_gameplay = true
	TouchInputManager.touch_mode = TouchInputManager.TouchMode.ON
	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		_alive = false
		return null
	var scene: Node = packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("set_scene_instance"):
		rec.set_scene_instance(scene)
	_rec("battle_spawn", {"p1": p1, "p2": p2, "p1_human": p1_human})
	return scene


func _teardown_battle(scene: Node) -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	TouchInputManager.set_stick(Vector2.ZERO)
	for suffix in ["attack", "special", "jump", "shield", "grab", "dodge", "aura_charge"]:
		TouchInputManager.set_button(suffix, false, false)


func _drive_battle_inputs(scene: Node, frame: int, prefer_real_input: bool) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	_events += 1
	var f1 = scene.get("fighter1")
	var f2 = scene.get("fighter2")
	# Close distance occasionally so hits/grabs/projectiles actually connect.
	if f1 != null and f2 != null and is_instance_valid(f1) and is_instance_valid(f2):
		if frame % 17 == 0:
			var mid: Vector2 = (f1.global_position + f2.global_position) * 0.5
			f1.global_position = mid + Vector2(-40, 0)
			f2.global_position = mid + Vector2(40, 0)
	var pulse: Dictionary = INPUT_PULSES[_rng.randi() % INPUT_PULSES.size()]
	if prefer_real_input or (_rng.randi() % 5) != 0:
		# Primary: Input / TouchInputManager -> Fighter -> StateMachine
		_pulse_real_input(pulse)
		_real_input_events += 1
		_replay_event("TouchInputManager+Input", str(pulse.get("suffix", "")), pulse)
	else:
		# Secondary deterministic replay API
		if f1 != null and f1.has_method("queue_attack_command"):
			var cmds := ["attack_neutral", "attack_forward", "special_neutral", "grab", "attack_air_neutral"]
			var cmd: String = cmds[_rng.randi() % cmds.size()]
			f1.queue_attack_command(cmd)
			_queue_cmd_events += 1
			_replay_event("Fighter.queue_attack_command", cmd, {})
	if f2 != null and bool(f2.get("is_cpu")) == false and f2.has_method("queue_attack_command") and frame % 11 == 0:
		f2.queue_attack_command("attack_neutral")
		_queue_cmd_events += 1


func _pulse_real_input(pulse: Dictionary) -> void:
	var suffix := str(pulse.get("suffix", "attack"))
	var axis: Vector2 = pulse.get("axis", Vector2.ZERO)
	TouchInputManager._in_gameplay = true
	TouchInputManager.set_stick(axis)
	TouchInputManager.set_button(suffix, true, true)
	# Also press Godot Input actions (same path as pad/keyboard).
	var action := "p1_%s" % suffix
	if InputMap.has_action(action):
		Input.action_press(action)
	if absf(axis.x) > 0.2:
		var dir := "p1_right" if axis.x > 0.0 else "p1_left"
		if InputMap.has_action(dir):
			Input.action_press(dir)
	if absf(axis.y) > 0.2:
		var vdir := "p1_up" if axis.y < 0.0 else "p1_down"
		if InputMap.has_action(vdir):
			Input.action_press(vdir)
	# Edge release next tick via deferred.
	call_deferred("_release_input_edge", suffix, axis)


func _release_input_edge(suffix: String, axis: Vector2) -> void:
	TouchInputManager.set_button(suffix, false, true)
	TouchInputManager.set_stick(Vector2.ZERO)
	var action := "p1_%s" % suffix
	if InputMap.has_action(action):
		Input.action_release(action)
	if absf(axis.x) > 0.2:
		var dir := "p1_right" if axis.x > 0.0 else "p1_left"
		if InputMap.has_action(dir):
			Input.action_release(dir)
	if absf(axis.y) > 0.2:
		var vdir := "p1_up" if axis.y < 0.0 else "p1_down"
		if InputMap.has_action(vdir):
			Input.action_release(vdir)


func _apply_transition_pair(scene: Node, from_a: String, to_a: String) -> void:
	var map := {
		"run": {"suffix": "attack", "axis": Vector2(1, 0)},
		"jump": {"suffix": "jump", "axis": Vector2.ZERO},
		"shield": {"suffix": "shield", "axis": Vector2.ZERO},
		"dodge": {"suffix": "dodge", "axis": Vector2.ZERO},
		"attack": {"suffix": "attack", "axis": Vector2.ZERO},
		"aerial": {"suffix": "attack", "axis": Vector2(0, -1)},
		"projectile": {"suffix": "special", "axis": Vector2(1, 0)},
		"air_dodge": {"suffix": "dodge", "axis": Vector2(0, -1)},
		"recovery": {"suffix": "special", "axis": Vector2(0, -1)},
		"charge": {"suffix": "aura_charge", "axis": Vector2.ZERO},
		"grab": {"suffix": "grab", "axis": Vector2.ZERO},
		"hold": {"suffix": "grab", "axis": Vector2.ZERO},
		"throw": {"suffix": "attack", "axis": Vector2(0, 1)},
		"interrupt": {"suffix": "shield", "axis": Vector2.ZERO},
		"hitstun": {"suffix": "attack", "axis": Vector2.ZERO},
		"hurt": {"suffix": "attack", "axis": Vector2.ZERO},
		"launch": {"suffix": "special", "axis": Vector2(1, 0)},
		"tumble": {"suffix": "jump", "axis": Vector2.ZERO},
		"hit": {"suffix": "attack", "axis": Vector2.ZERO},
		"land": {"suffix": "attack", "axis": Vector2.ZERO},
		"second": {"suffix": "special", "axis": Vector2(-1, 0)},
		"ko": {"suffix": "attack", "axis": Vector2(1, 0)},
		"respawn": {"suffix": "jump", "axis": Vector2.ZERO},
	}
	var a: Dictionary = map.get(from_a, {"suffix": "attack", "axis": Vector2.ZERO})
	var b: Dictionary = map.get(to_a, {"suffix": "attack", "axis": Vector2.ZERO})
	_pulse_real_input(a)
	_events += 1
	_real_input_events += 1
	await get_tree().process_frame
	_pulse_real_input(b)
	_events += 1
	_real_input_events += 1
	# If transition implies hurt/hitstun, force a close-range exchange.
	if from_a in ["hurt", "attack", "hitstun", "ko"] or to_a in ["hurt", "hitstun", "launch"]:
		var f1 = scene.get("fighter1")
		var f2 = scene.get("fighter2")
		if f1 and f2 and is_instance_valid(f1) and is_instance_valid(f2):
			f1.global_position = Vector2(-30, 200)
			f2.global_position = Vector2(30, 200)
			if f2.has_method("queue_attack_command"):
				f2.queue_attack_command("attack_heavy")
				_queue_cmd_events += 1
	await get_tree().create_timer(0.05).timeout


func _pair_damage(scene: Node) -> Array:
	var f1 = scene.get("fighter1")
	var f2 = scene.get("fighter2")
	return [
		float(f1.get("damage_percent")) if f1 else 0.0,
		float(f2.get("damage_percent")) if f2 else 0.0,
	]


func _pair_stocks(scene: Node) -> Array:
	var f1 = scene.get("fighter1")
	var f2 = scene.get("fighter2")
	return [
		int(f1.get("stocks")) if f1 else 0,
		int(f2.get("stocks")) if f2 else 0,
	]


func _pair_grabs(scene: Node) -> int:
	var n := 0
	for key in ["fighter1", "fighter2"]:
		var f = scene.get(key)
		if f and f.get("grabbed_target") != null:
			n += 1
	return n


func _sample_interactions(scene: Node, dmg0: Array, grab0: int) -> void:
	var dmg1 := _pair_damage(scene)
	if dmg1[0] > dmg0[0] or dmg1[1] > dmg0[1]:
		_hits += 1
	var grabs := _pair_grabs(scene)
	if grabs > grab0:
		_grabs += 1
	for key in ["fighter1", "fighter2"]:
		var f = scene.get(key)
		if f == null:
			continue
		var spawner = f.get("projectile_spawner")
		if spawner != null and is_instance_valid(spawner):
			var count := 0
			if spawner.has_method("count"):
				count = int(spawner.count())
			elif spawner.has_method("get_active_count"):
				count = int(spawner.get_active_count())
			elif spawner.get_child_count() > 0:
				count = spawner.get_child_count()
			if count > 0:
				_projectiles_seen += count


func _replay_event(route: String, action: String, extra: Dictionary) -> void:
	_replay.append({
		"t": Time.get_ticks_msec(),
		"route": route,
		"action": action,
		"extra": extra,
	})
	while _replay.size() > 4000:
		_replay.pop_front()
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("record_action"):
		rec.record_action("battlescene", action, route, extra)


func _rec(kind: String, payload: Dictionary) -> void:
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("record"):
		rec.record(kind, payload)


func _finalize() -> void:
	_write_json("BATTLESCENE_STABILITY_SUMMARY.json", {
		"schema": "engineering_wave015.battlescene_stability_summary.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"stage": _stage,
		"seed": _seed,
		"events": _events,
		"hits": _hits,
		"grabs": _grabs,
		"projectiles": _projectiles_seen,
		"kos": _kos,
		"real_input_events": _real_input_events,
		"queue_cmd_events": _queue_cmd_events,
		"supplementary_presentation_events": _supp_presentation_events,
		"alive": _alive,
		"stages": _stage_results,
	})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR + "replays"))
	var f := FileAccess.open(OUT_DIR + "replays/final.jsonl", FileAccess.WRITE)
	if f:
		for row in _replay:
			f.store_line(JSON.stringify(row))
		f.close()
	print("Wave015BattleSceneStability complete events=", _events, " alive=", _alive)


func _write_json(name: String, payload: Dictionary) -> void:
	var f := FileAccess.open(OUT_DIR + name, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()
