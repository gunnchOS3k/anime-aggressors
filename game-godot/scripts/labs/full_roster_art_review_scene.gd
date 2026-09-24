extends "res://scripts/ui/console_menu_base.gd"

## Owner elemental-specials review route. Dev-only labels. No filesystem paths.
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _Resolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _Overlay := preload("res://scripts/visual/art_source_review_overlay.gd")
const _Signature = preload("res://scripts/visual/signature_move_presentation.gd")
const _Facing = preload("res://scripts/combat/fighter_facing_contract.gd")
const _HitReaction = preload("res://scripts/combat/directional_hit_reaction.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]
const ACTIONS := ["heavy", "special_a", "special_b", "super", "clash", "charged_idle", "hurt_heavy", "launch"]
const SPEEDS := [1.0, 0.5, 0.25]
const FREEZE := ["live", "anticipation", "contact", "hurt", "follow-through"]
const FACINGS := ["LEFT", "RIGHT"]

var _index: int = 0
var _opp_index: int = 1
var _action_index: int = 0
var _speed_index: int = 0
var _facing_index: int = 1
var _freeze_index: int = 0
var _vfx_on: bool = true
var _preview: Node2D
var _opp_preview: Node2D
var _name_label: Label
var _action_label: Label
var _speed_label: Label
var _mode_label: Label
var _status_label: Label
var _overlay: CanvasLayer


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Elemental Specials Review"
	_overlay = _Overlay.new()
	_overlay.name = "ArtSourceReviewOverlay"
	add_child(_overlay)
	_ensure_preview()
	_apply_review_speed()
	_refresh()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func footer_hint() -> String:
	return "Review — not owner-approved. [A] action  [LB/RB] fighter  [X] facing  [Y] speed  [L] VFX  [R] freeze  [Select] opponent"


func on_back() -> void:
	Engine.time_scale = 1.0
	SceneRouter.go("fighter_select")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_cycle_action(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_page_down"):
		_next_fighter()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_page_up"):
		_index = (_index - 1 + FIGHTERS.size()) % FIGHTERS.size()
		_action_index = 0
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_text_completion_replace") or event.is_action_pressed("p1_special"):
		_cycle_speed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("p1_attack") or (event is InputEventKey and event.pressed and event.keycode == KEY_X):
		_cycle_facing()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		_vfx_on = not _vfx_on
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_freeze_index = (_freeze_index + 1) % FREEZE.size()
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		_opp_index = (_opp_index + 1) % FIGHTERS.size()
		_refresh()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func _next_fighter() -> void:
	_index = (_index + 1) % FIGHTERS.size()
	_action_index = 0
	_refresh()


func _cycle_action(delta: int) -> void:
	_action_index = (_action_index + delta + ACTIONS.size()) % ACTIONS.size()
	_refresh()


func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_apply_review_speed()
	_refresh()


func _cycle_facing() -> void:
	_facing_index = (_facing_index + 1) % FACINGS.size()
	_refresh()


func _apply_review_speed() -> void:
	if FREEZE[_freeze_index] != "live":
		Engine.time_scale = 0.0
		return
	Engine.time_scale = float(SPEEDS[_speed_index])


func _ensure_preview() -> void:
	_mode_label = Label.new()
	_mode_label.name = "ModeBanner"
	_mode_label.add_theme_font_size_override("font_size", 16)
	_mode_label.position = Vector2(48, 56)
	add_child(_mode_label)
	_name_label = Label.new()
	_name_label.name = "FighterName"
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.position = Vector2(48, 88)
	add_child(_name_label)
	_action_label = Label.new()
	_action_label.name = "ActionName"
	_action_label.add_theme_font_size_override("font_size", 20)
	_action_label.position = Vector2(48, 124)
	add_child(_action_label)
	_speed_label = Label.new()
	_speed_label.name = "ReviewSpeed"
	_speed_label.add_theme_font_size_override("font_size", 16)
	_speed_label.position = Vector2(48, 156)
	add_child(_speed_label)
	_status_label = Label.new()
	_status_label.name = "ReviewStatus"
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.position = Vector2(48, 184)
	add_child(_status_label)
	_add_button("FacingToggle", "Facing LEFT / RIGHT", Vector2(48, 520), _cycle_facing)
	_add_button("VfxToggle", "VFX ON / OFF", Vector2(280, 520), func() -> void:
		_vfx_on = not _vfx_on
		_refresh()
	)
	_add_button("SpeedToggle", "Speed 1.0 / 0.5 / 0.25", Vector2(512, 520), _cycle_speed)
	_add_button("FreezeToggle", "Freeze phase", Vector2(48, 572), func() -> void:
		_freeze_index = (_freeze_index + 1) % FREEZE.size()
		_refresh()
	)
	_add_button("OppToggle", "Opponent", Vector2(280, 572), func() -> void:
		_opp_index = (_opp_index + 1) % FIGHTERS.size()
		_refresh()
	)
	_add_button("NextFighter", "Next Fighter", Vector2(512, 572), _next_fighter)
	var action_row := HBoxContainer.new()
	action_row.name = "ActionButtons"
	action_row.position = Vector2(48, 220)
	action_row.add_theme_constant_override("separation", 8)
	add_child(action_row)
	for i in ACTIONS.size():
		var action_name: String = ACTIONS[i]
		var btn := Button.new()
		btn.name = "Action_%s" % action_name
		btn.text = action_name
		btn.custom_minimum_size = Vector2(96, 40)
		var captured := i
		btn.pressed.connect(func() -> void:
			_action_index = captured
			_refresh()
		)
		action_row.add_child(btn)
	var host := Control.new()
	host.name = "PreviewHost"
	host.position = Vector2(360, 80)
	host.custom_minimum_size = Vector2(360, 420)
	add_child(host)
	_preview = MODEL_SCRIPT.new()
	_preview.name = "ReviewPreview"
	host.add_child(_preview)
	var opp_host := Control.new()
	opp_host.name = "OpponentHost"
	opp_host.position = Vector2(720, 80)
	opp_host.custom_minimum_size = Vector2(360, 420)
	add_child(opp_host)
	_opp_preview = MODEL_SCRIPT.new()
	_opp_preview.name = "OpponentPreview"
	opp_host.add_child(_opp_preview)


func _add_button(node_name: String, text: String, pos: Vector2, cb: Callable) -> void:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.position = pos
	btn.custom_minimum_size = Vector2(220, 44)
	btn.pressed.connect(cb)
	add_child(btn)


func _refresh() -> void:
	var fighter_id: String = FIGHTERS[_index]
	var opp_id: String = FIGHTERS[_opp_index]
	var action: String = ACTIONS[_action_index]
	var facing: String = str(FACINGS[_facing_index])
	var freeze: String = str(FREEZE[_freeze_index])
	if _mode_label:
		var counts: Dictionary = _Resolver.roster_review_counts()
		_mode_label.text = "ELEMENTAL SPECIALS REVIEW — %s" % str(counts.get("label", "Candidate review")).replace("\n", "  ")
	if _name_label:
		_name_label.text = "%d / 7  %s" % [_index + 1, fighter_id]
	if _action_label:
		var label := _Signature.label_for_lane(fighter_id, action)
		_action_label.text = "Action: %s  (%s)" % [action, label]
	if _speed_label:
		_speed_label.text = "Speed: %.2fx   Freeze: %s" % [SPEEDS[_speed_index], freeze]
	if _status_label:
		_status_label.text = "Facing: %s   VFX: %s   Opponent: %s" % [facing, "ON" if _vfx_on else "OFF", opp_id]
	if _overlay and _overlay.has_method("set_fighter"):
		_overlay.set_fighter(fighter_id)
	_apply_review_speed()
	_apply_preview(_preview, fighter_id, action, facing, false)
	var opp_facing := "LEFT" if facing == "RIGHT" else "RIGHT"
	var opp_action := "hurt_heavy" if action in ["heavy", "special_a", "special_b", "super"] else "charged_idle"
	_apply_preview(_opp_preview, opp_id, opp_action, opp_facing, true)


func _apply_preview(preview: Node2D, fighter_id: String, action: String, facing: String, is_hurt: bool) -> void:
	if preview == null:
		return
	var data := {"id": fighter_id}
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and gs.has_method("load_fighter"):
			data = gs.load_fighter(fighter_id)
	if preview.has_method("set_presentation_context"):
		preview.set_presentation_context("SELECT_PREVIEW")
	if preview.has_method("configure"):
		preview.configure(data)
	if preview.has_method("set_facing"):
		preview.set_facing(_Facing.facing_int(facing))
	if preview.has_method("set_vfx_enabled"):
		preview.set_vfx_enabled(_vfx_on)
	if preview.has_method("set_review_freeze_phase"):
		preview.set_review_freeze_phase(FREEZE[_freeze_index])
	if preview.has_method("set_aura_level") and action == "charged_idle":
		preview.set_aura_level(3)
	if is_hurt and preview.has_method("apply_hurt_reaction"):
		var incoming := Vector2(1.0, -0.2) if FACINGS[_facing_index] == "RIGHT" else Vector2(-1.0, -0.2)
		var info := {
			"move_id": _Signature.move_id_for_lane(FIGHTERS[_index], ACTIONS[_action_index]),
			"damage": 10.0,
			"launch": incoming * 16.0,
		}
		preview.apply_hurt_reaction(_HitReaction.resolve(fighter_id, incoming, info))
	if preview.has_method("play_clip"):
		preview.play_clip(action)


func review_route_contract() -> Dictionary:
	return {
		"facing": FACINGS.duplicate(),
		"vfx": ["ON", "OFF"],
		"speed": SPEEDS.duplicate(),
		"freeze": FREEZE.duplicate(),
		"action": ACTIONS.duplicate(),
		"selectable_opponent": true,
		"exposes_filesystem_paths": false,
	}
