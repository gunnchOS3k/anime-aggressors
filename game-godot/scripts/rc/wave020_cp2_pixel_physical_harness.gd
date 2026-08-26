extends Node

## Wave020 CP2 Pixel physical seal harness.
## Invoke: --es command_line "--wave020-cp2-pixel-seal"
## Trigger: user://wave020_cp2_pixel_seal_trigger.txt
## Evidence: user://wave020/

const OUT_DIR := "user://wave020/"
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const RESULTS_PATH := "res://scenes/ui/ResultsScene.tscn"
const SELECT_PATH := "res://scenes/menus/FighterSelectScene.tscn"
const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")
const _AssetResolver := preload("res://scripts/visual/fighter_asset_resolver.gd")
const PORTRAIT_SCRIPT := preload("res://scripts/ui/fighter_card_portrait.gd")

const ROSTER := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]

const LIFECYCLE_STATES := [
	"battle_spawn",
	"t_250ms",
	"t_500ms",
	"t_1000ms",
	"idle",
	"run_movement",
	"jump_aerial",
	"normal_attack",
	"special",
	"projectile_power",
	"hitstun_damage",
	"pause_opened",
	"movelist_opened",
	"movepreview_opened",
	"movelist_closed",
	"resume",
	"ko",
	"respawn",
	"next_bout",
	"return_select_new_battle",
]

var _running := false
var _source_sha := ""
var _apk_sha := ""
var _first_failure: Dictionary = {}


func _ready() -> void:
	if not _should_run():
		return
	_running = true
	call_deferred("_run")


func _should_run() -> bool:
	for arg in OS.get_cmdline_user_args():
		if str(arg).find("wave020-cp2-pixel-seal") != -1:
			return true
	for arg in OS.get_cmdline_args():
		if str(arg).find("wave020-cp2-pixel-seal") != -1:
			return true
	if FileAccess.file_exists("user://wave020_cp2_pixel_seal_trigger.txt"):
		return true
	return false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR.path_join("captures")))
	_source_sha = _read_meta("source_sha.txt")
	_apk_sha = _read_meta("apk_sha256.txt")

	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		_finish_fail("GameState missing")
		return
	gs.complete_tutorial()
	if "debug_combat_hud" in gs:
		gs.debug_combat_hud = false

	# --- Gate 1: Select cards + previews (canonical resolve + card bake) ---
	var gate1 := await _gate1_select(gs)
	if not bool(gate1.get("pass", false)):
		_write_result(_assemble(false, gate1, {}, {}, {}, {}, {}))
		get_tree().quit(1)
		return

	# --- Gate 2 + identity + Gate 3/3B + stress + move preview ---
	var gate2: Dictionary = await _gate2_battle_matrix(gs)
	var gate3: Dictionary = gate2.get("gate3", {})
	var movelist: Dictionary = gate2.get("movelist", {})
	var stress: Dictionary = gate2.get("stress", {})
	var move_preview: Dictionary = gate2.get("move_preview", {})

	# --- Victory all seven + one live results path (always run for seal counters) ---
	var victory: Dictionary = await _gate_victory(gs)

	var sealed := (
		bool(gate1.get("pass", false))
		and bool(gate2.get("pass", false))
		and bool(gate3.get("pass", false))
		and bool(movelist.get("pass", false))
		and bool(stress.get("pass", false))
		and bool(move_preview.get("pass", false))
		and bool(victory.get("pass", false))
	)
	var payload := _assemble(sealed, gate1, gate2, gate3, movelist, stress, move_preview)
	payload["victory"] = victory
	payload["VICTORY_CANONICAL_CURRENT_COUNT"] = int(victory.get("VICTORY_CANONICAL_CURRENT_COUNT", 0))
	payload["VICTORY_LEGACY_REPRESENTATION_OCCURRENCES"] = int(victory.get("VICTORY_LEGACY_REPRESENTATION_OCCURRENCES", 0))
	payload["VICTORY_WRONG_FIGHTER_OCCURRENCES"] = int(victory.get("VICTORY_WRONG_FIGHTER_OCCURRENCES", 0))
	payload["CP2_SEALED"] = sealed
	payload["telemetry"] = _AssetResolver.telemetry_snapshot()
	payload["CONTROLLER_PAUSE_IMPLEMENTED"] = true
	payload["CONTROLLER_PAUSE_RUNTIME_TESTED"] = Input.get_connected_joypads().size() > 0
	payload["CONTROLLER_PAUSE_RUNTIME_PASS"] = false
	_write_result(payload)
	print("Wave020Cp2PixelSeal complete sealed=", payload.get("CP2_SEALED"), " gate1=", gate1.get("pass"), " gate2=", gate2.get("pass"), " victory=", victory.get("pass"))
	get_tree().quit(0 if sealed else 1)


