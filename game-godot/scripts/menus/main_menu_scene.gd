extends "res://scripts/ui/console_menu_base.gd"

var _ambient_tween: Tween

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Anime Aggressors"
	_start_menu_ambient()

func _start_menu_ambient() -> void:
	# Soft pulse so the hub never looks like a flat static panel.
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = create_tween().set_loops()
	_ambient_tween.tween_property(self, "modulate", Color(1.02, 1.02, 1.06, 1.0), 1.8)
	_ambient_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.8)
	if title_label:
		var title_pulse := create_tween().set_loops()
		title_pulse.tween_property(title_label, "modulate:a", 0.88, 1.4)
		title_pulse.tween_property(title_label, "modulate:a", 1.0, 1.4)

func _on_start_battle_pressed() -> void:
	_press_feedback()
	SceneRouter.go("mode_select")

func _on_training_pressed() -> void:
	_press_feedback()
	SceneRouter.go_training()

func _on_rulesets_pressed() -> void:
	_press_feedback()
	SceneRouter.go("ruleset")

func _on_fighter_vault_pressed() -> void:
	_press_feedback()
	SceneRouter.go("fighter_select")

func _on_stage_vault_pressed() -> void:
	_press_feedback()
	SceneRouter.go("stage_select")

func _on_controls_pressed() -> void:
	_press_feedback()
	SceneRouter.go("controls")

func _on_settings_pressed() -> void:
	_press_feedback()
	SceneRouter.go("settings")

func _on_labs_pressed() -> void:
	_press_feedback()
	SceneRouter.go("labs")

func _on_mobile_playtest_pressed() -> void:
	_press_feedback()
	SceneRouter.go_mobile_playtest()

func _press_feedback() -> void:
	# Soft scale nudge — stands in until dedicated menu SFX bus is wired.
	var tap := create_tween()
	tap.tween_property(self, "scale", Vector2(0.995, 0.995), 0.05)
	tap.tween_property(self, "scale", Vector2.ONE, 0.08)
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(18)

func footer_hint() -> String:
	return "[A] Select tile   [B] —   Primary Runtime: Godot 4"
