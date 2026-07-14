extends "res://scripts/ui/console_menu_base.gd"

func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Training"
	GameState.stage_id = "training-grid"
	GameState.p2_is_cpu = true

func _on_start_pressed() -> void:
	GameState.p1_fighter_id = GameState.p1_fighter_id if GameState.p1_fighter_id else "ember-vale"
	GameState.p2_fighter_id = "rook-ironside"
	GameState.stocks = 99
	SceneRouter.go("battle")

func on_back() -> void:
	SceneRouter.go("main_menu")