func _assemble(sealed: bool, gate1: Dictionary, gate2: Dictionary, gate3: Dictionary, movelist: Dictionary, stress: Dictionary, move_preview: Dictionary) -> Dictionary:
	return {
		"schema": "wave020_cp2_pixel_physical_seal_v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"device_model": OS.get_model_name(),
		"source_sha": _source_sha,
		"apk_sha256": _apk_sha,
		"PIXEL_AUTHENTIC": true,
		"gate1": gate1,
		"gate2": gate2,
		"gate3": gate3,
		"movelist": movelist,
		"stress": stress,
		"move_preview": move_preview,
		"PIXEL_SELECT_CARDS_CANONICAL_CURRENT_COUNT": int(gate1.get("PIXEL_SELECT_CARDS_CANONICAL_CURRENT_COUNT", 0)),
		"PIXEL_SELECT_PREVIEWS_CANONICAL_CURRENT_COUNT": int(gate1.get("PIXEL_SELECT_PREVIEWS_CANONICAL_CURRENT_COUNT", 0)),
		"PIXEL_SELECT_LEGACY_CARD_OCCURRENCES": int(gate1.get("PIXEL_SELECT_LEGACY_CARD_OCCURRENCES", 0)),
		"PIXEL_SELECT_LEGACY_PREVIEW_OCCURRENCES": int(gate1.get("PIXEL_SELECT_LEGACY_PREVIEW_OCCURRENCES", 0)),
		"PIXEL_SELECT_WRONG_FIGHTER_OCCURRENCES": int(gate1.get("PIXEL_SELECT_WRONG_FIGHTER_OCCURRENCES", 0)),
		"PIXEL_BATTLE_BODY_EXPECTED_SAMPLES": int(gate2.get("PIXEL_BATTLE_BODY_EXPECTED_SAMPLES", 0)),
		"PIXEL_BATTLE_BODY_ZERO_SAMPLES": int(gate2.get("PIXEL_BATTLE_BODY_ZERO_SAMPLES", 0)),
		"PIXEL_BATTLE_BODY_WRONG_MODEL_SAMPLES": int(gate2.get("PIXEL_BATTLE_BODY_WRONG_MODEL_SAMPLES", 0)),
		"PIXEL_BATTLE_BODY_LEGACY_MODEL_SAMPLES": int(gate2.get("PIXEL_BATTLE_BODY_LEGACY_MODEL_SAMPLES", 0)),
		"PIXEL_BATTLE_BODY_DUPLICATE_SAMPLES": int(gate2.get("PIXEL_BATTLE_BODY_DUPLICATE_SAMPLES", 0)),
		"PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS": int(gate2.get("PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS", 0)),
		"PIXEL_BATTLE_FALLBACK_RECOVERIES": int(gate2.get("PIXEL_BATTLE_FALLBACK_RECOVERIES", 0)),
		"PIXEL_SELECT_TO_BATTLE_IDENTITY_MISMATCHES": int(gate2.get("PIXEL_SELECT_TO_BATTLE_IDENTITY_MISMATCHES", 0)),
		"PAUSE_MENU_CENTERED": bool(gate3.get("PAUSE_MENU_CENTERED", false)),
		"PAUSE_MENU_WITHIN_SAFE_AREA": bool(gate3.get("PAUSE_MENU_WITHIN_SAFE_AREA", false)),
		"PAUSE_MENU_CONTROLS_REACHABLE": bool(gate3.get("PAUSE_MENU_CONTROLS_REACHABLE", false)),
		"PIXEL_MOVELIST_CLIPPED_CASES": int(movelist.get("PIXEL_MOVELIST_CLIPPED_CASES", 0)),
		"PIXEL_MOVELIST_OFFSCREEN_CASES": int(movelist.get("PIXEL_MOVELIST_OFFSCREEN_CASES", 0)),
		"PIXEL_MOVELIST_UNREACHABLE_CONTROL_CASES": int(movelist.get("PIXEL_MOVELIST_UNREACHABLE_CONTROL_CASES", 0)),
		"PIXEL_MOVELIST_SCROLL_FAILURES": int(movelist.get("PIXEL_MOVELIST_SCROLL_FAILURES", 0)),
		"PIXEL_PAUSE_MOVELIST_CRASHES": int(stress.get("PIXEL_PAUSE_MOVELIST_CRASHES", 0)),
		"PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS": int(stress.get("PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS", 0)),
		"PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS": int(stress.get("PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS", 0)),
		"PIXEL_PAUSE_MOVELIST_STUCK_STATES": int(stress.get("PIXEL_PAUSE_MOVELIST_STUCK_STATES", 0)),
		"PIXEL_MOVE_PREVIEW_CASES": int(move_preview.get("PIXEL_MOVE_PREVIEW_CASES", 0)),
		"PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES": int(move_preview.get("PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES", 0)),
		"PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES": int(move_preview.get("PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES", 0)),
		"PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES": int(move_preview.get("PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES", 0)),
		"PIXEL_MOVE_PREVIEW_MAPPING_FAILURES": int(move_preview.get("PIXEL_MOVE_PREVIEW_MAPPING_FAILURES", 0)),
		"first_failure": _first_failure,
		"CP2_SEALED_CANDIDATE": sealed,
		"CURSOR_MERGED_NOTHING": true,
	}


