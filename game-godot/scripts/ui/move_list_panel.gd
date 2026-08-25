extends Control
## Player-facing Move List / Command Guide / Move Preview (Wave019 20A).
## process_mode ALWAYS so it works under battle pause.

const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
const Glyphs = preload("res://scripts/ui/input_glyph_presenter.gd")
const MODEL_SCRIPT = preload("res://scripts/fighters/fighter_model_3d.gd")

signal closed
signal pin_requested(move_entry: Dictionary)

var fighter_id: String = ""
var _catalog: Dictionary = {}
var _device: String = ""
var _advanced: bool = false
var _show_lab: bool = false
var _selected_index: int = 0
var _flat_playable: Array = []
var _preview_model: Node2D
var _preview_playing: bool = true
var _preview_slow: bool = false
var _preview_t: float = 0.0
var _pinned_move_id: String = ""

var _root_panel: PanelContainer
var _title: Label
var _summary: Label
var _list: ItemList
var _detail: RichTextLabel
var _glyph_label: Label
var _core_label: Label
var _preview_host: Control
var _btn_simple: Button
var _btn_advanced: Button
var _btn_replay: Button
var _btn_pause: Button
var _btn_slow: Button
var _btn_pin: Button
var _btn_close: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


func open_for_fighter(p_fighter_id: String, pinned_move_id: String = "") -> void:
	fighter_id = p_fighter_id
	_pinned_move_id = pinned_move_id
	_device = Glyphs.detect_device()
	_catalog = Catalog.build_fighter_catalog(fighter_id)
	_rebuild_flat()
	_refresh_header()
	_populate_list()
	_ensure_preview()
	visible = true
	if _list.item_count > 0:
		for i in _list.item_count:
			if not _list.is_item_disabled(i):
				_list.select(i)
				_on_item_selected(i)
				break


func close_panel() -> void:
	visible = false
	_preview_playing = false
	closed.emit()


func get_pinned_reminder() -> Dictionary:
	if _pinned_move_id.is_empty():
		return {}
	for e in _flat_playable:
		if str(e.get("move_id", "")) == _pinned_move_id:
			return Glyphs.enrich_entry(e, _device)
	return {}


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_root_panel = PanelContainer.new()
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_root_panel.custom_minimum_size = Vector2(980, 560)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.14, 0.97)
	style.border_color = Color(0.95, 0.72, 0.28, 1.0)
	style.set_border_width_all(3)
	style.set_content_margin_all(14)
	_root_panel.add_theme_stylebox_override("panel", style)
	add_child(_root_panel)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	_root_panel.add_child(outer)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 8)
	outer.add_child(left)

	_title = Label.new()
	_title.text = "MOVE LIST / COMMAND GUIDE"
	_title.add_theme_font_size_override("font_size", 22)
	left.add_child(_title)

	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.add_theme_font_size_override("font_size", 13)
	left.add_child(_summary)

	_core_label = Label.new()
	_core_label.add_theme_font_size_override("font_size", 12)
	_core_label.modulate = Color(1.0, 0.85, 0.45)
	left.add_child(_core_label)

	var view_row := HBoxContainer.new()
	_btn_simple = Button.new()
	_btn_simple.text = "SIMPLE"
	_btn_simple.pressed.connect(func(): _advanced = false; _refresh_detail())
	_btn_advanced = Button.new()
	_btn_advanced.text = "ADVANCED"
	_btn_advanced.pressed.connect(func(): _advanced = true; _refresh_detail())
	var lab_btn := Button.new()
	lab_btn.text = "LAB REF"
	lab_btn.pressed.connect(func(): _show_lab = not _show_lab; _rebuild_flat(); _populate_list())
	view_row.add_child(_btn_simple)
	view_row.add_child(_btn_advanced)
	view_row.add_child(lab_btn)
	left.add_child(view_row)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0, 280)
	_list.item_selected.connect(_on_item_selected)
	left.add_child(_list)

	_glyph_label = Label.new()
	_glyph_label.add_theme_font_size_override("font_size", 18)
	left.add_child(_glyph_label)

	_detail = RichTextLabel.new()
	_detail.fit_content = true
	_detail.scroll_active = true
	_detail.bbcode_enabled = true
	_detail.custom_minimum_size = Vector2(0, 120)
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_detail)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.add_theme_constant_override("separation", 8)
	outer.add_child(right)

	var prev_title := Label.new()
	prev_title.text = "MOVE PREVIEW"
	prev_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(prev_title)

	_preview_host = Control.new()
	_preview_host.custom_minimum_size = Vector2(300, 340)
	_preview_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_preview_host)

	var controls := HBoxContainer.new()
	_btn_pause = Button.new()
	_btn_pause.text = "PAUSE"
	_btn_pause.pressed.connect(_toggle_preview_pause)
	_btn_replay = Button.new()
	_btn_replay.text = "REPLAY"
	_btn_replay.pressed.connect(_replay_preview)
	_btn_slow = Button.new()
	_btn_slow.text = "SLOW"
	_btn_slow.pressed.connect(_toggle_slow)
	_btn_pin = Button.new()
	_btn_pin.text = "TRY THIS"
	_btn_pin.pressed.connect(_pin_current)
	controls.add_child(_btn_pause)
	controls.add_child(_btn_replay)
	controls.add_child(_btn_slow)
	controls.add_child(_btn_pin)
	right.add_child(controls)

	_btn_close = Button.new()
	_btn_close.text = "Close Move List"
	_btn_close.pressed.connect(close_panel)
	right.add_child(_btn_close)


