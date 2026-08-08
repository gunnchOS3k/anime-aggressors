extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Mode Select"

func _on_versus_pressed() -> void:
	GameState.mode = "versus"
	GameState.arcade_active = false
	GameState.team_mode = false
	SceneRouter.go("ruleset")

func _on_training_pressed() -> void:
	GameState.mode = "training"
	GameState.arcade_active = false
	GameState.team_mode = false
	SceneRouter.go_training()

func _on_arcade_pressed() -> void:
	GameState.mode = "arcade"
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.team_mode = false
	SceneRouter.go("arcade")

func _on_tutorial_pressed() -> void:
	GameState.mode = "tutorial"
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.team_mode = false
	SceneRouter.go_tutorial()

func _on_hazards_pressed() -> void:
	GameState.mode = "hazards"
	GameState.team_mode = false
	SceneRouter.go_hazards()

func _on_team_pressed() -> void:
	GameState.mode = "team"
	SceneRouter.go("team")

func _on_challenges_pressed() -> void:
	GameState.mode = "challenges"
	SceneRouter.go("challenges")

func _on_online_pressed() -> void:
	GameState.mode = "online_private"
	SceneRouter.go("online_hub")

func _on_tournament_pressed() -> void:
	GameState.mode = "tournament"
	SceneRouter.go("tournament")

func on_back() -> void:
	SceneRouter.go("main_menu")