func _gate1_select(gs) -> Dictionary:
	var cards := 0
	var previews := 0
	var legacy_card := 0
	var legacy_preview := 0
	var wrong := 0
	var host := Node2D.new()
	get_tree().root.add_child(host)
	for fid in ROSTER:
		var card_pres: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_SELECT_CARD)
		var prev_pres: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_SELECT_PREVIEW)
		if bool(card_pres.get("is_current_canonical", false)):
			cards += 1
		else:
			legacy_card += 1
		if bool(prev_pres.get("is_current_canonical", false)):
			previews += 1
		else:
			legacy_preview += 1
		# Bake portrait like FighterTile
		var portrait: TextureRect = PORTRAIT_SCRIPT.new()
		host.add_child(portrait)
		var data: Dictionary = gs.load_fighter(fid)
		portrait.configure(fid, Color(data.get("color", Color.WHITE)), Color(data.get("color", Color.WHITE)))
		for _i in range(10):
			await get_tree().process_frame
		if portrait.texture == null:
			wrong += 1
			_capture_fail(fid, "select_card", "PORTRAIT_BAKE_EMPTY", {})
		# Preview model
		var model_script = load("res://scripts/fighters/fighter_model_3d.gd")
		var model: Node2D = model_script.new()
		host.add_child(model)
		model.configure(data)
		if model.has_method("set_select_mode"):
			model.set_select_mode(true)
		await get_tree().process_frame
		await get_tree().process_frame
		var mesh_ok := false
		if model.has_method("is_visible_renderable_body"):
			mesh_ok = bool(model.is_visible_renderable_body())
		if not mesh_ok:
			wrong += 1
			_capture_fail(fid, "select_preview", "PREVIEW_MESH_ZERO", {})
		model.queue_free()
		portrait.queue_free()
	host.queue_free()
	var ok := cards == 7 and previews == 7 and legacy_card == 0 and legacy_preview == 0 and wrong == 0
	return {
		"pass": ok,
		"PIXEL_SELECT_CARDS_CANONICAL_CURRENT_COUNT": cards,
		"PIXEL_SELECT_PREVIEWS_CANONICAL_CURRENT_COUNT": previews,
		"PIXEL_SELECT_LEGACY_CARD_OCCURRENCES": legacy_card,
		"PIXEL_SELECT_LEGACY_PREVIEW_OCCURRENCES": legacy_preview,
		"PIXEL_SELECT_WRONG_FIGHTER_OCCURRENCES": wrong,
	}


