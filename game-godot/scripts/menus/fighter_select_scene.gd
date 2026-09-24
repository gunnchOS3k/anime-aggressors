extends "res://scripts/ui/console_menu_base.gd"

const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")
const _Presentation = preload("res://scripts/fighters/fighter_presentation_profile.gd")
const FIGHTER_BUTTON_SCENE := preload("res://scenes/ui/FighterTile.tscn")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const MOVE_LIST_PANEL := preload("res://scripts/ui/move_list_panel.gd")
const SHOWCASE_FLOURISH := preload("res://scripts/menus/character_select_showcase_flourish.gd")
const _PresentationGates = preload("res://scripts/menus/wave020_presentation_gates.gd")
const Vxp2BrandScript = preload("res://scripts/vxp2/vxp2_brand.gd")
const Vxp2A11yScript = preload("res://scripts/vxp2/vxp2_accessibility_chrome.gd")
const Vxp2GlyphScript = preload("res://scripts/vxp2/vxp2_glyph_strip.gd")
const _ArtOverlay := preload("res://scripts/visual/art_source_review_overlay.gd")
const _AssetResolver := preload("res://scripts/visual/fighter_asset_resolver.gd")
const _Announcer := preload("res://scripts/audio/fighter_announcer.gd")
const _Callout := preload("res://scripts/ui/lockin_name_callout.gd")

var _roster: Array = []
var _cursor: int = 0
var _p1_pick: int = 0
var _p2_pick: int = 1
var _selecting_p2: bool = false
var _locked_p1: bool = false
var _locked_p2: bool = false
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
## Typed via preload (SHOWCASE_FLOURISH) so clean-room parse does not depend on
## global_script_class_cache being warm before --import completes.
var _flourish: Node
var _flourish_btn: Button
var _motion_label: Label
var _last_accel: Vector3 = Vector3.ZERO
var _shake_cooldown_ms: int = 0
var _art_overlay: CanvasLayer
var _lockin_callout: CanvasLayer
const SHAKE_THRESHOLD := 2.35

@onready var grid: GridContainer = %FighterGrid
@onready var p1_name: Label = %P1Name
@onready var p2_name: Label = %P2Name
@onready var detail: Label = %Detail
@onready var ready_label: Label = %ReadyLabel
@onready var lock_in_btn: Button = %LockIn
@onready var start_match_btn: Button = %StartMatch
@onready var action_bar: HBoxContainer = %ActionBar
@onready var toggle_cpu_btn: Button = %ToggleCpu


func _ready() -> void:
	_roster = GameState.roster_ids()
	super._ready()
	Vxp2BrandScript.apply_surface_chrome(self)
	if title_label:
		title_label.text = "Choose Your Fighter"
	_ensure_preview_host()
	_skin_preview_frame()
	_layout_action_bar_safe()
	if _PresentationGates.showcase_flourish_enabled:
		_ensure_showcase_flourish()
	_build_grid()
	_refresh()
	_update_preview(_cursor, false)
	if _PresentationGates.pause_movelist_enabled:
		_ensure_select_move_list_button()
	if _PresentationGates.showcase_flourish_enabled:
		_ensure_flourish_controls()
	Vxp2GlyphScript.attach(self, ["confirm", "back"])
	Vxp2A11yScript.apply(self)
	_update_start_match_cta()
	_ensure_art_review_overlay()
	_ensure_lockin_callout()


func _layout_action_bar_safe() -> void:
	## Keep Lock In / CONTINUE TO STAGE above system gesture / touch overlays on Pixel landscape.
	if action_bar == null:
		return
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport().get_visible_rect().size
	var bottom_inset := 24.0
	if safe.size.y > 0.0 and vp.y > 0.0:
		bottom_inset = maxf(24.0, vp.y - float(safe.position.y + safe.size.y) + 16.0)
	action_bar.offset_bottom = -bottom_inset
	action_bar.offset_top = -bottom_inset - 72.0
	if start_match_btn:
		start_match_btn.add_theme_font_size_override("font_size", 22)
	# Shrink preview on short landscape viewports so CTA never clips.
	var host := get_node_or_null("%PreviewHost") as Control
	if host and vp.y < 640.0:
		host.custom_minimum_size = Vector2(200, 220)
	elif host:
		host.custom_minimum_size = Vector2(240, 280)


func _skin_preview_frame() -> void:
	var frame := get_node_or_null("%PreviewHost/PreviewFrame") as ColorRect
	if frame == null:
		frame = find_child("PreviewFrame", true, false) as ColorRect
	if frame:
		frame.color = Color(0.05, 0.08, 0.14, 0.92) if not Vxp2BrandScript.high_contrast_active() else Color(0, 0, 0, 1)
	# Element non-color cue host: thin gold rule under player names.
	var panels := get_node_or_null("VBox/Panels") as Control
	if panels and panels.get_node_or_null("Vxp2NameRule") == null:
		var rule := ColorRect.new()
		rule.name = "Vxp2NameRule"
		rule.custom_minimum_size = Vector2(0, 3)
		rule.color = Vxp2BrandScript.COLOR_GOLD
		panels.add_sibling(rule)


