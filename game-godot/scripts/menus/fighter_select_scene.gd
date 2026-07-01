extends ConsoleMenuBase

var _roster: Array = []
var _cursor: int = 0
var _p1_pick: int = 0
var _p2_pick: int = 1
var _selecting_p2: bool = false

@onready var grid: GridContainer = %FighterGrid
@onready var p1_name: Label = %P1Name
@onready var p2_name: Label = %P2Name
@onready var detail: Label = %Detail
@onready var ready_label: Label = %ReadyLabel

const FIGHTER_BUTTON_SCENE := preload("res://scenes/ui/FighterTile.tscn")

func _ready() -> void:
	_roster = GameState.roster_ids()
	super._ready()
	if title_label:
		title_label.text = "Fighter Select"
	_build_grid()
	_refresh()

func _build_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in _roster.size():
		var id: String = _roster[i]
		var data: Dictionary = GameState.load_fighter(id)
		var tile: Button = FIGHTER_BUTTON_SCENE.instantiate()
		tile.text = data.get("displayName", id)
		tile.pressed.connect(_on_tile_pressed.bind(i))
		grid.add_child(tile)

func _on_tile_pressed(index: int) -> void:
	_cursor = index
	if _selecting_p2:
		_p2_pick = index
	else:
		_p1_pick = index
	_refresh()

func _refresh() -> void:
	var p1: Dictionary = GameState.load_fighter(_roster[_p1_pick])
	var p2: Dictionary = GameState.load_fighter(_roster[_p2_pick])
	if p1_name:
		p1_name.text = "P1: %s" % p1.get("displayName", "?")
	if p2_name:
		p2_name.text = "P2: %s%s" % [p2.get("displayName", "?"), " (CPU)" if GameState.p2_is_cpu else ""]
	if detail:
		var d: Dictionary = GameState.load_fighter(_roster[_cursor])
		detail.text = "%s | %s | W:%d Run:%d J:%d\nSig: %s" % [
			d.get("archetype", ""),
			d.get("element", ""),
			d.get("weight", 0),
			int(d.get("runSpeed", 0)),
			int(d.get("jumpStrength", 0)),
			d.get("signatureMove", "")
		]
	if ready_label:
		ready_label.text = "Select P2" if _selecting_p2 else "Select P1"

func _on_toggle_cpu_pressed() -> void:
	GameState.p2_is_cpu = not GameState.p2_is_cpu
	_refresh()

func _on_next_player_pressed() -> void:
	if not _selecting_p2:
		_selecting_p2 = true
		_refresh()
	else:
		GameState.p1_fighter_id = _roster[_p1_pick]
		GameState.p2_fighter_id = _roster[_p2_pick]
		GameState.p1_ready = true
		GameState.p2_ready = true
		SceneRouter.go("stage_select")

func on_back() -> void:
	if _selecting_p2:
		_selecting_p2 = false
		_refresh()
	else:
		SceneRouter.go("ruleset")
