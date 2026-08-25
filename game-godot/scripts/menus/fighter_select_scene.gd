extends "res://scripts/ui/console_menu_base.gd"

const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")
const _Presentation = preload("res://scripts/fighters/fighter_presentation_profile.gd")
const FIGHTER_BUTTON_SCENE := preload("res://scenes/ui/FighterTile.tscn")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")

var _roster: Array = []
var _cursor: int = 0
var _p1_pick: int = 0
var _p2_pick: int = 1
var _selecting_p2: bool = false
var _locked_p1: bool = false
var _preview_model: Node2D
var _tiles: Array = []
## Wave018: cancel superseded preview swaps (focus before previous configure resolves).
var _preview_generation: int = 0
var _preview_fighter_id: String = ""
var _preview_failures: int = 0
## Wave020: track full-roster browse cycles for proactive preview recycle.
var _preview_browse_count: int = 0
var _preview_pending_index: int = -1
var _preview_pending_lock: bool = false
var _move_list_panel: Control
var _move_list_btn: Button

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
	_ensure_select_move_list_button()


func _ensure_select_move_list_button() -> void:
	if _move_list_btn != null:
		return
	_move_list_btn = Button.new()
	_move_list_btn.text = "Command Guide"
	_move_list_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_move_list_btn.position = Vector2(24, 640)
	_move_list_btn.pressed.connect(_open_select_move_list)
	add_child(_move_list_btn)


func _open_select_move_list() -> void:
	if _move_list_panel == null or not is_instance_valid(_move_list_panel):
		_move_list_panel = MOVE_LIST_PANEL.new()
		_move_list_panel.name = "SelectMoveList"
		add_child(_move_list_panel)
	var fid := str(_roster[_cursor]) if _roster.size() > 0 else "ember-vale"
	_move_list_panel.open_for_fighter(fid)


func _exit_tree() -> void:
	# Tear down preview so battle never inherits a stale SubViewport/cache.
	_teardown_preview()


func _teardown_preview() -> void:
	_preview_generation += 1
	if _preview_model != null and is_instance_valid(_preview_model):
		_preview_model.queue_free()
	_preview_model = null
	_preview_fighter_id = ""


func _ensure_preview_host() -> void:
	var host := get_node_or_null("%PreviewHost") as Control
	if host == null:
		# Runtime host if scene not yet patched
		host = Control.new()
		host.name = "PreviewHost"
		host.custom_minimum_size = Vector2(300, 380)
		host.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		host.offset_left = -340.0
		host.offset_top = 72.0
		host.offset_right = -40.0
		host.offset_bottom = 460.0
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(host)
	else:
		host.custom_minimum_size = Vector2(300, 380)
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_model = host.get_node_or_null("SelectModel") as Node2D
	if _preview_model == null or not is_instance_valid(_preview_model):
		_preview_model = MODEL_SCRIPT.new()
		_preview_model.name = "SelectModel"
		_preview_model.position = Vector2(150, 240)
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
	_schedule_preview_update(index, false)
	_set_tile_focus_visuals(index)


func _schedule_preview_update(index: int, lock_in: bool) -> void:
	_preview_pending_index = index
	_preview_pending_lock = lock_in
	if not is_node_ready():
		return
	call_deferred("_flush_preview_update")