func _rebuild_flat() -> void:
	_flat_playable.clear()
	var order: Array = Catalog.CATEGORY_ORDER
	var by_cat: Dictionary = {}
	for e in _catalog.get("entries", []):
		var playable := bool(e.get("playable", false))
		var lab := str(e.get("reachability", "")) == "LAB_ONLY"
		if playable or (_show_lab and lab):
			var cat := str(e.get("category", "SPECIALS"))
			if not by_cat.has(cat):
				by_cat[cat] = []
			(by_cat[cat] as Array).append(Glyphs.enrich_entry(e, _device))
	for cat in order:
		if not by_cat.has(cat):
			continue
		for e in by_cat[cat]:
			_flat_playable.append(e)
	for cat in by_cat.keys():
		if cat in order:
			continue
		for e in by_cat[cat]:
			_flat_playable.append(e)


func _populate_list() -> void:
	_list.clear()
	var last_cat := ""
	for e in _flat_playable:
		var cat := str(e.get("category", ""))
		if cat != last_cat:
			_list.add_item("— %s —" % cat)
			_list.set_item_disabled(_list.item_count - 1, true)
			last_cat = cat
		var mark := "★ " if bool(e.get("is_core", false)) else ""
		var lab := " [LAB]" if str(e.get("reachability", "")) == "LAB_ONLY" else ""
		var glyphs: Dictionary = e.get("input_glyphs", {})
		var line := "%s%s%s   %s" % [mark, str(e.get("display_name", "")), lab, str(glyphs.get("compact", ""))]
		_list.add_item(line)


func _refresh_header() -> void:
	var beginner: Dictionary = _catalog.get("beginner", {})
	_title.text = "MOVE LIST — %s" % fighter_id.replace("-", " ").capitalize()
	_summary.text = "PLAYSTYLE: %s\nDIFFICULTY: %s\nBEST AT: %s\nWATCH OUT FOR: %s\nCORE GAME PLAN: %s" % [
		str(beginner.get("playstyle", "")),
		str(beginner.get("difficulty", "")),
		str(beginner.get("best_at", "")),
		str(beginner.get("watch_out_for", "")),
		str(beginner.get("core_game_plan", "")),
	]
	var cores: Array = _catalog.get("core_move_ids", [])
	_core_label.text = "CORE MOVES: " + ", ".join(PackedStringArray(cores))


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _list.item_count:
		return
	if _list.is_item_disabled(index):
		return
	var entry_i := -1
	for i in _list.item_count:
		if _list.is_item_disabled(i):
			continue
		entry_i += 1
		if i == index:
			_selected_index = entry_i
			break
	_refresh_detail()
	_replay_preview()


