extends "res://scripts/ui/console_menu_base.gd"

## Interactive first-run / tutorial mode — step checklist then guided training battle.

@onready var status_label: Label = %StatusLabel
@onready var step_label: Label = %StepLabel

const STEPS: Array[Dictionary] = [
	{"id": "move", "title": "Move", "hint": "Use Left/Right (A/D or stick) to walk the platform."},
	{"id": "jump", "title": "Jump", "hint": "Press Jump (W / South). Short-hop by tapping."},
	{"id": "attack", "title": "Attack", "hint": "Press Attack (J). Try tilt directions."},
	{"id": "special", "title": "Special", "hint": "Press Special (K) for your fighter's unique special."},
	{"id": "aura", "title": "Aura Charge", "hint": "Hold Special+Shield to charge aura, then burst."},
]


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Tutorial"
	GameState.mode = "tutorial"
	GameState.ensure_first_run_loaded()
	_refresh()


func _refresh() -> void:
	var idx: int = clampi(GameState.tutorial_step, 0, STEPS.size() - 1)
	var step: Dictionary = STEPS[idx]
	if step_label:
		step_label.text = "Step %d/%d — %s" % [idx + 1, STEPS.size(), step.get("title", "")]
	if status_label:
		var first := "First-run path active.\n" if GameState.first_run_pending else ""
		status_label.text = "%s%s\n\nComplete steps in the guided battle, or skip to Mode Select.\nNOT Alpha exit — tutorial is Alpha depth." % [
			first,
			step.get("hint", ""),
		]


func _on_start_guided_pressed() -> void:
	GameState.begin_tutorial()
	SceneRouter.go("tutorial_battle")


func _on_next_step_pressed() -> void:
	GameState.tutorial_step = mini(GameState.tutorial_step + 1, STEPS.size() - 1)
	if GameState.tutorial_step >= STEPS.size() - 1 and GameState.tutorial_steps_done.size() >= STEPS.size():
		GameState.complete_tutorial()
	_refresh()


func _on_skip_pressed() -> void:
	GameState.skip_tutorial()
	SceneRouter.go("mode_select")


func on_back() -> void:
	SceneRouter.go("main_menu")
