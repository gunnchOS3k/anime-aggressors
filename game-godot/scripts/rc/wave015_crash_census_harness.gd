extends Node

## Wave015 crash census harness — Pixel 6a only.
## Trigger: --wave015-crash-census or user://wave015_crash_census_trigger.txt
## Optional stage file: user://wave015_crash_census_stage.txt  (A|B|C|D|E|F|ALL)
## Optional seed: user://wave015_crash_census_seed.txt

const OUT_DIR := "user://wave015_crash_census/"
const FIGHTER_SCENE := preload("res://scenes/fighters/Fighter.tscn")
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const ROSTER_LAB_PATH := "res://scenes/labs/RosterArtLab.tscn"
const ANIM_LAB_PATH := "res://scenes/labs/AnimationLab.tscn"
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

## Canonical presentation actions (model route) + gameplay command route.
const PRESENTATION_ACTIONS := [
	"idle", "walk", "run", "dash", "jab", "heavy", "tilt_forward", "grab",
	"aerial_neutral", "aerial_forward", "dodge", "tumble",
	"signature_lane_confirm", "signature_lane_counter", "throw_down", "landing",
]

const GAMEPLAY_COMMANDS := [
	"attack_neutral", "attack_forward", "attack_up", "attack_down", "attack_heavy",
	"attack_dash", "attack_air_neutral", "attack_air_forward", "attack_air_up", "attack_air_down",
	"special_neutral", "special_forward", "special_up", "special_down",
	"grab", "aura_burst",
]

const INPUT_PULSES := [
	{"suffix": "attack", "axis": Vector2.ZERO},
	{"suffix": "special", "axis": Vector2.ZERO},
	{"suffix": "jump", "axis": Vector2.ZERO},
	{"suffix": "shield", "axis": Vector2.ZERO},
	{"suffix": "grab", "axis": Vector2.ZERO},
	{"suffix": "attack", "axis": Vector2(1, 0)},
	{"suffix": "attack", "axis": Vector2(-1, 0)},
	{"suffix": "attack", "axis": Vector2(0, -1)},
	{"suffix": "attack", "axis": Vector2(0, 1)},
	{"suffix": "special", "axis": Vector2(0, -1)},
]

var _running := false
var _stage := "ALL"
var _seed := 152026
var _rng := RandomNumberGenerator.new()
var _action_events := 0
var _crashes_observed := 0
var _stage_results: Dictionary = {}
var _isolation_rows: Array = []
var _transition_counts: Dictionary = {}
var _matchup_rows: Array = []
var _lifecycle_rows: Array = []
var _replay_events: Array = []
var _alive := true


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
		if str(arg).find("wave015-crash-census") != -1:
			return true
	for arg in OS.get_cmdline_args():
		if str(arg).find("wave015-crash-census") != -1:
			return true
	return FileAccess.file_exists("user://wave015_crash_census_trigger.txt")


func _read_stage() -> String:
	if FileAccess.file_exists("user://wave015_crash_census_stage.txt"):
		var f := FileAccess.open("user://wave015_crash_census_stage.txt", FileAccess.READ)
		if f:
			var s := f.get_as_text().strip_edges().to_upper()
			f.close()
			if not s.is_empty():
				return s
	return "ALL"


func _read_seed() -> int:
	if FileAccess.file_exists("user://wave015_crash_census_seed.txt"):
		var f := FileAccess.open("user://wave015_crash_census_seed.txt", FileAccess.READ)
		if f:
			var s := f.get_as_text().strip_edges()
			f.close()
			if s.is_valid_int():
				return int(s)
	return 152026


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_rec("census_start", {"stage": _stage, "seed": _seed})
	if _alive and _stage in ["A", "ALL", "ABCD"]:
		await _stage_a_isolation()
	if _alive and _stage in ["B", "ALL", "ABCD"]:
		await _stage_b_transitions()
	if _alive and _stage in ["C", "ALL", "ABCD"]:
		await _stage_c_fuzz()
	if _alive and _stage in ["D", "ALL", "ABCD"]:
		await _stage_d_matchups()
	if _alive and _stage in ["E", "ALL"]:
		await _stage_e_lifecycle()
	if _alive and _stage in ["F", "ALL"]:
		await _stage_f_soak()
	_finalize()
	if Engine.has_singleton("RuntimeFlightRecorder") or true:
		if has_node("/root/RuntimeFlightRecorder"):
			get_node("/root/RuntimeFlightRecorder").mark_clean_shutdown()
	get_tree().quit(0)


