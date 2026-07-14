extends "res://scripts/ui/console_menu_base.gd"

var _stages: Array = []
var _cursor: int = 0

@onready var grid: GridContainer = %StageGrid
@onready var preview: Label = %Preview
@onready var rules: Label = %RulesSummary

const STAGE_TILE_SCENE := preload("res://scenes/ui/StageTile.tscn")

func _ready() -> void:
	_stages = GameState.production_stage_ids()
	super._ready()
	if title_label:
		title_label.text = "Stage Select"
	_build_grid()
	_refresh()

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
		preview.text = "%s\nLayout: %s" % [data.get("displayName", id), data.get("layoutType", "")]
	if rules:
		rules.text = "Stocks: %d | CPU Lv%d" % [GameState.stocks, GameState.cpu_level]

func _on_confirm_pressed() -> void:
	if _stages.is_empty():
		return
	GameState.stage_id = _stages[_cursor]
	SceneRouter.go("versus")

func on_back() -> void:
	SceneRouter.go("fighter_select")
