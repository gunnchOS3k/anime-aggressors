extends Control

## Cold-start title screen — mirrors GitHub Pages energy: animated backdrop, title, Start Game CTA.

const PRELOAD_PATHS: Array[String] = [
	"res://data/fighters.json",
	"res://data/stages.json",
	"res://data/rulesets.json",
	"res://assets/placeholder/aa_theme.tres",
]

var _start_button: Button
var _progress: ProgressBar
var _status: Label
var _title: Label
var _tagline: Label
var _accent_lines: Array[ColorRect] = []
var _ready_to_start := false
var _transitioning := false

func _ready() -> void:
	if SceneRouter.skip_boot_title:
		_enter_main_menu_immediate()
		return
	_build_visuals()
	_start_ambient_motion()
	await _preload_resources()
	_present_title_screen()

func _build_visuals() -> void:
	var bg := $Background as ColorRect
	if bg:
		bg.color = Color(0.04, 0.05, 0.11, 1.0)

	_title = $Title as Label
	if _title:
		_title.text = "ANIME AGGRESSORS"
		_title.modulate.a = 0.0

	_tagline = $Subtitle as Label
	if _tagline:
		_tagline.text = "Create Your Legend"
		_tagline.modulate.a = 0.0

	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_status.offset_top = -120.0
	_status.offset_bottom = -96.0
	_status.offset_left = -240.0
	_status.offset_right = 240.0
	_status.text = "Preparing arena..."
	add_child(_status)

	_progress = ProgressBar.new()
	_progress.name = "LoadProgress"
	_progress.show_percentage = false
	_progress.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_progress.offset_top = -88.0
	_progress.offset_bottom = -72.0
	_progress.offset_left = -200.0
	_progress.offset_right = 200.0
	_progress.max_value = PRELOAD_PATHS.size()
	_progress.value = 0.0
	_progress.visible = false
	add_child(_progress)

	_start_button = Button.new()
	_start_button.name = "StartGame"
	_start_button.text = "Start Game"
	_start_button.custom_minimum_size = Vector2(320, 72)
	_start_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_start_button.offset_top = -200.0
	_start_button.offset_bottom = -128.0
	_start_button.offset_left = -160.0
	_start_button.offset_right = 160.0
	_start_button.visible = false
	_start_button.pressed.connect(_on_start_game_pressed)
	add_child(_start_button)

	for i in 3:
		var line := ColorRect.new()
		line.color = Color(0.35, 0.55, 0.95, 0.18)
		line.custom_minimum_size = Vector2(900, 2)
		line.position = Vector2(-450 + float(i) * 40.0, 120.0 + float(i) * 80.0)
		line.pivot_offset = line.custom_minimum_size * 0.5
		line.set_anchors_preset(Control.PRESET_CENTER)
		add_child(line)
		_accent_lines.append(line)

func _start_ambient_motion() -> void:
	var bg := $Background as ColorRect
	if bg:
		var tween := create_tween().set_loops()
		tween.tween_property(bg, "color", Color(0.06, 0.08, 0.16, 1.0), 2.4)
		tween.tween_property(bg, "color", Color(0.04, 0.05, 0.11, 1.0), 2.4)

	for i in _accent_lines.size():
		var line := _accent_lines[i]
		var drift := create_tween().set_loops()
		drift.tween_property(line, "position:x", line.position.x + 28.0, 1.6 + float(i) * 0.2)
		drift.tween_property(line, "position:x", line.position.x - 28.0, 1.6 + float(i) * 0.2)

func _preload_resources() -> void:
	if PRELOAD_PATHS.is_empty():
		return
	_progress.visible = true
	_status.text = "Loading fighters and stages..."
	for i in PRELOAD_PATHS.size():
		var path: String = PRELOAD_PATHS[i]
		if ResourceLoader.exists(path):
			ResourceLoader.load(path)
		_progress.value = float(i + 1)
		await get_tree().process_frame
	_progress.visible = false

func _present_title_screen() -> void:
	_status.text = ""
	var intro := create_tween()
	if _title:
		intro.parallel().tween_property(_title, "modulate:a", 1.0, 0.55)
	if _tagline:
		intro.parallel().tween_property(_tagline, "modulate:a", 1.0, 0.65).set_delay(0.15)
	await intro.finished
	_ready_to_start = true
	_start_button.visible = true
	_start_button.modulate.a = 0.0
	var btn_tween := create_tween()
	btn_tween.tween_property(_start_button, "modulate:a", 1.0, 0.35)
	_start_button.grab_focus()

func _on_start_game_pressed() -> void:
	if _transitioning or not _ready_to_start:
		return
	_transitioning = true
	_start_button.disabled = true
	if Input.is_action_pressed("ui_accept") == false:
		# Audible feedback when audio bus exists
		pass
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.35)
	await out.finished
	SceneRouter.mark_boot_title_shown()
	_enter_main_menu_immediate()

func _enter_main_menu_immediate() -> void:
	SceneRouter.go("main_menu")

func _unhandled_input(event: InputEvent) -> void:
	if not _ready_to_start or _transitioning:
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_game_pressed()
		get_viewport().set_input_as_handled()