func _current_entry() -> Dictionary:
	if _selected_index < 0 or _selected_index >= _flat_playable.size():
		return {}
	return _flat_playable[_selected_index]


func _refresh_detail() -> void:
	var e := _current_entry()
	if e.is_empty():
		_detail.text = ""
		_glyph_label.text = ""
		return
	var glyphs: Dictionary = e.get("input_glyphs", {})
	_glyph_label.text = "INPUT: %s" % str(glyphs.get("advanced" if _advanced else "compact", ""))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]%s[/b]" % str(e.get("display_name", "")))
	lines.append(str(e.get("short_description", "")))
	lines.append("Type: %s · State: %s · Aura: %s · Role: %s" % [
		str(e.get("move_type", "")),
		str(e.get("grounded_air", "")),
		str(e.get("aura_requirement", "")),
		str(e.get("damage_role", "")),
	])
	lines.append("Tactical: %s" % str(e.get("tactical_purpose", "")))
	if _advanced:
		lines.append("Frames — startup %s / active %s / recovery %s" % [
			str(e.get("startup_frames", "—")),
			str(e.get("active_frames", "—")),
			str(e.get("recovery_frames", "—")),
		])
		lines.append("Clip: %s · move_id: %s" % [str(e.get("animation_clip", "")), str(e.get("move_id", ""))])
		if str(e.get("reachability", "")) == "LAB_ONLY":
			lines.append("[i]CONCEPT / LAB TECHNIQUE — NOT CURRENTLY BOUND TO NORMAL MATCH INPUT[/i]")
	_detail.text = "\n".join(lines)


func _ensure_preview() -> void:
	if _preview_model != null and is_instance_valid(_preview_model):
		return
	_preview_model = MODEL_SCRIPT.new()
	_preview_model.name = "MovePreviewModel"
	_preview_model.position = Vector2(150, 260)
	_preview_host.add_child(_preview_model)
	var data: Dictionary = {"id": fighter_id, "displayName": fighter_id}
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("load_fighter"):
		data = gs.load_fighter(fighter_id)
	if _preview_model.has_method("configure"):
		_preview_model.configure(data)
	if _preview_model.has_method("set_select_mode"):
		_preview_model.set_select_mode(true)


func _replay_preview() -> void:
	_preview_t = 0.0
	_preview_playing = true
	_btn_pause.text = "PAUSE"
	_ensure_preview()
	var e := _current_entry()
	if e.is_empty() or _preview_model == null:
		return
	var clip := str(e.get("animation_clip", "idle"))
	if _preview_model.has_method("play_clip"):
		_preview_model.play_clip(clip)
	elif _preview_model.has_method("play_state"):
		_preview_model.play_state(clip)


func _toggle_preview_pause() -> void:
	_preview_playing = not _preview_playing
	_btn_pause.text = "PLAY" if not _preview_playing else "PAUSE"


func _toggle_slow() -> void:
	_preview_slow = not _preview_slow
	_btn_slow.text = "SLOW ✓" if _preview_slow else "SLOW"


func _pin_current() -> void:
	var e := _current_entry()
	if e.is_empty() or not bool(e.get("playable", false)):
		return
	_pinned_move_id = str(e.get("move_id", ""))
	pin_requested.emit(e)


func _process(delta: float) -> void:
	if not visible or not _preview_playing:
		return
	var speed := 0.35 if _preview_slow else 1.0
	_preview_t += delta * speed
	var e := _current_entry()
	if e.is_empty() or _preview_model == null:
		return
	var clip := str(e.get("animation_clip", "idle"))
	if _preview_model.has_method("animate_preview"):
		_preview_model.animate_preview(clip, _preview_t)
	elif _preview_model.has_method("play_clip") and fmod(_preview_t, 1.2) < delta * speed:
		_preview_model.play_clip(clip)