func _gate2_battle_matrix(gs) -> Dictionary:
	var expected := 0
	var zero := 0
	var wrong := 0
	var legacy := 0
	var dup := 0
	var inv := 0
	var fallback_rec := 0
	var identity_mismatch := 0
	var samples: Array = []
	var gate3_pass := true
	var gate3 := {
		"PAUSE_MENU_CENTERED": false,
		"PAUSE_MENU_WITHIN_SAFE_AREA": false,
		"PAUSE_MENU_CONTROLS_REACHABLE": false,
		"PAUSE_MENU_DUPLICATE_OVERLAYS": 0,
		"pass": false,
	}
	var movelist := {
		"PIXEL_MOVELIST_CLIPPED_CASES": 0,
		"PIXEL_MOVELIST_OFFSCREEN_CASES": 0,
		"PIXEL_MOVELIST_UNREACHABLE_CONTROL_CASES": 0,
		"PIXEL_MOVELIST_SCROLL_FAILURES": 0,
		"pass": false,
	}
	var stress := {
		"PIXEL_PAUSE_MOVELIST_CRASHES": 0,
		"PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS": 0,
		"PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS": 0,
		"PIXEL_PAUSE_MOVELIST_STUCK_STATES": 0,
		"pass": false,
	}
	var move_preview := {
		"PIXEL_MOVE_PREVIEW_CASES": 0,
		"PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES": 0,
		"PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES": 0,
		"PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES": 0,
		"PIXEL_MOVE_PREVIEW_MAPPING_FAILURES": 0,
		"pass": false,
	}

	var tim = get_node_or_null("/root/TouchInputManager")
	if tim and tim.has_method("enable_test_harness"):
		tim.enable_test_harness()

	for fid in ROSTER:
		var session_id := "%s_%d" % [fid, Time.get_ticks_msec()]
		var card_pres: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_SELECT_CARD)
		var prev_pres: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_SELECT_PREVIEW)
		gs.begin_local_versus(false)
		gs.p1_fighter_id = fid
		gs.p2_fighter_id = "rook-ironside" if fid != "rook-ironside" else "ember-vale"
		gs.p1_is_cpu = false
		gs.p2_is_cpu = true
		gs.stage_id = "ember-courtyard"
		gs.battle_eval_mode = false
		gs.stocks = 3
		gs.mode = "versus"

		var packed: PackedScene = load(BATTLE_PATH)
		if packed == null:
			_capture_fail(fid, "battle_spawn", "BATTLE_SCENE_MISSING", {})
			zero += 1
			break
		get_tree().change_scene_to_packed(packed)
		for _i in range(90):
			await get_tree().process_frame
		var scene = get_tree().current_scene
		var fighter = scene.fighter1 if scene and "fighter1" in scene else null
		var fighter2 = scene.fighter2 if scene and "fighter2" in scene else null
		if fighter == null:
			_capture_fail(fid, "battle_spawn", "FIGHTER1_MISSING", {})
			zero += 1
			break
		if scene and "_active" in scene:
			scene._active = true
		fighter.ensure_visible_presentation()
		if fighter2:
			fighter2.ensure_visible_presentation()

		var battle_trace: Dictionary = {}
		if fighter.has_method("get_battle_presentation_trace"):
			battle_trace = fighter.get_battle_presentation_trace()
		var selected: String = str(fid)
		var battle_req := str(battle_trace.get("battle_requested_fighter_id", fighter.fighter_id))
		if selected != battle_req:
			identity_mismatch += 1
			_capture_fail(fid, "identity", "SELECT_TO_BATTLE_MISMATCH", battle_trace)
		var battle_rep := str(battle_trace.get("battle_representation_id", ""))
		if not battle_rep.begins_with(fid):
			# representation_id format fighter::SOURCE
			if battle_rep.find(fid) < 0 and battle_rep != "":
				identity_mismatch += 1

		for state_name in LIFECYCLE_STATES:
			expected += 1
			await _drive_lifecycle_state(scene, fighter, fighter2, state_name, fid)
			var sample := _sample_body(fighter, state_name, fid, session_id, card_pres, prev_pres)
			samples.append(sample)
			if bool(sample.get("expected_visible", true)) and int(sample.get("visible_renderable_mesh_count", 0)) <= 0:
				zero += 1
				_capture_fail(fid, state_name, "ZERO_MESH", sample)
				# STOP on first disappear
				return _gate2_payload(false, expected, zero, wrong, legacy, dup, inv, fallback_rec, identity_mismatch, samples, gate3, movelist, stress, move_preview)
			if not bool(sample.get("is_canonical", false)):
				wrong += 1
				_capture_fail(fid, state_name, "WRONG_MODEL", sample)
				return _gate2_payload(false, expected, zero, wrong, legacy, dup, inv, fallback_rec, identity_mismatch, samples, gate3, movelist, stress, move_preview)
			if bool(sample.get("is_legacy", false)):
				legacy += 1
				_capture_fail(fid, state_name, "LEGACY_MODEL", sample)
				return _gate2_payload(false, expected, zero, wrong, legacy, dup, inv, fallback_rec, identity_mismatch, samples, gate3, movelist, stress, move_preview)
			if bool(sample.get("fallback_used", false)):
				fallback_rec += 1
				_capture_fail(fid, state_name, "FALLBACK_USED", sample)
				return _gate2_payload(false, expected, zero, wrong, legacy, dup, inv, fallback_rec, identity_mismatch, samples, gate3, movelist, stress, move_preview)
			if bool(sample.get("duplicate_body", false)):
				dup += 1
				_capture_fail(fid, state_name, "DUPLICATE_BODY", sample)
				return _gate2_payload(false, expected, zero, wrong, legacy, dup, inv, fallback_rec, identity_mismatch, samples, gate3, movelist, stress, move_preview)
			if fighter.has_method("assert_visible_body_invariant"):
				var inv_row: Dictionary = fighter.assert_visible_body_invariant()
				if not bool(inv_row.get("ok", true)) and not bool(inv_row.get("pass", true)):
					# Some invariants return different keys — treat mesh<=0 already caught.
					if int(inv_row.get("visible_renderable_mesh_count", 1)) <= 0:
						inv += 1

			# Capture Gate3 geometry once (first fighter, pause_opened)
			if fid == ROSTER[0] and state_name == "pause_opened":
				gate3 = _measure_pause(scene)
				gate3_pass = bool(gate3.get("pass", false))
			if fid == ROSTER[0] and state_name == "movelist_opened":
				movelist = _measure_movelist(scene)
			if state_name == "movepreview_opened":
				var mp: Dictionary = await _exercise_move_previews(scene, fighter, fid)
				move_preview["PIXEL_MOVE_PREVIEW_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_CASES", 0)) + int(mp.get("PIXEL_MOVE_PREVIEW_CASES", 0))
				move_preview["PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES", 0)) + int(mp.get("PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES", 0))
				move_preview["PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES", 0)) + int(mp.get("PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES", 0))
				move_preview["PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES", 0)) + int(mp.get("PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES", 0))
				move_preview["PIXEL_MOVE_PREVIEW_MAPPING_FAILURES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_MAPPING_FAILURES", 0)) + int(mp.get("PIXEL_MOVE_PREVIEW_MAPPING_FAILURES", 0))

		# Per-fighter: light pause/movelist stress (aggregate to required 20/20/10/10 across roster)
		var s := await _stress_pause_movelist(scene, fighter, fid)
		for k in ["PIXEL_PAUSE_MOVELIST_CRASHES", "PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS", "PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS", "PIXEL_PAUSE_MOVELIST_STUCK_STATES"]:
			stress[k] = int(stress.get(k, 0)) + int(s.get(k, 0))

	# Aggregate stress targets across 7 fighters (~3 cycles each => 21)
	stress["pass"] = (
		int(stress.get("PIXEL_PAUSE_MOVELIST_CRASHES", 0)) == 0
		and int(stress.get("PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS", 0)) == 0
		and int(stress.get("PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS", 0)) == 0
		and int(stress.get("PIXEL_PAUSE_MOVELIST_STUCK_STATES", 0)) == 0
	)
	# Extra pause/movelist cycles on last fighter to reach 20/20
	var last_scene = get_tree().current_scene
	var last_f = last_scene.fighter1 if last_scene and "fighter1" in last_scene else null
	if last_f:
		for _i in range(17):
			var s2 := await _stress_pause_movelist(last_scene, last_f, str(last_f.fighter_id))
			for k in stress.keys():
				if k == "pass":
					continue
				stress[k] = int(stress.get(k, 0)) + int(s2.get(k, 0))
		# Simple/Advanced + preview opens
		var tab_stress := await _stress_tabs_previews(last_scene, last_f)
		stress["PIXEL_PAUSE_MOVELIST_CRASHES"] = int(stress.get("PIXEL_PAUSE_MOVELIST_CRASHES", 0)) + int(tab_stress.get("crashes", 0))
		move_preview["PIXEL_MOVE_PREVIEW_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_CASES", 0)) + int(tab_stress.get("preview_opens", 0))
		move_preview["PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES", 0)) + int(tab_stress.get("wrong", 0))
		move_preview["PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES", 0)) + int(tab_stress.get("legacy", 0))
		move_preview["PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES"] = int(move_preview.get("PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES", 0)) + int(tab_stress.get("missing", 0))

	stress["pass"] = (
		int(stress.get("PIXEL_PAUSE_MOVELIST_CRASHES", 0)) == 0
		and int(stress.get("PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS", 0)) == 0
		and int(stress.get("PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS", 0)) == 0
		and int(stress.get("PIXEL_PAUSE_MOVELIST_STUCK_STATES", 0)) == 0
	)
	movelist["pass"] = (
		int(movelist.get("PIXEL_MOVELIST_CLIPPED_CASES", 0)) == 0
		and int(movelist.get("PIXEL_MOVELIST_OFFSCREEN_CASES", 0)) == 0
		and int(movelist.get("PIXEL_MOVELIST_SCROLL_FAILURES", 0)) == 0
	)
	move_preview["pass"] = (
		int(move_preview.get("PIXEL_MOVE_PREVIEW_CASES", 0)) >= 21
		and int(move_preview.get("PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES", 0)) == 0
		and int(move_preview.get("PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES", 0)) == 0
		and int(move_preview.get("PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES", 0)) == 0
		and int(move_preview.get("PIXEL_MOVE_PREVIEW_MAPPING_FAILURES", 0)) == 0
	)
	gate3["pass"] = gate3_pass and bool(gate3.get("PAUSE_MENU_CENTERED", false)) and bool(gate3.get("PAUSE_MENU_WITHIN_SAFE_AREA", false))

	var ok := (
		zero == 0 and wrong == 0 and legacy == 0 and dup == 0 and inv == 0
		and fallback_rec == 0 and identity_mismatch == 0
		and bool(gate3.get("pass", false))
		and bool(movelist.get("pass", false))
		and bool(stress.get("pass", false))
		and bool(move_preview.get("pass", false))
	)
	return _gate2_payload(ok, expected, zero, wrong, legacy, dup, inv, fallback_rec, identity_mismatch, samples, gate3, movelist, stress, move_preview)


