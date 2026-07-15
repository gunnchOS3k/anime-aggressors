extends "res://scripts/ui/console_menu_base.gd"

const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")

var _roster: Array = []
var _cursor: int = 0
var _p1_pick: int = 0
var _p2_pick: int = 1
var _selecting_p2: bool = false
var _locked_p1: bool = false

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
		var life: Dictionary = _CharacterLife.for_id(id)
		var tile: Button = FIGHTER_BUTTON_SCENE.instantiate()
		tile.text = "%s\n%s" % [data.get("displayName", id), life.get("select_archetype", "")]
		tile.pressed.connect(_on_tile_pressed.bind(i))
		tile.focus_entered.connect(_on_tile_focused.bind(i))
		grid.add_child(tile)

func _on_tile_focused(index: int) -> void:
	_cursor = index
	_refresh()

func _on_tile_pressed(index: int) -> void:
	_cursor = index
	if _selecting_p2:
		_p2_pick = index
	else:
		_p1_pick = index
		_locked_p1 = true
	_refresh()

func _refresh() -> void:
	var p1: Dictionary = GameState.load_fighter(_roster[_p1_pick])
	var p2: Dictionary = GameState.load_fighter(_roster[_p2_pick])
	var focus_id: String = _roster[_cursor]
	var life: Dictionary = _CharacterLife.for_id(focus_id)
	var focus: Dictionary = GameState.load_fighter(focus_id)
	if p1_name:
		var lock := " ✓" if _locked_p1 and not _selecting_p2 else ""
		p1_name.text = "P1: %s%s" % [p1.get("displayName", "?"), lock]
	if p2_name:
		p2_name.text = "P2: %s%s" % [p2.get("displayName", "?"), " (CPU)" if GameState.p2_is_cpu else ""]
	if detail:
		var traits: PackedStringArray = []
		for personality_trait in life.get("personality", []):
			traits.append(str(personality_trait))
		detail.text = "%s  ·  %s\n%s\n\"%s\"\n%s | Wt %d · Run %d · Jump %d\nSig: %s" % [
			life.get("power_id", ""),
			life.get("select_archetype", ""),
			" · ".join(traits),
			life.get("line", ""),
			focus.get("element", ""),
			int(focus.get("weight", 0)),
			int(focus.get("runSpeed", 0)),
			int(focus.get("jumpStrength", 0)),
			focus.get("signatureMove", ""),
		]
	if ready_label:
		if _selecting_p2:
			ready_label.text = "Face-off: lock P2 — %s vs %s" % [
				p1.get("displayName", "?"),
				GameState.load_fighter(_roster[_cursor]).get("displayName", "?"),
			]
		else:
			ready_label.text = "Focus %s — %s" % [
				focus.get("displayName", "?"),
				life.get("fantasy", ""),
			]

func _on_toggle_cpu_pressed() -> void:
	GameState.p2_is_cpu = not GameState.p2_is_cpu
	_refresh()

func _on_next_player_pressed() -> void:
	if not _selecting_p2:
		_selecting_p2 = true
		_locked_p1 = true
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
