extends Control

## Cold-start title — GitHub Pages energy + rotating fighter cameo.

const PRELOAD_PATHS: Array[String] = [
	"res://data/fighters.json",
	"res://data/stages.json",
	"res://data/rulesets.json",
	"res://assets/placeholder/aa_theme.tres",
]
const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const SILHOUETTE_SCRIPT := preload("res://scripts/ui/fighter_silhouette_card.gd")

var _start_button: Button
var _progress: ProgressBar
var _status: Label
var _title: Label
var _tagline: Label
var _cameo_name: Label
var _cameo_line: Label
var _accent_lines: Array[ColorRect] = []
var _ready_to_start := false
var _transitioning := false
var _roster: Array = []
var _cameo_index: int = 0
var _cameo_model: Node2D
var _cameo_sil: Control
var _cameo_timer: float = 0.0
var _cameo_interval: float = 3.6
var _reduced_motion := false

func _ready() -> void:
	_reduced_motion = bool(ProjectSettings.get_setting("rendering/accessibility/reduce_motion", false))
	if SceneRouter.skip_boot_title:
		_enter_main_menu_immediate()
		return
	_roster = GameState.roster_ids() if GameState else []
	_build_visuals()
	_start_ambient_motion()
	await _preload_resources()
	_present_title_screen()
	_show_cameo(0)

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

	# Cameo stage (right side) — silhouette + optional 3D model
	var cameo_host := Control.new()
	cameo_host.name = "CameoHost"
	cameo_host.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	cameo_host.offset_left = -320.0
	cameo_host.offset_top = -180.0
	cameo_host.offset_right = -40.0
	cameo_host.offset_bottom = 160.0
	add_child(cameo_host)

	_cameo_sil = SILHOUETTE_SCRIPT.new()
	_cameo_sil.name = "CameoSilhouette"
	_cameo_sil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cameo_sil.offset_bottom = -48.0
	cameo_host.add_child(_cameo_sil)

	_cameo_model = MODEL_SCRIPT.new()
	_cameo_model.name = "CameoModel"
	_cameo_model.position = Vector2(140, 210)
	cameo_host.add_child(_cameo_model)

	_cameo_name = Label.new()
	_cameo_name.name = "CameoName"
	_cameo_name.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_cameo_name.offset_top = -44.0
	_cameo_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cameo_name.add_theme_font_size_override("font_size", 20)
	cameo_host.add_child(_cameo_name)

	_cameo_line = Label.new()
	_cameo_line.name = "CameoLine"
	_cameo_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_cameo_line.offset_top = -22.0
	_cameo_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cameo_line.add_theme_font_size_override("font_size", 12)
	_cameo_line.modulate = Color(0.85, 0.9, 1.0, 0.85)
	cameo_host.add_child(_cameo_line)

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

func _process(delta: float) -> void:
	if not _ready_to_start or _transitioning or _reduced_motion:
		return
	if _roster.is_empty():
		return
	_cameo_timer += delta
	if _cameo_timer >= _cameo_interval:
		_cameo_timer = 0.0
		_cameo_index = (_cameo_index + 1) % _roster.size()
		_show_cameo(_cameo_index)

func _show_cameo(index: int) -> void:
	if _roster.is_empty():
		return
	var id: String = _roster[index % _roster.size()]
	var data: Dictionary = GameState.load_fighter(id)
	var life: Dictionary = _CharacterLife.for_id(id)
	var primary := Color(data.get("color", Color(1, 0.5, 0.3)))
	var accent := Color(data.get("auraColor", Color(1, 0.8, 0.2)))
	if _cameo_sil and _cameo_sil.has_method("configure"):
		_cameo_sil.configure(id, primary, accent)
		_cameo_sil.set_focused(true)
	if _cameo_model and _cameo_model.has_method("configure"):
		_cameo_model.configure(data)
		if _cameo_model.has_method("set_select_mode"):
			_cameo_model.set_select_mode(true)
		if _cameo_model.has_method("play_selection_focus"):
			_cameo_model.play_selection_focus()
		if _cameo_model.has_method("set_aura_level"):
			_cameo_model.set_aura_level(2)
	if _cameo_name:
		_cameo_name.text = str(data.get("displayName", id))
	if _cameo_line:
		_cameo_line.text = str(life.get("line", ""))
	# Ambient background shift toward fighter identity
	var bg := $Background as ColorRect
	if bg and not _reduced_motion:
		var target := Color(primary.r * 0.12, primary.g * 0.1, primary.b * 0.16, 1.0)
		create_tween().tween_property(bg, "color", target, 0.45)

func _start_ambient_motion() -> void:
	if _reduced_motion:
		return
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
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.35)
	await out.finished
	SceneRouter.mark_boot_title_shown()
	_enter_main_menu_immediate()

func _enter_main_menu_immediate() -> void:
	SceneRouter.go("main_menu")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		on_back()
		get_viewport().set_input_as_handled()
		return
	if not _ready_to_start or _transitioning:
		return
	if event.is_action_pressed("ui_accept"):
		_on_start_game_pressed()
		get_viewport().set_input_as_handled()


func on_back() -> void:
	var nav := get_node_or_null("/root/NavigationAuthority")
	if nav != null and nav.has_method("request_exit"):
		nav.request_exit()