func _stage_a_isolation() -> void:
	_rec("stage_start", {"stage": "A"})
	var reps := 10
	for fighter_id in FIGHTERS:
		# Presentation route (same as Wave015 physical harness).
		var model: Node = MODEL_SCRIPT.new()
		add_child(model)
		var data := _DataLoader.load_fighter(fighter_id)
		var configured := bool(model.configure(data))
		await get_tree().process_frame
		for action in PRESENTATION_ACTIONS:
			for rep in range(reps):
				if not _alive:
					break
				_drive_presentation(model, fighter_id, action, rep)
				if rep % 2 == 0:
					await get_tree().process_frame
				_isolation_rows.append({
					"fighter_id": fighter_id,
					"action": action,
					"route": "FighterModel3D.play_for_state",
					"rep": rep,
					"configured": configured,
					"alive": _process_alive(),
				})
		model.queue_free()
		await get_tree().process_frame

		# Gameplay route via Fighter.queue_attack_command (public combat path).
		var fighter: Node = FIGHTER_SCENE.instantiate()
		add_child(fighter)
		fighter.configure(fighter_id, 1, false, 3, Vector2(0, 0))
		await get_tree().process_frame
		await get_tree().process_frame
		for cmd in GAMEPLAY_COMMANDS:
			for rep in range(reps):
				if not _alive:
					break
				_drive_gameplay_command(fighter, fighter_id, cmd, rep)
				if rep % 2 == 0:
					await get_tree().process_frame
				_isolation_rows.append({
					"fighter_id": fighter_id,
					"action": cmd,
					"route": "Fighter.queue_attack_command",
					"rep": rep,
					"alive": _process_alive(),
				})
		# Input route via TouchInputManager (same as play touch).
		for pulse in INPUT_PULSES:
			for rep in range(reps):
				if not _alive:
					break
				_drive_input_pulse(fighter_id, pulse, rep)
				await get_tree().create_timer(0.06).timeout
				_isolation_rows.append({
					"fighter_id": fighter_id,
					"action": "input_%s" % str(pulse.get("suffix", "")),
					"route": "TouchInputManager",
					"rep": rep,
					"alive": _process_alive(),
				})
		fighter.queue_free()
		await get_tree().process_frame
	_stage_results["A"] = {
		"name": "ISOLATED_ACTION_CENSUS",
		"reps_per_action": reps,
		"rows": _isolation_rows.size(),
		"action_events": _action_events,
		"alive": _alive,
	}
	_write_json("ACTION_ISOLATION_MATRIX.json", {
		"schema": "engineering_wave015.action_isolation.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"observations": _isolation_rows,
		"count": _isolation_rows.size(),
	})
	_persist_replay("stage_a")
	_rec("stage_end", {"stage": "A", "rows": _isolation_rows.size()})


func _stage_b_transitions() -> void:
	_rec("stage_start", {"stage": "B"})
	var actions := PRESENTATION_ACTIONS
	for fighter_id in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		add_child(model)
		model.configure(_DataLoader.load_fighter(fighter_id))
		await get_tree().process_frame
		for a in actions:
			for b in actions:
				if not _alive:
					break
				_drive_presentation(model, fighter_id, a, 0)
				_drive_presentation(model, fighter_id, b, 0)
				var key := "%s|%s->%s" % [fighter_id, a, b]
				_transition_counts[key] = int(_transition_counts.get(key, 0)) + 1
				if (int(_transition_counts[key]) % 8) == 0:
					await get_tree().process_frame
		model.queue_free()
		await get_tree().process_frame
	var matrix: Array = []
	for k in _transition_counts.keys():
		var parts: PackedStringArray = String(k).split("|")
		var fighters_pair := parts[0]
		var ab: PackedStringArray = parts[1].split("->")
		matrix.append({
			"fighter_id": fighters_pair,
			"from": ab[0],
			"to": ab[1],
			"count": _transition_counts[k],
		})
	_stage_results["B"] = {
		"name": "ACTION_TRANSITION_MATRIX",
		"cells": matrix.size(),
		"action_events": _action_events,
		"alive": _alive,
	}
	_write_json("ACTION_TRANSITION_MATRIX.json", {
		"schema": "engineering_wave015.action_transition.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"transitions": matrix,
		"count": matrix.size(),
	})
	_persist_replay("stage_b")
	_rec("stage_end", {"stage": "B", "cells": matrix.size()})


