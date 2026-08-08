extends "res://scripts/training/training_battle_scene.gd"

## Guided interactive tutorial battle — watches inputs / hits to advance first-run steps.

var _guide: Label
var _steps_done: Dictionary = {}
var _poll_timer: float = 0.0

const ORDER: Array[String] = ["move", "jump", "attack", "special", "aura"]


func _ready() -> void:
	GameState.mode = "tutorial"
	GameState.stage_id = "training-grid"
	GameState.p2_fighter_id = "rook-ironside"
	GameState.training_dummy_mode = "idle"
	GameState.p2_is_cpu = false
	super._ready()
	if fighter2:
		fighter2.dummy_mode = "idle"
		fighter2.is_cpu = false
		fighter2.controls_enabled = false
	_build_guide()
	_refresh_guide()


func _build_guide() -> void:
	_guide = Label.new()
	_guide.name = "TutorialGuide"
	_guide.position = Vector2(24, 16)
	_guide.size = Vector2(700, 140)
	_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guide.add_theme_font_size_override("font_size", 18)
	if hud:
		hud.add_child(_guide)


func _process(delta: float) -> void:
	_poll_timer += delta
	if _poll_timer < 0.08:
		return
	_poll_timer = 0.0
	_poll_steps()


func _poll_steps() -> void:
	if fighter1 == null or fighter1.state_machine == null:
		return
	if absf(fighter1.velocity.x) > 40.0:
		_mark("move")
	var st: String = str(fighter1.state_machine.current_state)
	if st.contains("jump") or st == "double_jump":
		_mark("jump")
	if fighter1.move_runner != null and fighter1.move_runner.active:
		var mid: String = str(fighter1.move_runner.current_move_id())
		if mid.begins_with("special") or st.contains("special"):
			_mark("special")
		elif mid == "aura_burst" or st.contains("aura"):
			_mark("aura")
		elif mid != "":
			_mark("attack")
	if fighter1.aura >= 15.0 or st.contains("aura"):
		_mark("aura")
	_refresh_guide()


func _mark(step_id: String) -> void:
	if _steps_done.has(step_id):
		return
	_steps_done[step_id] = true
	GameState.mark_tutorial_step(step_id)


func _refresh_guide() -> void:
	if _guide == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Tutorial — interactive first-run (Esc = finish)")
	for id in ORDER:
		var done := _steps_done.has(id) or GameState.tutorial_steps_done.has(id)
		lines.append("%s %s" % ["[x]" if done else "[ ]", id.capitalize()])
	var remaining := 0
	for id in ORDER:
		if not (_steps_done.has(id) or GameState.tutorial_steps_done.has(id)):
			remaining += 1
	if remaining == 0:
		lines.append("All steps complete — press Esc to continue.")
		GameState.complete_tutorial()
	_guide.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Engine.time_scale = 1.0
		if _steps_done.size() >= ORDER.size() or GameState.tutorial_steps_done.size() >= ORDER.size():
			GameState.complete_tutorial()
		SceneRouter.go("mode_select")
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
