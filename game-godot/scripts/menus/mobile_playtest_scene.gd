extends Control

## Fast mobile playtest entry — reach combat in two taps from boot on touch devices.

@onready var title_label: Label = %Title
@onready var feedback_label: Label = %FeedbackLink

const FEEDBACK_URL := "https://github.com/gunnchOS3k/anime-aggressors/issues/new/choose"

func _ready() -> void:
	if title_label:
		title_label.text = "Mobile Playtest"
	if feedback_label:
		feedback_label.text = "Feedback: %s" % FEEDBACK_URL

func _on_quick_training_pressed() -> void:
	_apply_training_defaults()
	SceneRouter.go("training_battle")

func _on_versus_cpu_pressed() -> void:
	_apply_versus_cpu_defaults()
	SceneRouter.go("battle")

func _on_controls_pressed() -> void:
	SceneRouter.go("controls")

func _on_settings_pressed() -> void:
	SceneRouter.go("settings")

func _on_full_menu_pressed() -> void:
	SceneRouter.go("main_menu")

func _on_feedback_pressed() -> void:
	OS.shell_open(FEEDBACK_URL)

func _apply_training_defaults() -> void:
	GameState.p1_fighter_id = "ember-vale"
	GameState.p2_fighter_id = "rook-ironside"
	GameState.stage_id = "training-grid"
	GameState.training_dummy_mode = "idle"
	GameState.p2_is_cpu = false

func _apply_versus_cpu_defaults() -> void:
	GameState.p1_fighter_id = "ember-vale"
	GameState.p2_fighter_id = "juno-spark"
	GameState.p2_is_cpu = true
	GameState.cpu_level = 2
	GameState.stage_id = "skyline-arena"
	GameState.stocks = 3
	GameState.match_type = "stock"
	GameState.ruleset_id = "stock-3"