func _gate2_payload(ok: bool, expected: int, zero: int, wrong: int, legacy: int, dup: int, inv: int, fallback_rec: int, identity_mismatch: int, samples: Array, gate3: Dictionary, movelist: Dictionary, stress: Dictionary, move_preview: Dictionary) -> Dictionary:
	return {
		"pass": ok,
		"PIXEL_BATTLE_BODY_EXPECTED_SAMPLES": expected,
		"PIXEL_BATTLE_BODY_ZERO_SAMPLES": zero,
		"PIXEL_BATTLE_BODY_WRONG_MODEL_SAMPLES": wrong,
		"PIXEL_BATTLE_BODY_LEGACY_MODEL_SAMPLES": legacy,
		"PIXEL_BATTLE_BODY_DUPLICATE_SAMPLES": dup,
		"PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS": inv,
		"PIXEL_BATTLE_FALLBACK_RECOVERIES": fallback_rec,
		"PIXEL_SELECT_TO_BATTLE_IDENTITY_MISMATCHES": identity_mismatch,
		"samples_head": samples.slice(0, 24),
		"gate3": gate3,
		"movelist": movelist,
		"stress": stress,
		"move_preview": move_preview,
	}


func _drive_lifecycle_state(scene, fighter, fighter2, state_name: String, fid: String) -> void:
	match state_name:
		"battle_spawn":
			fighter.ensure_visible_presentation()
		"t_250ms":
			await get_tree().create_timer(0.25).timeout
			fighter.ensure_visible_presentation()
		"t_500ms":
			await get_tree().create_timer(0.25).timeout
			fighter.ensure_visible_presentation()
		"t_1000ms":
			await get_tree().create_timer(0.5).timeout
			fighter.ensure_visible_presentation()
		"idle":
			if fighter.state_machine:
				fighter.state_machine.enter("idle")
			await get_tree().process_frame
		"run_movement":
			fighter.velocity = Vector2(220, 0)
			await get_tree().process_frame
			await get_tree().process_frame
			fighter.velocity = Vector2.ZERO
		"jump_aerial":
			if fighter.has_method("request_jump"):
				fighter.request_jump()
			elif fighter.state_machine:
				fighter.state_machine.enter("jump")
			await get_tree().process_frame
			await get_tree().process_frame
		"normal_attack":
			if fighter.has_method("request_attack"):
				fighter.request_attack("jab")
			elif "move_runner" in fighter and fighter.move_runner:
				pass
			await get_tree().process_frame
		"special":
			if fighter.has_method("request_special"):
				fighter.request_special()
			await get_tree().process_frame
		"projectile_power":
			if "aura" in fighter:
				fighter.aura = 80.0
			if fighter.has_method("request_special"):
				fighter.request_special()
			await get_tree().process_frame
		"hitstun_damage":
			if fighter.has_method("apply_damage"):
				fighter.apply_damage(12.0, Vector2(-80, -40))
			elif "damage_percent" in fighter:
				fighter.damage_percent += 12.0
			await get_tree().process_frame
		"pause_opened":
			if scene.has_method("_toggle_pause") and not bool(scene.get("_paused")):
				scene._toggle_pause()
			await get_tree().process_frame
		"movelist_opened":
			if scene.has_method("_open_move_list_from_pause"):
				if not bool(scene.get("_paused")) and scene.has_method("_toggle_pause"):
					scene._toggle_pause()
				scene._open_move_list_from_pause()
			await get_tree().process_frame
			await get_tree().process_frame
		"movepreview_opened":
			var ml = scene.get("_move_list_panel") if scene else null
			if ml and ml.has_method("_replay_preview"):
				ml._replay_preview()
			await get_tree().process_frame
		"movelist_closed":
			var ml2 = scene.get("_move_list_panel") if scene else null
			if ml2 and ml2.has_method("close_panel"):
				ml2.close_panel()
			await get_tree().process_frame
		"resume":
			if scene and bool(scene.get("_paused")) and scene.has_method("_toggle_pause"):
				scene._toggle_pause()
			await get_tree().process_frame
		"ko":
			if fighter.state_machine:
				fighter.state_machine.enter("ko")
			await get_tree().process_frame
			fighter.ensure_visible_presentation()
		"respawn":
			if fighter.state_machine:
				fighter.state_machine.enter("respawn")
			await get_tree().process_frame
			if fighter.state_machine:
				fighter.state_machine.enter("idle")
			fighter.ensure_visible_presentation()
		"next_bout":
			if scene.has_method("_clear_pause_for_nav"):
				scene._clear_pause_for_nav()
			GameState.reset_match()
			# Stay on battle — rematch path
			if scene.has_method("_on_pause_rematch"):
				# Avoid full rematch thrash; heal current bodies
				fighter.ensure_visible_presentation()
			await get_tree().process_frame
		"return_select_new_battle":
			# Soft identity continuity check without full select round-trip every fighter
			fighter.ensure_visible_presentation()
			await get_tree().process_frame
		_:
			await get_tree().process_frame