func _flush_preview_update() -> void:
	if _preview_pending_index < 0:
		return
	var idx := _preview_pending_index
	var lock := _preview_pending_lock
	_preview_pending_index = -1
	_update_preview(idx, lock)


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
	_preview_generation += 1
	var gen := _preview_generation
	_preview_browse_count += 1
	_ensure_preview_host()
	if _preview_model == null or not is_instance_valid(_preview_model):
		_preview_failures += 1
		push_warning("SelectPreview: model host missing gen=%d" % gen)
		return
	if index < 0 or index >= _roster.size():
		return
	var id: String = _roster[index]
	# Wave020: after each full-roster sweep, hard-recycle preview host (owner P0 after ~6 browses).
	if _preview_browse_count > 0 and _preview_browse_count % 7 == 0:
		_recreate_preview_model()
		if gen != _preview_generation:
			return
		if _preview_model.has_method("refresh_viewport_texture"):
			_preview_model.refresh_viewport_texture(true)
	var data: Dictionary = GameState.load_fighter(id)
	# Reuse cache when same fighter + already renderable (hold/reselect).
	var same: bool = id == _preview_fighter_id
	var already_ok: bool = same and _preview_model.has_method("is_visible_renderable_body") and bool(_preview_model.is_visible_renderable_body())
	if not already_ok:
		var ok := false
		if _preview_model.has_method("configure"):
			ok = bool(_preview_model.configure(data))
		if gen != _preview_generation:
			return  # superseded by newer cursor/select
		if not ok:
			_preview_failures += 1
			push_warning("SelectPreview: configure failed fighter=%s gen=%d — attempting heal/fallback" % [id, gen])
			if _preview_model.has_method("heal_visibility_if_needed"):
				_preview_model.heal_visibility_if_needed()
			# One hard recreate if still dead (corrupted SubViewport / stuck false).
			if not (_preview_model.has_method("is_visible_renderable_body") and _preview_model.is_visible_renderable_body()):
				_recreate_preview_model()
				if gen != _preview_generation:
					return
				if _preview_model.has_method("configure"):
					ok = bool(_preview_model.configure(data))
				if not ok:
					push_warning("SelectPreview: recoverable fallback still failed fighter=%s" % id)
	if gen != _preview_generation:
		return
	_preview_fighter_id = id
	if _preview_model.has_method("set_select_mode"):
		_preview_model.set_select_mode(true)
	if _preview_model.has_method("heal_visibility_if_needed"):
		_preview_model.heal_visibility_if_needed()
	if _preview_model.has_method("_enforce_exactly_one_visible_body"):
		_preview_model._enforce_exactly_one_visible_body()
	_emit_preview_visibility_telemetry()
	if lock_in and _preview_model.has_method("play_lock_in"):
		_preview_model.play_lock_in()
	elif _preview_model.has_method("play_selection_focus"):
		_preview_model.play_selection_focus()


func _recreate_preview_model() -> void:
	var host := get_node_or_null("%PreviewHost") as Control
	if host == null:
		return
	if _preview_model != null and is_instance_valid(_preview_model):
		_preview_model.free()
	_preview_model = MODEL_SCRIPT.new()
	_preview_model.name = "SelectModel"
	_preview_model.position = Vector2(150, 240)
	host.add_child(_preview_model)
	_preview_fighter_id = ""



func _emit_preview_visibility_telemetry() -> void:
	var telem = get_node_or_null("/root/Wave018VisibilityTelemetry")
	if telem == null or not telem.has_method("emit_select_row"):
		return
	var snap: Dictionary = {}
	if telem.has_method("snapshot_model"):
		snap = telem.snapshot_model(_preview_model)
	var expected: bool = visible and is_inside_tree() and _roster.size() > 0
	var inv: Dictionary = assert_preview_visibility_invariant()
	var rid: String = str(telem.emit_select_row({
		"selected_fighter_id": _preview_fighter_id,
		"preview_generation": _preview_generation,
		"preview_expected_visible": expected,
		"preview_root_valid": bool(snap.get("model_root_valid", _preview_model != null and is_instance_valid(_preview_model))),
		"preview_visible_in_tree": bool(snap.get("model_visible_in_tree", false)),
		"renderable_mesh_count": int(snap.get("renderable_mesh_count", 0)),
		"visible_renderable_mesh_count": int(snap.get("visible_renderable_mesh_count", 0)),
		"skeleton_valid": bool(snap.get("skeleton_valid", false)),
		"controller_valid": bool(snap.get("controller_valid", false)),
		"fallback_active": bool(snap.get("fallback_active", false)),
		"visibility_invariant_pass": bool(inv.get("PASS", false)),
	}))
	# Stash last record id for screenshot binding.
	set_meta("wave018_last_telemetry_record_id", rid)


func assert_preview_visibility_invariant() -> Dictionary:
	var expected := visible and is_inside_tree() and _roster.size() > 0
	var body_ok: bool = false
	if _preview_model != null and is_instance_valid(_preview_model) and _preview_model.has_method("is_visible_renderable_body"):
		body_ok = bool(_preview_model.is_visible_renderable_body())
	var bodies := 0
	if _preview_model != null and _preview_model.has_method("count_visible_bodies"):
		bodies = int(_preview_model.count_visible_bodies())
	var ghost: bool = expected and not body_ok
	var dup: bool = bodies > 1
	return {
		"FIGHTER_SHOULD_BE_PRESENT": expected,
		"VISIBLE_RENDERABLE_BODY": body_ok,
		"VISIBLE_BODY_COUNT": bodies,
		"GHOST": ghost,
		"DUPLICATE_BODY": dup,
		"PASS": (not expected) or (body_ok and not dup),
		"preview_fighter_id": _preview_fighter_id,
		"preview_failures": _preview_failures,
	}


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
		_teardown_preview()
		SceneRouter.go("stage_select")


func on_back() -> void:
	if _selecting_p2:
		_selecting_p2 = false
		_refresh()
	else:
		_teardown_preview()
		SceneRouter.go("ruleset")
