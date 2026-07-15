extends Node

## Centralized Back / Escape / Android system-back navigation.
## Prevents Android WM_GO_BACK_REQUEST from quitting mid-flow.

var _busy := false
var _exit_armed := false
var _exit_arm_time_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back("android_back")


func handle_back(source: String = "ui_cancel") -> void:
	if _busy:
		return
	_busy = true
	get_tree().create_timer(0.18).timeout.connect(func (): _busy = false)

	var sc := get_tree().current_scene
	if sc == null:
		return

	# Prefer scene-owned on_back / handle_back contracts.
	if sc.has_method("on_back"):
		sc.on_back()
		_exit_armed = false
		return
	if sc.has_method("handle_back"):
		sc.handle_back()
		_exit_armed = false
		return

	_fallback_navigation(sc, source)


func _fallback_navigation(sc: Node, _source: String) -> void:
	var path := String(sc.scene_file_path)
	if path.ends_with("BootScene.tscn"):
		_request_exit()
		return
	if path.ends_with("MainMenuScene.tscn"):
		SceneRouter.go("boot")
		return
	if path.ends_with("ModeSelectScene.tscn"):
		SceneRouter.go("main_menu")
		return
	if path.ends_with("RulesetScene.tscn"):
		SceneRouter.go("main_menu")
		return
	if path.ends_with("FighterSelectScene.tscn"):
		SceneRouter.go("ruleset")
		return
	if path.ends_with("StageSelectScene.tscn"):
		SceneRouter.go("fighter_select")
		return
	if path.ends_with("VersusScene.tscn"):
		# Ignore or soft-cancel to stage select.
		SceneRouter.go("stage_select")
		return
	if path.ends_with("BattleScene.tscn"):
		if sc.has_method("_toggle_pause"):
			sc.call("_ensure_pause_panel")
			sc.call("_toggle_pause")
		return
	if path.ends_with("TrainingBattleScene.tscn"):
		if sc.has_method("_toggle_pause"):
			sc.call("_toggle_pause")
		else:
			SceneRouter.go("training")
		return
	if path.ends_with("ResultsScene.tscn"):
		SceneRouter.go("main_menu")
		return
	if path.ends_with("PauseMenuScene.tscn"):
		SceneRouter.go("battle")
		return
	if (
		path.ends_with("SettingsScene.tscn")
		or path.ends_with("ControlsScene.tscn")
		or path.ends_with("LabsScene.tscn")
		or path.ends_with("TrainingMenuScene.tscn")
		or path.ends_with("TrainingScene.tscn")
		or path.ends_with("MobilePlaytestScene.tscn")
	):
		SceneRouter.go("main_menu")
		return
	# Unknown internal screen — never hard-quit.
	SceneRouter.go("main_menu")


func request_exit() -> void:
	_request_exit()


func _request_exit() -> void:
	var now := Time.get_ticks_msec()
	if _exit_armed and now - _exit_arm_time_msec < 2000:
		get_tree().quit()
		return
	_exit_armed = true
	_exit_arm_time_msec = now
	push_warning("Press Back again to exit Anime Aggressors")