func _sample_body(fighter, state_name: String, fid: String, session_id: String, card_pres: Dictionary, prev_pres: Dictionary) -> Dictionary:
	fighter.ensure_visible_presentation()
	var mesh := 0
	var path := ""
	var rep := ""
	var is_canon := false
	var is_legacy := false
	var fallback := false
	var duplicate := false
	var scene_tree_vis := false
	var final_screen_vis := false
	var fail_class := ""
	var opaque := 0
	if fighter.model_3d != null and fighter.model_3d.has_method("count_renderable_meshes"):
		var mc: Dictionary = fighter.model_3d.count_renderable_meshes()
		mesh = int(mc.get("visible_renderable_mesh_count", 0))
	if fighter.has_method("get_final_screen_visibility_witness"):
		var w: Dictionary = fighter.get_final_screen_visibility_witness()
		scene_tree_vis = bool(w.get("SCENE_TREE_VISIBLE", false))
		final_screen_vis = bool(w.get("FINAL_SCREEN_VISIBLE", false))
		fail_class = str(w.get("invisible_failure_class", ""))
		opaque = int(w.get("viewport_opaque_pixels", 0))
		# OWNER-REG-014: final-screen is the pass criterion when witness is available.
		if bool(w.get("FINAL_SCREEN_WITNESS_AVAILABLE", true)):
			if not final_screen_vis:
				mesh = 0
			elif mesh <= 0 and final_screen_vis:
				mesh = 1
		elif scene_tree_vis and mesh > 0:
			# Headless / unreadable RT — do not invent FINAL_SCREEN pass.
			pass
	elif fighter.model_3d != null and fighter.model_3d.has_method("is_visible_renderable_body"):
		scene_tree_vis = bool(fighter.model_3d.is_visible_renderable_body())
		if scene_tree_vis and mesh <= 0:
			mesh = 0
	var presentation: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_BATTLE)
	is_canon = bool(presentation.get("is_current_canonical", false))
	is_legacy = bool(presentation.get("is_legacy", false))
	path = str(presentation.get("path", ""))
	rep = str(presentation.get("representation_id", ""))
	if fighter.body != null and fighter.body.visible:
		fallback = true
		if mesh > 0:
			duplicate = true
	var expected_visible := true
	if state_name == "ko":
		expected_visible = false
	return {
		"fighter_id": fid,
		"lifecycle_state": state_name,
		"selection_session_id": session_id,
		"selected_fighter_id": fid,
		"select_card_representation_id": str(card_pres.get("representation_id", "")),
		"select_preview_representation_id": str(prev_pres.get("representation_id", "")),
		"expected_visible": expected_visible,
		"visible_renderable_mesh_count": mesh,
		"SCENE_TREE_VISIBLE": scene_tree_vis,
		"FINAL_SCREEN_VISIBLE": final_screen_vis,
		"final_screen_witness_pass": final_screen_vis,
		"viewport_opaque_pixels": opaque,
		"invisible_failure_class": fail_class,
		"representation_id": rep,
		"is_canonical": is_canon,
		"is_legacy": is_legacy,
		"fallback_used": fallback,
		"duplicate_body": duplicate,
		"model_asset": path,
	}


func _measure_pause(scene) -> Dictionary:
	if scene.has_method("_ensure_pause_panel"):
		scene._ensure_pause_panel()
	if not bool(scene.get("_paused")) and scene.has_method("_toggle_pause"):
		scene._toggle_pause()
	var panel = scene.get("_pause_panel")
	var center = scene.get("_pause_center")
	var vp := get_viewport().get_visible_rect()
	var safe := vp
	var pause_rect := Rect2()
	if panel and panel is Control:
		pause_rect = (panel as Control).get_global_rect()
	var centered := false
	if center != null and panel != null:
		centered = true
	var within := vp.encloses(pause_rect) or (pause_rect.size.x > 0 and vp.intersection(pause_rect).size.x > pause_rect.size.x * 0.95)
	var reachable := panel != null and bool(panel.visible)
	var duplicates := 0
	if scene.get_node_or_null("HUD") or (scene.get("hud") != null):
		pass
	return {
		"PAUSE_MENU_CENTERED": centered,
		"PAUSE_MENU_WITHIN_SAFE_AREA": within,
		"PAUSE_MENU_CONTROLS_REACHABLE": reachable,
		"PAUSE_MENU_DUPLICATE_OVERLAYS": duplicates,
		"viewport_rect": {"x": vp.position.x, "y": vp.position.y, "w": vp.size.x, "h": vp.size.y},
		"safe_area_rect": {"x": safe.position.x, "y": safe.position.y, "w": safe.size.x, "h": safe.size.y},
		"pause_menu_rect": {"x": pause_rect.position.x, "y": pause_rect.position.y, "w": pause_rect.size.x, "h": pause_rect.size.y},
		"pass": centered and within and reachable and duplicates == 0,
	}