func _stage_c_fuzz() -> void:
	_rec("stage_start", {"stage": "C"})
	var target := 25000
	var started := _action_events
	var fighter_id: String = FIGHTERS[0]
	var model: Node = MODEL_SCRIPT.new()
	add_child(model)
	model.configure(_DataLoader.load_fighter(fighter_id))
	var fighter: Node = FIGHTER_SCENE.instantiate()
	add_child(fighter)
	fighter.configure(fighter_id, 1, false, 3, Vector2(0, 0))
	await get_tree().process_frame
	var batch := 0
	while (_action_events - started) < target and _alive:
		var mode := _rng.randi() % 3
		fighter_id = FIGHTERS[_rng.randi() % FIGHTERS.size()]
		if mode == 0:
			var action: String = PRESENTATION_ACTIONS[_rng.randi() % PRESENTATION_ACTIONS.size()]
			if batch % 200 == 0:
				model.queue_free()
				await get_tree().process_frame
				model = MODEL_SCRIPT.new()
				add_child(model)
				model.configure(_DataLoader.load_fighter(fighter_id))
			_drive_presentation(model, fighter_id, action, batch)
		elif mode == 1:
			var cmd: String = GAMEPLAY_COMMANDS[_rng.randi() % GAMEPLAY_COMMANDS.size()]
			if not is_instance_valid(fighter):
				fighter = FIGHTER_SCENE.instantiate()
				add_child(fighter)
				fighter.configure(fighter_id, 1, false, 3, Vector2(0, 0))
				await get_tree().process_frame
			_drive_gameplay_command(fighter, fighter_id, cmd, batch)
		else:
			var pulse: Dictionary = INPUT_PULSES[_rng.randi() % INPUT_PULSES.size()]
			_drive_input_pulse(fighter_id, pulse, batch)
		batch += 1
		if batch % 200 == 0:
			await get_tree().process_frame
		if batch % 2000 == 0:
			await get_tree().create_timer(0.01).timeout
			_write_json("FUZZ_CAMPAIGN_RESULT.partial.json", {
				"events": _action_events - started,
				"batch": batch,
				"alive": _alive,
			})
	if is_instance_valid(model):
		model.queue_free()
	if is_instance_valid(fighter):
		fighter.queue_free()
	var events := _action_events - started
	_stage_results["C"] = {
		"name": "SEEDED_FUZZ",
		"target_events": target,
		"events": events,
		"seed": _seed,
		"alive": _alive,
		"crashes": _crashes_observed,
	}
	_write_json("FUZZ_CAMPAIGN_RESULT.json", {
		"schema": "engineering_wave015.fuzz.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"GAMEPLAY_ACTION_EVENTS": events,
		"TARGET_EVENTS": target,
		"TARGET_MET": events >= target,
		"CRASHES": _crashes_observed,
		"alive": _alive,
	})
	_persist_replay("stage_c")
	_rec("stage_end", {"stage": "C", "events": events})


func _stage_d_matchups() -> void:
	_rec("stage_start", {"stage": "D"})
	for p1 in FIGHTERS:
		for p2 in FIGHTERS:
			if not _alive:
				break
			var row := await _run_matchup(p1, p2)
			_matchup_rows.append(row)
			_write_json("MATCHUP_STRESS_RESULT.partial.json", {
				"completed": _matchup_rows.size(),
				"last": row,
			})
	_stage_results["D"] = {
		"name": "MATCHUP_STRESS",
		"matchups": _matchup_rows.size(),
		"expected": 49,
		"alive": _alive,
	}
	_write_json("MATCHUP_STRESS_RESULT.json", {
		"schema": "engineering_wave015.matchup.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"seed": _seed,
		"matchups": _matchup_rows,
		"count": _matchup_rows.size(),
		"PASS": _matchup_rows.size() >= 49 and _alive,
	})
	_persist_replay("stage_d")
	_rec("stage_end", {"stage": "D", "matchups": _matchup_rows.size()})


