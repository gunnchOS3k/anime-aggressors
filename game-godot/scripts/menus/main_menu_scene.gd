extends ConsoleMenuBase

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Anime Aggressors"

func _on_start_battle_pressed() -> void:
	SceneRouter.go("mode_select")

func _on_training_pressed() -> void:
	SceneRouter.go_training()

func _on_rulesets_pressed() -> void:
	SceneRouter.go("ruleset")

func _on_fighter_vault_pressed() -> void:
	SceneRouter.go("fighter_select")

func _on_stage_vault_pressed() -> void:
	SceneRouter.go("stage_select")

func _on_controls_pressed() -> void:
	SceneRouter.go("controls")

func _on_settings_pressed() -> void:
	SceneRouter.go("settings")

func _on_labs_pressed() -> void:
	SceneRouter.go("labs")

func _on_mobile_playtest_pressed() -> void:
	SceneRouter.go_mobile_playtest()

func footer_hint() -> String:
	return "[A] Select tile   [B] —   Primary Runtime: Godot 4"
