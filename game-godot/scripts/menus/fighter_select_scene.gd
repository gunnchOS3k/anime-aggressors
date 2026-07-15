extends "res://scripts/ui/console_menu_base.gd"

const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")
const _Presentation = preload("res://scripts/fighters/fighter_presentation_profile.gd")
const FIGHTER_BUTTON_SCENE := preload("res://scenes/ui/FighterTile.tscn")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")

var _roster: Array = []
var _cursor: int = 0
var _p1_pick: int = 0
var _p2_pick: int = 1
var _selecting_p2: bool = false
var _locked_p1: bool = false
var _preview_model: Node2D
var _tiles: Array = []

@onready var grid: GridContainer = %FighterGrid
@onready var p1_name: Label = %P1Name
@onready var p2_name: Label = %P2Name
@onready var detail: Label = %Detail
@onready var ready_label: Label = %ReadyLabel


func _ready() -> void:
	_roster = GameState.roster_ids()
	super._ready()
	if title_label:
		title_label.text = "Fighter Select"
	_ensure_preview_host()
	_build_grid()
	_refresh()
	_update_preview(_cursor, false)


func _ensure_preview_host() -> void:
	var host := get_node_or_null("%PreviewHost") as Control
	if host == null:
		# Runtime host if scene not yet patched
		host = Control.new()
		host.name = "PreviewHost"
		host.custom_minimum_size = Vector2(240, 280)
		host.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		host.offset_left = -280.0
		host.offset_top = 96.0
		host.offset_right = -40.0
		host.offset_bottom = 376.0
		add_child(host)
	_preview_model = host.get_node_or_null("SelectModel") as Node2D
	if _preview_model == null:
		_preview_model = MODEL_SCRIPT.new()
		_preview_model.name = "SelectModel"
		_preview_model.position = Vector2(120, 200)
		host.add_child(_preview_model)


func _build_grid() -> void:
	_tiles.clear()
	for c in grid.get_children():
		c.queue_free()
	for i in _roster.size():
		var id: String = _roster[i]
		var data: Dictionary = GameState.load_fighter(id)
		var life: Dictionary = _CharacterLife.for_id(id)
		var profile = _Presentation.from_life_dict(id, life, data)
		var tile: Button = FIGHTER_BUTTON_SCENE.instantiate()
		var name_l := tile.get_node_or_null("VBox/NameLabel") as Label
		var arch_l := tile.get_node_or_null("VBox/ArchetypeLabel") as Label
		var sil := tile.get_node_or_null("VBox/Silhouette") as Control
		if name_l:
			name_l.text = str(profile.display_name)
		if arch_l:
			arch_l.text = str(profile.select_archetype)
		if sil and sil.has_method("configure"):
			sil.configure(id, profile.primary_color, profile.accent_color)
		tile.pressed.connect(_on_tile_pressed.bind(i))
		tile.focus_entered.connect(_on_tile_focused.bind(i))
		tile.mouse_entered.connect(_on_tile_focused.bind(i))
		grid.add_child(tile)
		_tiles.append(tile)


func _on_tile_focused(index: int) -> void:
	_cursor = index
	_refresh()
	_update_preview(index, false)
	_set_tile_focus_visuals(index)


func _on_tile_pressed(index: int) -> void:
	_cursor = index
	if _selecting_p2:
		_p2_pick = index
	else:
		_p1_pick = index
		_locked_p1 = true
	_refresh()
	_update_preview(index, true)


func _set_tile_focus_visuals(index: int) -> void:
	for i in _tiles.size():
		var tile: Button = _tiles[i]
		var sil := tile.get_node_or_null("VBox/Silhouette") as Control
		if sil and sil.has_method("set_focused"):
			sil.set_focused(i == index)
		tile.modulate = Color(1.15, 1.15, 1.2, 1.0) if i == index else Color(1, 1, 1, 1)


func _update_preview(index: int, lock_in: bool) -> void:
	if _preview_model == null or index < 0 or index >= _roster.size():
		return
	var id: String = _roster[index]
	var data: Dictionary = GameState.load_fighter(id)
	if _preview_model.has_method("configure"):
		_preview_model.configure(data)
	if _preview_model.has_method("set_select_mode"):
		_preview_model.set_select_mode(true)
	if lock_in and _preview_model.has_method("play_lock_in"):
		_preview_model.play_lock_in()
	elif _preview_model.has_method("play_selection_focus"):
		_preview_model.play_selection_focus()


func _refresh() -> void:
	var p1: Dictionary = GameState.load_fighter(_roster[_p1_pick])
	var p2: Dictionary = GameState.load_fighter(_roster[_p2_pick])
	var focus_id: String = _roster[_cursor]
	var life: Dictionary = _CharacterLife.for_id(focus_id)
	var focus: Dictionary = GameState.load_fighter(focus_id)
	var profile = _Presentation.from_life_dict(focus_id, life, focus)
	if p1_name:
		var lock := " ✓" if _locked_p1 and not _selecting_p2 else ""
		p1_name.text = "P1: %s%s" % [p1.get("displayName", "?"), lock]
	if p2_name:
		p2_name.text = "P2: %s%s" % [p2.get("displayName", "?"), " (CPU)" if GameState.p2_is_cpu else ""]
	if detail:
		var traits: PackedStringArray = profile.personality_traits
		detail.text = "%s  ·  %s\n%s\n\"%s\"\n%s | Wt %d · Run %d · Jump %d\nSig: %s" % [
			profile.power_identity,
			profile.select_archetype,
			" · ".join(traits),
			profile.selection_line,
			focus.get("element", ""),
			int(focus.get("weight", 0)),
			int(focus.get("runSpeed", 0)),
			int(focus.get("jumpStrength", 0)),
			focus.get("signatureMove", ""),
		]
	if ready_label:
		if _selecting_p2:
			ready_label.text = "Face-off: %s  vs  %s" % [
				p1.get("displayName", "?"),
				GameState.load_fighter(_roster[_cursor]).get("displayName", "?"),
			]
		else:
			ready_label.text = "%s — %s" % [profile.display_name, profile.combat_fantasy]


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
