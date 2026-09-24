extends "res://scripts/ui/console_menu_base.gd"

## Pixel / owner full-roster art review route. Dev-only when staging flags are on.
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _Resolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _Overlay := preload("res://scripts/visual/art_source_review_overlay.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]
const ACTIONS := ["idle", "walk", "run", "charge", "heavy", "hurt", "super", "clash"]
const SPEEDS := [1.0, 0.5, 0.25]

var _index: int = 0
var _action_index: int = 0
var _speed_index: int = 0
var _preview: Node2D
var _name_label: Label
var _action_label: Label
var _speed_label: Label
var _mode_label: Label
var _overlay: CanvasLayer


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Full Roster Art Review"
	_overlay = _Overlay.new()
	_overlay.name = "ArtSourceReviewOverlay"
	add_child(_overlay)
	_ensure_preview()
	_apply_review_speed()
	_refresh()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func footer_hint() -> String:
	return "Mode A baseline — accepted/fallback art. Not a human-candidate review. [A] action  [LB/RB] fighter  [Y] speed"


func on_back() -> void:
	Engine.time_scale = 1.0
	SceneRouter.go("fighter_select")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_cycle_action(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_page_down"):
		_next_fighter()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_page_up"):
		_index = (_index - 1 + FIGHTERS.size()) % FIGHTERS.size()
		_action_index = 0
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_text_completion_replace") or event.is_action_pressed("p1_special"):
		_cycle_speed()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func _next_fighter() -> void:
	_index = (_index + 1) % FIGHTERS.size()
	_action_index = 0
	_refresh()


func _cycle_action(delta: int) -> void:
	_action_index = (_action_index + delta + ACTIONS.size()) % ACTIONS.size()
	_refresh()


func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_apply_review_speed()
	_refresh()


func _apply_review_speed() -> void:
	## Review-only. Restored on back / exit. Does not change production defaults.
	Engine.time_scale = float(SPEEDS[_speed_index])


func _ensure_preview() -> void:
	_mode_label = Label.new()
	_mode_label.name = "ModeABanner"
	_mode_label.add_theme_font_size_override("font_size", 16)
	_mode_label.text = "MODE A INTEGRATION BASELINE — Candidate 0/7  Validated 0/7  Owner approved 0/7"
	_mode_label.position = Vector2(48, 64)
	add_child(_mode_label)
	_name_label = Label.new()
	_name_label.name = "FighterName"
	_name_label.add_theme_font_size_override("font_size", 28)
	add_child(_name_label)
	_name_label.position = Vector2(48, 96)
	_action_label = Label.new()
	_action_label.name = "ActionName"
	_action_label.add_theme_font_size_override("font_size", 22)
	add_child(_action_label)
	_action_label.position = Vector2(48, 140)
	_speed_label = Label.new()
	_speed_label.name = "ReviewSpeed"
	_speed_label.add_theme_font_size_override("font_size", 18)
	_speed_label.position = Vector2(48, 176)
	add_child(_speed_label)
	var next_btn := Button.new()
	next_btn.name = "NextFighter"
	next_btn.text = "Next Fighter"
	next_btn.position = Vector2(48, 560)
	next_btn.custom_minimum_size = Vector2(200, 48)
	next_btn.pressed.connect(_next_fighter)
	add_child(next_btn)
	var prev_btn := Button.new()
	prev_btn.name = "PrevFighter"
	prev_btn.text = "Prev Fighter"
	prev_btn.position = Vector2(260, 560)
	prev_btn.custom_minimum_size = Vector2(200, 48)
	prev_btn.pressed.connect(func() -> void:
		_index = (_index - 1 + FIGHTERS.size()) % FIGHTERS.size()
		_action_index = 0
		_refresh()
	)
	add_child(prev_btn)
	var speed_btn := Button.new()
	speed_btn.name = "ReviewSpeedToggle"
	speed_btn.text = "Speed 1.0x / 0.5x / 0.25x"
	speed_btn.position = Vector2(48, 616)
	speed_btn.custom_minimum_size = Vector2(412, 44)
	speed_btn.pressed.connect(_cycle_speed)
	add_child(speed_btn)
	var action_row := HBoxContainer.new()
	action_row.name = "ActionButtons"
	action_row.position = Vector2(48, 216)
	action_row.add_theme_constant_override("separation", 8)
	add_child(action_row)
	for i in ACTIONS.size():
		var action_name: String = ACTIONS[i]
		var btn := Button.new()
		btn.name = "Action_%s" % action_name
		btn.text = action_name
		btn.custom_minimum_size = Vector2(88, 40)
		var captured := i
		btn.pressed.connect(func() -> void:
			_action_index = captured
			_refresh()
		)
		action_row.add_child(btn)
	var host := Control.new()
	host.name = "PreviewHost"
	host.position = Vector2(420, 80)
	host.custom_minimum_size = Vector2(360, 420)
	add_child(host)
	_preview = MODEL_SCRIPT.new()
	_preview.name = "ReviewPreview"
	host.add_child(_preview)


func _refresh() -> void:
	var fighter_id: String = FIGHTERS[_index]
	var action: String = ACTIONS[_action_index]
	if _name_label:
		_name_label.text = "%d / 7  %s" % [_index + 1, fighter_id]
	if _action_label:
		_action_label.text = "Action: %s" % action
	if _speed_label:
		_speed_label.text = "Review speed: %.2fx (dev/review only)" % SPEEDS[_speed_index]
	if _overlay and _overlay.has_method("set_fighter"):
		_overlay.set_fighter(fighter_id)
	var data := {"id": fighter_id}
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and gs.has_method("load_fighter"):
			data = gs.load_fighter(fighter_id)
	if _preview and _preview.has_method("configure"):
		_preview.configure(data)
	if _preview and _preview.has_method("play_clip"):
		_preview.play_clip(action)