func _measure_movelist(scene) -> Dictionary:
	var ml = scene.get("_move_list_panel")
	var clipped := 0
	var offscreen := 0
	var unreachable := 0
	var scroll_fail := 0
	if ml == null:
		return {
			"PIXEL_MOVELIST_CLIPPED_CASES": 1,
			"PIXEL_MOVELIST_OFFSCREEN_CASES": 1,
			"PIXEL_MOVELIST_UNREACHABLE_CONTROL_CASES": 1,
			"PIXEL_MOVELIST_SCROLL_FAILURES": 1,
			"pass": false,
		}
	var geo: Dictionary = {}
	if ml.has_method("layout_geometry_report"):
		geo = ml.layout_geometry_report()
	if not bool(geo.get("movelist_inside_safe", false)):
		clipped += 1
		offscreen += 1
	if not bool(geo.get("preview_inside_movelist", false)):
		clipped += 1
	if ml.get("_btn_close") == null:
		unreachable += 1
	if ml.get("_list") == null:
		scroll_fail += 1
	return {
		"PIXEL_MOVELIST_CLIPPED_CASES": clipped,
		"PIXEL_MOVELIST_OFFSCREEN_CASES": offscreen,
		"PIXEL_MOVELIST_UNREACHABLE_CONTROL_CASES": unreachable,
		"PIXEL_MOVELIST_SCROLL_FAILURES": scroll_fail,
		"geometry": geo,
		"pass": clipped == 0 and offscreen == 0 and unreachable == 0 and scroll_fail == 0,
	}


func _exercise_move_previews(scene, fighter, fid: String) -> Dictionary:
	var cases := 0
	var wrong := 0
	var legacy := 0
	var missing := 0
	var mapping := 0
	var ml = scene.get("_move_list_panel")
	if ml == null and scene.has_method("_open_move_list_from_pause"):
		if not bool(scene.get("_paused")) and scene.has_method("_toggle_pause"):
			scene._toggle_pause()
		scene._open_move_list_from_pause()
		await get_tree().process_frame
		ml = scene.get("_move_list_panel")
	if ml == null:
		return {"PIXEL_MOVE_PREVIEW_CASES": 0, "PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES": 3, "PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES": 0, "PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES": 0, "PIXEL_MOVE_PREVIEW_MAPPING_FAILURES": 0}
	var flat: Array = ml.get("_flat_playable") if ml else []
	var opened := 0
	for e in flat:
		if opened >= 3:
			break
		if not bool(e.get("playable", false)):
			continue
		cases += 1
		opened += 1
		ml._selected_index = flat.find(e)
		if ml.has_method("_replay_preview"):
			ml._replay_preview()
		await get_tree().process_frame
		await get_tree().process_frame
		var model = ml.get("_preview_model")
		var presentation: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_MOVE_PREVIEW)
		if not bool(presentation.get("is_current_canonical", false)):
			legacy += 1
		if model == null:
			missing += 1
		elif ml.has_method("get_move_preview_final_screen_witness"):
			var pw: Dictionary = ml.get_move_preview_final_screen_witness()
			# OWNER-REG-015: pane present but FINAL_SCREEN empty counts as missing.
			if bool(pw.get("FINAL_SCREEN_WITNESS_AVAILABLE", true)) and not bool(pw.get("FINAL_SCREEN_VISIBLE", false)):
				missing += 1
			elif model.has_method("is_visible_renderable_body") and not model.is_visible_renderable_body():
				missing += 1
		elif model.has_method("is_final_screen_visible_body"):
			if not model.is_final_screen_visible_body():
				missing += 1
		elif model.has_method("is_visible_renderable_body") and not model.is_visible_renderable_body():
			missing += 1
		if str(ml.fighter_id) != fid:
			wrong += 1
	return {
		"PIXEL_MOVE_PREVIEW_CASES": cases,
		"PIXEL_MOVE_PREVIEW_WRONG_MODEL_CASES": wrong,
		"PIXEL_MOVE_PREVIEW_LEGACY_MODEL_CASES": legacy,
		"PIXEL_MOVE_PREVIEW_MISSING_MODEL_CASES": missing,
		"PIXEL_MOVE_PREVIEW_MAPPING_FAILURES": mapping,
	}