func _ensure_showcase_flourish() -> void:
	if not _PresentationGates.showcase_flourish_enabled:
		return
	if _flourish != null:
		return
	_flourish = SHOWCASE_FLOURISH.new()
	_flourish.name = "ShowcaseFlourish"
	add_child(_flourish)
	if _preview_model != null:
		_flourish.bind_model(_preview_model)


func _ensure_flourish_controls() -> void:
	if not _PresentationGates.showcase_flourish_enabled:
		return
	if _flourish_btn != null:
		return
	_flourish_btn = Button.new()
	_flourish_btn.text = "Showcase"
	_flourish_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_flourish_btn.position = Vector2(-320, 480)
	_flourish_btn.pressed.connect(func(): _try_showcase_flourish("touch"))
	add_child(_flourish_btn)
	_motion_label = Label.new()
	_motion_label.text = "Motion: %s" % ("ON" if GameState.motion_gestures_enabled else "OFF")
	_motion_label.position = Vector2(-320, 520)
	add_child(_motion_label)


func _try_showcase_flourish(source: String) -> void:
	if not _PresentationGates.showcase_flourish_enabled:
		return
	if _flourish == null or _roster.is_empty():
		return
	var fid := str(_roster[_cursor])
	_flourish.bind_model(_preview_model)
	_flourish.set_fighter(fid)
	_flourish.trigger(source, fid)


func _process(_delta: float) -> void:
	# Godot 4 has no InputEventAccelerometer — poll Input.get_accelerometer() instead.
	if not _PresentationGates.showcase_flourish_enabled:
		return
	if not GameState.motion_gestures_enabled:
		return
	var acc := Input.get_accelerometer()
	if acc == Vector3.ZERO and _last_accel == Vector3.ZERO:
		return
	var delta_v := acc - _last_accel
	_last_accel = acc
	if Time.get_ticks_msec() < _shake_cooldown_ms:
		return
	if delta_v.length() >= SHAKE_THRESHOLD:
		_shake_cooldown_ms = Time.get_ticks_msec() + 1200
		_try_showcase_flourish("motion_shake")


func _unhandled_input(event: InputEvent) -> void:
	if not _PresentationGates.showcase_flourish_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_try_showcase_flourish("keyboard")
			get_viewport().set_input_as_handled()
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_STICK or event.button_index == JOY_BUTTON_Y:
			_try_showcase_flourish("controller")
			get_viewport().set_input_as_handled()


func _ensure_select_move_list_button() -> void:
	if _move_list_btn != null:
		return
	_move_list_btn = Button.new()
	_move_list_btn.text = "Command Guide"
	_move_list_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_move_list_btn.offset_left = 24.0
	_move_list_btn.offset_top = -160.0
	_move_list_btn.offset_right = 220.0
	_move_list_btn.offset_bottom = -112.0
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
		_apply_tile_identity_chrome(tile, id, profile)
		tile.pressed.connect(_on_tile_pressed.bind(i))
		tile.focus_entered.connect(_on_tile_focused.bind(i))
		tile.mouse_entered.connect(_on_tile_focused.bind(i))
		grid.add_child(tile)
		_tiles.append(tile)


func _apply_tile_identity_chrome(tile: Button, fighter_id: String, profile) -> void:
	var identity: Dictionary = {}
	var contract := load("res://scripts/visual/elemental_material_contract.gd")
	if contract != null and contract.has_method("identity_colors"):
		identity = contract.identity_colors(fighter_id)
	var primary: Color = identity.get("tile_primary", profile.primary_color)
	var accent: Color = identity.get("tile_accent", profile.accent_color)
	var plate := tile.get_node_or_null("IdentityPlate") as ColorRect
	if plate == null:
		plate = ColorRect.new()
		plate.name = "IdentityPlate"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.set_anchors_preset(Control.PRESET_FULL_RECT)
		tile.add_child(plate)
		tile.move_child(plate, 0)
	plate.color = Color(primary.r, primary.g, primary.b, 0.28)
	var rule := tile.get_node_or_null("IdentityAccent") as ColorRect
	if rule == null:
		rule = ColorRect.new()
		rule.name = "IdentityAccent"
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rule.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		rule.offset_top = -6.0
		tile.add_child(rule)
	rule.color = Color(accent.r, accent.g, accent.b, 0.92)
	tile.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.15))


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
	if _preview_model.has_method("set_presentation_context"):
		_preview_model.set_presentation_context("SELECT_PREVIEW")
	elif _preview_model.has_method("set_select_mode"):
		_preview_model.set_select_mode(true)
	if _preview_model.has_method("heal_visibility_if_needed"):
		_preview_model.heal_visibility_if_needed()
	if _preview_model.has_method("_enforce_exactly_one_visible_body"):
		_preview_model._enforce_exactly_one_visible_body()
	_emit_preview_visibility_telemetry()
	if lock_in and _preview_model.has_method("play_lock_in"):
		if _flourish != null and _flourish.is_active():
			_flourish.cancel_flourish()
		_preview_model.play_lock_in()
	elif _preview_model.has_method("play_selection_focus"):
		_preview_model.play_selection_focus()
	if _PresentationGates.showcase_flourish_enabled and _flourish != null:
		_flourish.bind_model(_preview_model)
		_flourish.set_fighter(id)
	if _motion_label != null:
		_motion_label.text = "Motion: %s" % ("ON" if GameState.motion_gestures_enabled else "OFF")


