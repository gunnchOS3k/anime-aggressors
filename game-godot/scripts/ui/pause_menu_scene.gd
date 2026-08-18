extends "res://scripts/ui/console_menu_base.gd"

## Standalone pause scene. In-battle pause is BattleScene._toggle_pause (does not reload).
## Resume here reloads Versus only if this scene was entered via SceneRouter.go("pause").

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Paused"

func _on_resume_pressed() -> void:
	SceneRouter.go("battle")

func _on_settings_pressed() -> void:
	SceneRouter.go("settings")

func _on_quit_pressed() -> void:
	SceneRouter.go("main_menu")

func on_back() -> void:
	SceneRouter.go("battle")