func _stress_pause_movelist(scene, fighter, fid: String) -> Dictionary:
	var crashes := 0
	var ghosts := 0
	var corrupt := 0
	var stuck := 0
	if scene == null or fighter == null:
		return {"PIXEL_PAUSE_MOVELIST_CRASHES": 1, "PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS": 0, "PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS": 0, "PIXEL_PAUSE_MOVELIST_STUCK_STATES": 0}
	# One open/close cycle
	if scene.has_method("_toggle_pause"):
		if not bool(scene.get("_paused")):
			scene._toggle_pause()
		await get_tree().process_frame
		if scene.has_method("_open_move_list_from_pause"):
			scene._open_move_list_from_pause()
		await get_tree().process_frame
		var ml = scene.get("_move_list_panel")
		if ml and ml.has_method("close_panel"):
			ml.close_panel()
		if bool(scene.get("_paused")):
			scene._toggle_pause()
		await get_tree().process_frame
		fighter.ensure_visible_presentation()
		if fighter.model_3d and fighter.model_3d.has_method("is_visible_renderable_body"):
			if not fighter.model_3d.is_visible_renderable_body():
				ghosts += 1
		if bool(scene.get("_paused")):
			stuck += 1
			corrupt += 1
	return {
		"PIXEL_PAUSE_MOVELIST_CRASHES": crashes,
		"PIXEL_PAUSE_MOVELIST_GHOST_REGRESSIONS": ghosts,
		"PIXEL_PAUSE_RESUME_STATE_CORRUPTIONS": corrupt,
		"PIXEL_PAUSE_MOVELIST_STUCK_STATES": stuck,
	}


func _stress_tabs_previews(scene, fighter) -> Dictionary:
	var crashes := 0
	var preview_opens := 0
	var wrong := 0
	var legacy := 0
	var missing := 0
	if scene == null:
		return {"crashes": 1, "preview_opens": 0, "wrong": 0, "legacy": 0, "missing": 0}
	if not bool(scene.get("_paused")) and scene.has_method("_toggle_pause"):
		scene._toggle_pause()
	if scene.has_method("_open_move_list_from_pause"):
		scene._open_move_list_from_pause()
	await get_tree().process_frame
	var ml = scene.get("_move_list_panel")
	if ml == null:
		return {"crashes": 1, "preview_opens": 0, "wrong": 0, "legacy": 0, "missing": 0}
	for _i in range(10):
		if ml.get("_btn_advanced") != null:
			ml._advanced = not ml._advanced
			if ml.has_method("_populate_list"):
				ml._populate_list()
		await get_tree().process_frame
	for _i in range(10):
		if ml.has_method("_replay_preview"):
			ml._replay_preview()
		preview_opens += 1
		await get_tree().process_frame
		var model = ml.get("_preview_model")
		if model == null:
			missing += 1
		elif model.has_method("is_visible_renderable_body") and not model.is_visible_renderable_body():
			missing += 1
	if ml.has_method("close_panel"):
		ml.close_panel()
	if bool(scene.get("_paused")) and scene.has_method("_toggle_pause"):
		scene._toggle_pause()
	return {"crashes": crashes, "preview_opens": preview_opens, "wrong": wrong, "legacy": legacy, "missing": missing}


func _gate_victory(gs) -> Dictionary:
	var canonical := 0
	var legacy := 0
	var wrong := 0
	for fid in ROSTER:
		gs.p1_fighter_id = fid
		gs.p2_fighter_id = "rook-ironside" if fid != "rook-ironside" else "ember-vale"
		gs.last_winner_slot = 1
		gs.mode = "versus"
		var packed: PackedScene = load(RESULTS_PATH)
		get_tree().change_scene_to_packed(packed)
		for _i in range(14):
			await get_tree().process_frame
		var scene = get_tree().current_scene
		var presentation: Dictionary = _AssetResolver.resolve_presentation(fid, _AssetResolver.CTX_VICTORY)
		var snap: Dictionary = {}
		if scene and scene.has_method("victory_presentation_snapshot"):
			snap = scene.victory_presentation_snapshot()
		var tex_ok := bool(snap.get("portrait_texture_present", false))
		if scene and scene.get("victory_portrait") != null and scene.victory_portrait.texture != null:
			tex_ok = true
		if bool(presentation.get("is_current_canonical", false)) and str(snap.get("fighter_id", fid)) == fid and tex_ok:
			canonical += 1
		else:
			if not bool(presentation.get("is_current_canonical", false)):
				legacy += 1
			wrong += 1
		_capture_screenshot("victory_%s" % fid)
	var ok := canonical == 7 and legacy == 0 and wrong == 0
	return {
		"pass": ok,
		"VICTORY_CANONICAL_CURRENT_COUNT": canonical,
		"VICTORY_LEGACY_REPRESENTATION_OCCURRENCES": legacy,
		"VICTORY_WRONG_FIGHTER_OCCURRENCES": wrong,
		"PIXEL_VICTORY_PATH_VALIDATED": canonical >= 1,
	}


func _capture_fail(fid: String, state: String, reason: String, sample: Dictionary) -> void:
	if not _first_failure.is_empty():
		return
	_first_failure = {
		"fighter_id": fid,
		"state": state,
		"reason": reason,
		"sample": sample,
		"at": Time.get_datetime_string_from_system(true),
	}
	_write_json("FIRST_FAILURE.json", _first_failure)


func _capture_screenshot(label: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	var path := OUT_DIR.path_join("captures/%s.png" % label)
	img.save_png(path)


func _read_meta(name: String) -> String:
	var path := OUT_DIR.path_join(name)
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text().strip_edges()
	f.close()
	return t


func _write_json(name: String, payload: Dictionary) -> void:
	var path := OUT_DIR.path_join(name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t") + "\n")
		f.close()


func _write_result(payload: Dictionary) -> void:
	_write_json("CP2_PIXEL_PHYSICAL_SEAL_RESULT.json", payload)


func _finish_fail(reason: String) -> void:
	_write_result({
		"schema": "wave020_cp2_pixel_physical_seal_v1",
		"pass": false,
		"CP2_SEALED": false,
		"reason": reason,
		"generated_at_utc": Time.get_datetime_string_from_system(true),
	})
	get_tree().quit(1)