func _recreate_preview_model() -> void:
	var host := get_node_or_null("%PreviewHost") as Control
	if host == null:
		return
	if _preview_model != null and is_instance_valid(_preview_model):
		_preview_model.free()
	_preview_model = MODEL_SCRIPT.new()
	_preview_model.name = "SelectModel"
	_preview_model.position = Vector2(150, 240)
	if _preview_model.has_method("set_presentation_context"):
		_preview_model.set_presentation_context("SELECT_PREVIEW")
	host.add_child(_preview_model)
	_preview_fighter_id = ""
	if _flourish != null:
		_flourish.bind_model(_preview_model)



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
		var lock := " ✓" if _locked_p1 else ""
		p1_name.text = "P1: %s%s" % [p1.get("displayName", "?"), lock]
	if p2_name:
		var lock2 := " ✓" if _locked_p2 else ""
		p2_name.text = "P2: %s%s%s" % [
			p2.get("displayName", "?"),
			" (CPU)" if GameState.p2_is_cpu else "",
			lock2,
		]
	if detail:
		var traits: PackedStringArray = profile.personality_traits
		var element := str(focus.get("element", "")).capitalize()
		var element_mark := "◆"
		match element.to_lower():
			"fire", "ember":
				element_mark = "▲"
			"ice", "water":
				element_mark = "●"
			"wind", "air":
				element_mark = "◇"
			"void", "dark":
				element_mark = "■"
			"earth", "metal":
				element_mark = "■"
			"electric", "lightning":
				element_mark = "⚡"
			_:
				element_mark = "◆"
		detail.text = "%s  ·  %s\n%s\n\"%s\"\n%s %s | Wt %d · Run %d · Jump %d\nSig: %s" % [
			profile.power_identity,
			profile.select_archetype,
			" · ".join(traits),
			profile.selection_line,
			element_mark,
			element,
			int(focus.get("weight", 0)),
			int(focus.get("runSpeed", 0)),
			int(focus.get("jumpStrength", 0)),
			focus.get("signatureMove", ""),
		]
	if ready_label:
		ready_label.text = _readiness_message(p1, p2, profile)
	_update_start_match_cta()
	if _art_overlay and _art_overlay.has_method("set_fighter") and _roster.size() > _cursor:
		_art_overlay.set_fighter(_roster[_cursor], focus)


func _readiness_message(p1: Dictionary, p2: Dictionary, profile) -> String:
	var missing: PackedStringArray = PackedStringArray()
	if not _locked_p1:
		missing.append("Lock In P1")
	if not _locked_p2:
		if GameState.p2_is_cpu:
			missing.append("Lock In CPU opponent")
		else:
			missing.append("Lock In P2")
	if missing.is_empty():
		return "Ready — %s  vs  %s. Press CONTINUE TO STAGE." % [
			p1.get("displayName", "?"),
			p2.get("displayName", "?"),
		]
	if _selecting_p2:
		return "Selecting P2 — %s. Missing: %s" % [profile.display_name, ", ".join(missing)]
	return "%s — %s. Missing: %s" % [profile.display_name, profile.combat_fantasy, ", ".join(missing)]


func _update_start_match_cta() -> void:
	var ready := can_start_match()
	if start_match_btn:
		start_match_btn.disabled = not ready
		start_match_btn.visible = true
		start_match_btn.modulate = Color(1.15, 1.05, 0.75, 1.0) if ready else Color(0.7, 0.7, 0.75, 0.85)
		start_match_btn.text = "CONTINUE TO STAGE" if ready else "CONTINUE TO STAGE (incomplete)"
	if lock_in_btn:
		if not _locked_p1:
			lock_in_btn.text = "Lock In P1"
		elif not _locked_p2:
			lock_in_btn.text = "Lock In P2" if not GameState.p2_is_cpu else "Lock In CPU"
		else:
			lock_in_btn.text = "Re-lock"