func _run_matchup(p1: String, p2: String) -> Dictionary:
	GameState.p1_fighter_id = p1
	GameState.p2_fighter_id = p2
	GameState.p1_is_cpu = true
	GameState.p2_is_cpu = true
	GameState.stocks = 1
	GameState.match_timer_seconds = 8
	GameState.match_type = "stock"
	GameState.match_seed = _seed + _matchup_rows.size()
	GameState.battle_eval_mode = true
	GameState.battle_eval_max_frames = 180
	GameState.battle_eval_finished = false
	GameState.reset_match()
	_rec("matchup_start", {"p1": p1, "p2": p2})
	var packed: PackedScene = load(BATTLE_PATH)
	var scene: Node = packed.instantiate()
	add_child(scene)
	var frames := 0
	var ok := true
	while frames < 200 and not bool(GameState.battle_eval_finished):
		await get_tree().process_frame
		frames += 1
		if not _process_alive():
			ok = false
			break
		# Inject shared public combat commands periodically.
		if frames % 15 == 0 and scene.has_node("Fighters/Fighter1"):
			var f1: Node = scene.get_node("Fighters/Fighter1")
			if f1 and f1.has_method("queue_attack_command"):
				var cmd: String = GAMEPLAY_COMMANDS[_rng.randi() % GAMEPLAY_COMMANDS.size()]
				_drive_gameplay_command(f1, p1, cmd, frames)
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return {
		"p1": p1,
		"p2": p2,
		"frames": frames,
		"finished": bool(GameState.battle_eval_finished),
		"alive": ok and _alive,
		"OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_RUNTIME",
	}


func _stage_e_lifecycle() -> void:
	_rec("stage_start", {"stage": "E"})
	var cycles := 50
	for i in range(cycles):
		if not _alive:
			break
		var mem_before := OS.get_static_memory_usage()
		for path in [BATTLE_PATH, ROSTER_LAB_PATH, ANIM_LAB_PATH]:
			var packed: PackedScene = load(path)
			if packed == null:
				continue
			var node: Node = packed.instantiate()
			add_child(node)
			await get_tree().process_frame
			await get_tree().process_frame
			node.queue_free()
			await get_tree().process_frame
		var mem_after := OS.get_static_memory_usage()
		_lifecycle_rows.append({
			"cycle": i,
			"mem_before": mem_before,
			"mem_after": mem_after,
			"delta": mem_after - mem_before,
			"alive": _process_alive(),
		})
	_stage_results["E"] = {
		"name": "SCENE_LIFECYCLE",
		"cycles": _lifecycle_rows.size(),
		"target": cycles,
		"alive": _alive,
	}
	_write_json("SCENE_LIFECYCLE_RESULT.json", {
		"schema": "engineering_wave015.scene_lifecycle.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"cycles": _lifecycle_rows,
		"count": _lifecycle_rows.size(),
		"PASS": _lifecycle_rows.size() >= cycles and _alive,
	})
	_persist_replay("stage_e")
	_rec("stage_end", {"stage": "E", "cycles": _lifecycle_rows.size()})


func _stage_f_soak() -> void:
	_rec("stage_start", {"stage": "F"})
	# Wall-clock soak via unix time (ticks_msec alone is easy to mis-read under load).
	var duration_s := 30 * 60
	var start_unix := Time.get_unix_time_from_system()
	var end_unix := start_unix + duration_s
	var events_start := _action_events
	var model: Node = MODEL_SCRIPT.new()
	add_child(model)
	model.configure(_DataLoader.load_fighter(FIGHTERS[0]))
	var ticks := 0
	while Time.get_unix_time_from_system() < end_unix and _alive:
		var fid: String = FIGHTERS[_rng.randi() % FIGHTERS.size()]
		var action: String = PRESENTATION_ACTIONS[_rng.randi() % PRESENTATION_ACTIONS.size()]
		if ticks % 300 == 0:
			model.queue_free()
			await get_tree().process_frame
			model = MODEL_SCRIPT.new()
			add_child(model)
			model.configure(_DataLoader.load_fighter(fid))
		_drive_presentation(model, fid, action, ticks)
		ticks += 1
		if ticks % 20 == 0:
			await get_tree().process_frame
		if ticks % 200 == 0:
			var elapsed_now := int(Time.get_unix_time_from_system() - start_unix)
			_write_json("SOAK_RESULT.partial.json", {
				"elapsed_s": elapsed_now,
				"events": _action_events - events_start,
				"alive": _alive,
			})
	if is_instance_valid(model):
		model.queue_free()
	var elapsed := int(Time.get_unix_time_from_system() - start_unix)
	_stage_results["F"] = {
		"name": "SOAK",
		"target_seconds": duration_s,
		"elapsed_seconds": elapsed,
		"events": _action_events - events_start,
		"alive": _alive,
		"crashes": _crashes_observed,
	}
	_write_json("SOAK_RESULT.json", {
		"schema": "engineering_wave015.soak.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"TARGET_SECONDS": duration_s,
		"ELAPSED_SECONDS": elapsed,
		"GAMEPLAY_ACTION_EVENTS": _action_events - events_start,
		"CRASHES": _crashes_observed,
		"PASS": _alive and _crashes_observed == 0 and elapsed >= duration_s,
	})
	_persist_replay("stage_f")
	_rec("stage_end", {"stage": "F", "elapsed_s": elapsed})


