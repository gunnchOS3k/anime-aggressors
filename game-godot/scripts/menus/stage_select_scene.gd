extends "res://scripts/ui/console_menu_base.gd"

var _stages: Array = []
var _cursor: int = 0
var _preview_tex: TextureRect

@onready var grid: GridContainer = %StageGrid
@onready var preview: Label = %Preview
@onready var rules: Label = %RulesSummary

const STAGE_TILE_SCENE := preload("res://scenes/ui/StageTile.tscn")

func _ready() -> void:
	_stages = GameState.production_stage_ids()
	super._ready()
	if title_label:
		title_label.text = "Stage Select"
	_ensure_preview_texture()
	_build_grid()
	_refresh()

func _ensure_preview_texture() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_preview_tex = vbox.get_node_or_null("StageArtPreview") as TextureRect
	if _preview_tex != null:
		return
	_preview_tex = TextureRect.new()
	_preview_tex.name = "StageArtPreview"
	_preview_tex.custom_minimum_size = Vector2(640, 180)
	_preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vbox.add_child(_preview_tex)
	vbox.move_child(_preview_tex, 2)

func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
	var random_btn := Button.new()
	random_btn.text = "Random"
	random_btn.pressed.connect(_on_random_pressed)
	grid.add_child(random_btn)
	for i in _stages.size():
		var id: String = _stages[i]
		var data: Dictionary = GameState.load_stage(id)
		var tile: Button = STAGE_TILE_SCENE.instantiate()
		tile.text = data.get("displayName", id)
		tile.pressed.connect(_on_stage_pressed.bind(i))
		grid.add_child(tile)

func _on_random_pressed() -> void:
	if _stages.is_empty():
		return
	_cursor = randi() % _stages.size()
	_refresh()

func _on_stage_pressed(index: int) -> void:
	_cursor = index
	_refresh()

func _refresh() -> void:
	if _stages.is_empty():
		return
	var id: String = _stages[_cursor]
	var data: Dictionary = GameState.load_stage(id)
	if preview:
		preview.text = "%s\nLayout: %s\nArt: %s" % [
			data.get("displayName", id),
			data.get("layoutType", ""),
			data.get("artStatus", ""),
		]
	if rules:
		rules.text = "Stocks: %d | CPU Lv%d" % [GameState.stocks, GameState.cpu_level]
	_load_stage_preview(data)

func _load_stage_preview(data: Dictionary) -> void:
	if _preview_tex == null:
		return
	var path := str(data.get("previewPlaceholder", ""))
	_preview_tex.texture = null
	if path.is_empty():
		return
	if ResourceLoader.exists(path):
		_preview_tex.texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		# Import sidecars should make ResourceLoader succeed; FileAccess proves asset present.
		_preview_tex.modulate = Color(0.7, 0.85, 1.0, 1.0)

func _on_confirm_pressed() -> void:
	if _stages.is_empty():
		return
	GameState.stage_id = _stages[_cursor]
	SceneRouter.go("versus")

func on_back() -> void:
	SceneRouter.go("fighter_select")