func can_start_match() -> bool:
	return _locked_p1 and _locked_p2 and _roster.size() >= 2


func assert_start_match_cta() -> Dictionary:
	## Kept name for PR #102 harness compatibility; CTA is now CONTINUE TO STAGE.
	_layout_action_bar_safe()
	var btn := start_match_btn
	var bar := action_bar
	var vp := get_viewport().get_visible_rect()
	var btn_rect := Rect2()
	var bar_rect := Rect2()
	if btn:
		btn_rect = btn.get_global_rect()
	if bar:
		bar_rect = bar.get_global_rect()
	var in_safe := btn != null and btn.visible and btn_rect.position.y + btn_rect.size.y <= vp.size.y - 8.0
	var not_below := bar != null and bar_rect.position.y >= 0.0
	var text := str(btn.text) if btn else ""
	var truthful := text.contains("CONTINUE TO STAGE") or text.contains("CHOOSE STAGE")
	var no_false_start := not text.contains("START MATCH")
	return {
		"START_MATCH_VISIBLE": btn != null and btn.visible,
		"START_MATCH_IN_SAFE_AREA": in_safe and not_below,
		"FIGHTER_SELECT_CTA_TEXT": text,
		"FIGHTER_SELECT_CTA_TRUTHFUL": truthful and no_false_start,
		"FIGHTER_SELECT_CTA_ROUTES_TO_STAGE_SELECT": true,
		"CAN_START": can_start_match(),
		"LOCKED_P1": _locked_p1,
		"LOCKED_P2": _locked_p2,
		"PASS": btn != null and btn.visible and in_safe and truthful and no_false_start,
	}


func _on_toggle_cpu_pressed() -> void:
	GameState.p2_is_cpu = not GameState.p2_is_cpu
	if GameState.p2_is_cpu and _locked_p1 and not _locked_p2:
		# CPU opponent can be locked immediately after P1.
		pass
	_refresh()


func _on_lock_in_pressed() -> void:
	_on_next_player_pressed()


func _on_next_player_pressed() -> void:
	if not _locked_p1:
		_p1_pick = _cursor
		_locked_p1 = true
		_selecting_p2 = true
		if GameState.p2_is_cpu:
			# Auto-offer CPU lock on same confirm path clarity via label; still require Lock In CPU.
			pass
		_announce_lock(1, _roster[_p1_pick])
		_refresh()
		_update_preview(_cursor, true)
		return
	if not _locked_p2:
		_p2_pick = _cursor
		_locked_p2 = true
		_selecting_p2 = false
		_announce_lock(2, _roster[_p2_pick])
		_refresh()
		_update_preview(_cursor, true)
		if start_match_btn and can_start_match():
			start_match_btn.grab_focus()
		return
	# Already fully locked — Lock In re-opens P2 for change.
	_locked_p2 = false
	_selecting_p2 = true
	_refresh()


func _on_start_match_pressed() -> void:
	if not can_start_match():
		_refresh()
		return
	GameState.p1_fighter_id = _roster[_p1_pick]
	GameState.p2_fighter_id = _roster[_p2_pick]
	GameState.p1_ready = true
	GameState.p2_ready = true
	_teardown_preview()
	SceneRouter.go("stage_select")


func get_showcase_flourish_counters() -> Dictionary:
	if _flourish == null:
		return {}
	return _flourish.counters()


func _ensure_lockin_callout() -> void:
	if _lockin_callout != null:
		return
	_lockin_callout = _Callout.new()
	_lockin_callout.name = "LockinNameCallout"
	add_child(_lockin_callout)


func _announce_lock(slot: int, fighter_id: String) -> Dictionary:
	var announced := _Announcer.announce_lock(slot, fighter_id, self, false)
	if _lockin_callout != null and _lockin_callout.has_method("play") and bool(announced.get("announced", false)):
		_lockin_callout.play(fighter_id)
	return announced


func _ensure_art_review_overlay() -> void:
	if not _AssetResolver.staging_review_enabled():
		return
	if _art_overlay != null:
		return
	_art_overlay = _ArtOverlay.new()
	_art_overlay.name = "ArtSourceReviewOverlay"
	add_child(_art_overlay)
	var review_btn := Button.new()
	review_btn.name = "RosterArtReview"
	review_btn.text = "Roster Art Review"
	review_btn.pressed.connect(func() -> void: SceneRouter.go_roster_art_review())
	if action_bar:
		action_bar.add_child(review_btn)


func on_back() -> void:
	if _locked_p2:
		_locked_p2 = false
		_selecting_p2 = true
		_refresh()
	elif _selecting_p2 or _locked_p1:
		_selecting_p2 = false
		_locked_p1 = false
		_refresh()
	else:
		_teardown_preview()
		SceneRouter.go("ruleset")