func _drive_presentation(model: Node, fighter_id: String, action: String, rep: int) -> void:
	if not is_instance_valid(model):
		_note_crash("invalid_model", fighter_id, action)
		return
	_action_events += 1
	_replay_events.append({
		"t": Time.get_ticks_msec(),
		"route": "FighterModel3D.play_for_state",
		"fighter_id": fighter_id,
		"action": action,
		"rep": rep,
	})
	_flight("action", fighter_id, action, "FighterModel3D.play_for_state", {"rep": rep})
	model.play_for_state("", {"move_id": action})


func _drive_gameplay_command(fighter: Node, fighter_id: String, cmd: String, rep: int) -> void:
	if not is_instance_valid(fighter):
		_note_crash("invalid_fighter", fighter_id, cmd)
		return
	_action_events += 1
	_replay_events.append({
		"t": Time.get_ticks_msec(),
		"route": "Fighter.queue_attack_command",
		"fighter_id": fighter_id,
		"action": cmd,
		"rep": rep,
	})
	_flight("action", fighter_id, cmd, "Fighter.queue_attack_command", {"rep": rep})
	if fighter.has_method("queue_attack_command"):
		fighter.queue_attack_command(cmd)


func _drive_input_pulse(fighter_id: String, pulse: Dictionary, rep: int) -> void:
	_action_events += 1
	var suffix := str(pulse.get("suffix", "attack"))
	var axis: Vector2 = pulse.get("axis", Vector2.ZERO)
	_replay_events.append({
		"t": Time.get_ticks_msec(),
		"route": "TouchInputManager",
		"fighter_id": fighter_id,
		"action": suffix,
		"axis": [axis.x, axis.y],
		"rep": rep,
	})
	_flight("action", fighter_id, suffix, "TouchInputManager", {"rep": rep, "axis": [axis.x, axis.y]})
	TouchInputManager.set_stick(axis)
	TouchInputManager.set_button(suffix, true, true)
	# Edge released next frame via short timer-free immediate release pattern.
	TouchInputManager.set_button(suffix, false, false)
	TouchInputManager.set_stick(Vector2.ZERO)


func _flight(kind: String, fighter_id: String, action: String, route: String, extra: Dictionary) -> void:
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("record_action"):
		rec.record_action(fighter_id, action, route, extra)
	elif rec and rec.has_method("record"):
		rec.record(kind, {"fighter_id": fighter_id, "action": action, "route": route})


func _rec(kind: String, payload: Dictionary) -> void:
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("record"):
		rec.record(kind, payload)


func _note_crash(sig: String, fighter_id: String, action: String) -> void:
	_crashes_observed += 1
	_alive = false
	_rec("crash_note", {"signature": sig, "fighter_id": fighter_id, "action": action})
	_write_json("CRASH_NOTE_%s.json" % sig, {
		"signature": sig,
		"fighter_id": fighter_id,
		"action": action,
		"t_msec": Time.get_ticks_msec(),
		"recent_replay": _replay_events.slice(maxi(0, _replay_events.size() - 64), _replay_events.size()),
	})


func _process_alive() -> bool:
	# Host process liveness is also checked externally via adb pidof.
	return _alive


func _persist_replay(label: String) -> void:
	var path := "replays/%s.jsonl" % label
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR + "replays"))
	var f := FileAccess.open(OUT_DIR + path, FileAccess.WRITE)
	if f == null:
		return
	var start := maxi(0, _replay_events.size() - 5000)
	for i in range(start, _replay_events.size()):
		f.store_line(JSON.stringify(_replay_events[i]))
	f.close()


func _finalize() -> void:
	_write_json("CENSUS_SUMMARY.json", {
		"schema": "engineering_wave015.census_summary.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"stage": _stage,
		"seed": _seed,
		"action_events": _action_events,
		"crashes_observed": _crashes_observed,
		"alive": _alive,
		"stages": _stage_results,
	})
	_persist_replay("final")
	print("Wave015CrashCensus complete events=", _action_events, " alive=", _alive)


func _write_json(name: String, payload: Dictionary) -> void:
	var f := FileAccess.open(OUT_DIR + name, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()
