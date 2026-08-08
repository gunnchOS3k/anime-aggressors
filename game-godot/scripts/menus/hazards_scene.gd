extends "res://scripts/ui/console_menu_base.gd"

## Items / Hazards mode entry — one more playable mode beyond Versus/Training/Arcade.

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Items / Hazards"
	_refresh()


func _refresh() -> void:
	if status_label:
		status_label.text = "Mode: Items + stage hazards\nLane surge pulses + pickup items (aura/heal/surge)\nCPU opponent · PROCEDURAL_FINAL stages\nPainted art still REQUIRES_ART_PRODUCTION"


func _on_start_pressed() -> void:
	GameState.begin_hazards_mode()
	SceneRouter.go("versus")


func _on_change_fighters_pressed() -> void:
	GameState.mode = "hazards"
	GameState.hazards_enabled = true
	GameState.items_enabled = true
	SceneRouter.go("fighter_select")


func on_back() -> void:
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.mode = "versus"
	SceneRouter.go("mode_select")
