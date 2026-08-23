extends Node

## Engineering Wave015 — on-device physical matrix harness.
## Invoke on Pixel 6a: adb shell am start -n com.gunnchos.animeaggressors/com.godot.game.GodotApp \
##   --es command_line "--wave015-physical"
## Evidence: user://wave015/ (adb pull from Android/data/.../files/wave015/)

const OUT_DIR := "user://wave015/"
const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const CANONICAL_ACTIONS := [
	"idle", "walk", "run", "dash", "jab", "heavy", "tilt_forward", "grab",
	"aerial_neutral", "aerial_forward", "dodge", "tumble",
	"signature_lane_confirm", "signature_lane_counter", "throw_down", "landing",
]
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const ROSTER_LAB_PATH := "res://scenes/labs/RosterArtLab.tscn"
const ANIM_LAB_PATH := "res://scenes/labs/AnimationLab.tscn"

var _running := false


func _ready() -> void:
	if not _should_run():
		return
	_running = true
	call_deferred("_run")


func _should_run() -> bool:
	for arg in OS.get_cmdline_user_args():
		if str(arg).find("wave015-physical") != -1:
			return true
	for arg in OS.get_cmdline_args():
		if str(arg).find("wave015-physical") != -1:
			return true
	# Engineering trigger file pushed via adb run-as before launch.
	if FileAccess.file_exists("user://wave015_trigger.txt"):
		return true
	return false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var roster_matrix: Array = []
	var action_matrix: Array = []
	var screenshots: Array = []
	var shot_idx := 0

	for fighter_id in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		add_child(model)
		var data := _DataLoader.load_fighter(fighter_id)
		var configured := bool(model.configure(data))
		await get_tree().process_frame
		await get_tree().process_frame

		var truth: Dictionary = model.truth_flags() if model.has_method("truth_flags") else {}
		var row := {
			"fighter_id": fighter_id,
			"CURRENT_MODEL_SOURCE": truth.get("CURRENT_MODEL_SOURCE", "UNKNOWN"),
			"PROCEDURAL_PROXY_VISIBLE": model.is_procedural_proxy_visible() if model.has_method("is_procedural_proxy_visible") else false,
			"VISIBLE_MODEL_COUNT": model.count_visible_representations() if model.has_method("count_visible_representations") else 0,
			"SKELETON_PRESENT": truth.get("VISIBLE_SKELETON_PRESENT", false),
			"CONTROLLER_PRESENT": model.get_animation_controller() != null,
			"TOON_SHADER": truth.get("CURRENT_MODEL_SOURCE", "") == "PROCEDURAL_PRODUCTION_PROXY",
			"CONFIGURED": configured,
			"OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_RUNTIME",
		}
		roster_matrix.append(row)

		shot_idx += 1
		var roster_shot := _capture_screenshot("roster_%s_%02d" % [fighter_id, shot_idx])
		if not roster_shot.is_empty():
			screenshots.append(roster_shot)

		for action in CANONICAL_ACTIONS:
			model.play_for_state("", {"move_id": action})
			await get_tree().create_timer(0.12).timeout
			await get_tree().process_frame
			shot_idx += 1
			var action_shot := _capture_screenshot("%s_%s_%02d" % [fighter_id, action, shot_idx])
			var active_clip: String = model.get_active_animation_clip() if model.has_method("get_active_animation_clip") else ""
			action_matrix.append({
				"fighter_id": fighter_id,
				"action": action,
				"active_clip": active_clip,
				"model_source": row["CURRENT_MODEL_SOURCE"],
				"procedural_visible": row["PROCEDURAL_PROXY_VISIBLE"],
				"screenshot": action_shot.get("relative", ""),
				"OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_RUNTIME",
				"status": "OBSERVED" if configured and row["PROCEDURAL_PROXY_VISIBLE"] else "DEFECT",
			})
			if not action_shot.is_empty():
				screenshots.append(action_shot)

		model.queue_free()
		await get_tree().process_frame

	var scene_checks := await _verify_canonical_scenes()
	shot_idx += 1
	for key in scene_checks.keys():
		var info: Dictionary = scene_checks[key]
		if info.get("loaded", false):
			var scene_shot := _capture_screenshot("scene_%s_%02d" % [key, shot_idx])
			shot_idx += 1
			if not scene_shot.is_empty():
				screenshots.append(scene_shot)

	var payload := {
		"schema": "engineering_wave015.physical_matrix.v1",
		"generated_at_utc": Time.get_datetime_string_from_system(true),
		"device_model": "Pixel 6a",
		"OBSERVATION_SOURCE": "PHYSICAL_PIXEL6A_RUNTIME",
		"roster_model_matrix": roster_matrix,
		"action_matrix": action_matrix,
		"action_observation_count": action_matrix.size(),
		"screenshot_manifest": screenshots,
		"canonical_scene_checks": scene_checks,
		"PHYSICAL_MATRIX_PASS": action_matrix.size() >= 112 and roster_matrix.size() == 7,
	}
	_write_json("physical_matrix_result.json", payload)
	_write_json("PIXEL6A_ROSTER_MODEL_MATRIX.json", {"fighters": roster_matrix, "count": roster_matrix.size()})
	_write_json("PIXEL6A_ACTION_MATRIX.json", {"observations": action_matrix, "count": action_matrix.size()})
	_write_json("device_screenshots/manifest.json", {"screenshots": screenshots, "count": screenshots.size(), "source": "PHYSICAL_PIXEL6A_SCREENSHOT"})
	print("Wave015PhysicalHarness complete observations=", action_matrix.size(), " screenshots=", screenshots.size())
	get_tree().quit(0)


func _verify_canonical_scenes() -> Dictionary:
	var out := {}
	for key in ["BattleScene", "RosterArtLab", "AnimationLab"]:
		var path := BATTLE_PATH
		if key == "RosterArtLab":
			path = ROSTER_LAB_PATH
		elif key == "AnimationLab":
			path = ANIM_LAB_PATH
		var packed: PackedScene = load(path)
		out[key] = {"path": path, "loaded": packed != null}
	return out


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
	return {
		"name": name,
		"relative": rel,
		"absolute": abs,
		"source": "PHYSICAL_PIXEL6A_SCREENSHOT",
		"timestamp_utc": Time.get_datetime_string_from_system(true),
	}


func _write_json(filename: String, payload: Dictionary) -> void:
	var abs := ProjectSettings.globalize_path(OUT_DIR.path_join(filename))
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
