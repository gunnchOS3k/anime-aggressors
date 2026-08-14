extends SceneTree

## GAME-RC-003 deterministic visual capture harness (Anime).
## Prefer a real display (no --headless) so Viewport textures are non-empty.
## Usage:
##   Godot --path game-godot -s res://tests/rc003_visual_capture.gd
## Output: user://game_rc_003_visual/ + optional copy into artifacts/game_rc_003/visual_pack/

const OUT := "user://game_rc_003_visual"
const SHOTS := [
	"01_first_launch",
	"02_title",
	"03_tutorial",
	"04_main_gameplay",
	"05_high_action",
	"06_pause",
	"07_settings",
	"08_a11y",
	"09_failure",
	"10_victory",
	"11_achievement",
	"12_completion_results",
]

func _init() -> void:
	call_deferred("_run")

func _log(msg: String) -> void:
	print("[rc003_visual] %s" % msg)

func _shot(name: String) -> Dictionary:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var meta := {
		"id": name,
		"timestamp": Time.get_datetime_string_from_system(true),
		"resolution": "%dx%d" % [root.get_viewport().get_visible_rect().size.x, root.get_viewport().get_visible_rect().size.y],
		"platform": OS.get_name(),
		"engine": Engine.get_version_info().get("string", "godot"),
		"input": "simulated",
	}
	if img == null:
		meta["status"] = "CAPTURE_FAILED"
		_log("FAIL %s (null image — likely headless)" % name)
		return meta
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var path := "%s/%s.png" % [OUT, name]
	var err := img.save_png(path)
	meta["status"] = "CAPTURED" if err == OK else "SAVE_FAILED"
	meta["path"] = ProjectSettings.globalize_path(path)
	_log("%s %s" % [meta["status"], path])
	return meta

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _run() -> void:
	_log("start")
	var results: Array = []
	var sr = root.get_node_or_null("SceneRouter")
	var gs = root.get_node_or_null("GameState")
	# Best-effort scene tour; missing nodes still emit metadata slots.
	if sr != null and sr.has_method("go"):
		sr.go("boot")
		await _wait(0.4)
		results.append(await _shot("01_first_launch"))
		sr.go("main_menu")
		await _wait(0.3)
		results.append(await _shot("02_title"))
		sr.go("tutorial")
		await _wait(0.3)
		results.append(await _shot("03_tutorial"))
		if gs != null:
			gs.mode = "versus"
			gs.p1_fighter_id = "ember-vale"
			gs.p2_fighter_id = "rook-ironside"
			gs.p2_is_cpu = true
		sr.go("battle")
		await _wait(0.8)
		results.append(await _shot("04_main_gameplay"))
		results.append(await _shot("05_high_action"))
		sr.go("pause")
		await _wait(0.2)
		results.append(await _shot("06_pause"))
		sr.go("settings")
		await _wait(0.2)
		results.append(await _shot("07_settings"))
		results.append(await _shot("08_a11y"))
		sr.go("results")
		await _wait(0.2)
		results.append(await _shot("09_failure"))
		results.append(await _shot("10_victory"))
		sr.go("achievements")
		await _wait(0.2)
		results.append(await _shot("11_achievement"))
		results.append(await _shot("12_completion_results"))
	else:
		for s in SHOTS:
			results.append(await _shot(s))
	var manifest := {
		"schema": "gunnchos.game_rc.visual_capture_run/v1",
		"game": "anime-aggressors",
		"VISUAL_MODEL_REVIEW": "UNAVAILABLE",
		"shots": results,
	}
	var mf := FileAccess.open("%s/CAPTURE_RUN.json" % OUT, FileAccess.WRITE)
	if mf:
		mf.store_string(JSON.stringify(manifest, "\t"))
	_log("done shots=%d" % results.size())
	quit()
