extends "res://scripts/ui/console_menu_base.gd"

## Arcade ladder entry — pick fighter, then climb all 7 CPU opponents.

@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Arcade Ladder"
	_refresh()


func _refresh() -> void:
	var p1: Dictionary = GameState.load_fighter(GameState.p1_fighter_id)
	if status_label:
		status_label.text = "Fighter: %s\nOpponents: 7 CPU bouts (Alpha ladder)\nStages: greybox — REQUIRES_ART_PRODUCTION\nNOT content-complete / NOT RC" % p1.get("displayName", GameState.p1_fighter_id)


func _on_change_fighter_pressed() -> void:
	GameState.mode = "arcade"
	SceneRouter.go("fighter_select")


func _on_start_pressed() -> void:
	GameState.begin_arcade(GameState.p1_fighter_id)
	SceneRouter.go("versus")


func on_back() -> void:
	GameState.arcade_active = false
	GameState.mode = "versus"
	SceneRouter.go("mode_select")
