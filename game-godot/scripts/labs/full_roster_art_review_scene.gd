extends "res://scripts/ui/console_menu_base.gd"

## Pixel / owner full-roster art review route. Dev-only when staging flags are on.
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _Resolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _Overlay := preload("res://scripts/visual/art_source_review_overlay.gd")

const FIGHTERS := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]
const ACTIONS := ["idle", "walk", "run", "charge", "heavy", "hurt", "super", "clash"]

var _index: int = 0
var _action_index: int = 0
var _preview: Node2D
var _name_label: Label
var _action_label: Label
var _overlay: CanvasLayer


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Full Roster Art Review"
	_overlay = _Overlay.new()
	_overlay.name = "ArtSourceReviewOverlay"
	add_child(_overlay)
	_ensure_preview()
	_refresh()


func footer_hint() -> String:
	return "[A] Next action   [LB/RB] Next fighter   [B] Back   Review only — not production"


func on_back() -> void:
	SceneRouter.go("fighter_select")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_action_index = (_action_index + 1) % ACTIONS.size()
		_refresh()
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
	super._unhandled_input(event)


func _next_fighter() -> void:
	_index = (_index + 1) % FIGHTERS.size()
	_action_index = 0
	_refresh()


func _ensure_preview() -> void:
	_name_label = Label.new()
	_name_label.name = "FighterName"
	_name_label.add_theme_font_size_override("font_size", 28)
	add_child(_name_label)
	_name_label.position = Vector2(48, 96)
	_action_label = Label.new()
	_action_label.name = "ActionName"
	_action_label.add_theme_font_size_override("font_size", 22)
	add_child(_action_label)
	_action_label.position = Vector2(48, 140)
	var next_btn := Button.new()
	next_btn.name = "NextFighter"
	next_btn.text = "Next Fighter"
	next_btn.position = Vector2(48, 620)
	next_btn.pressed.connect(_next_fighter)
	add_child(next_btn)
	var host := Control.new()
	host.name = "PreviewHost"
	host.position = Vector2(420, 80)
	host.custom_minimum_size = Vector2(360, 420)
	add_child(host)
	_preview = MODEL_SCRIPT.new()
	_preview.name = "ReviewPreview"
	host.add_child(_preview)


func _refresh() -> void:
	var fighter_id: String = FIGHTERS[_index]
	var action: String = ACTIONS[_action_index]
	if _name_label:
		_name_label.text = "%d / 7  %s" % [_index + 1, fighter_id]
	if _action_label:
		_action_label.text = "Action: %s" % action
	if _overlay and _overlay.has_method("set_fighter"):
		_overlay.set_fighter(fighter_id)
	var data := {"id": fighter_id}
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null and gs.has_method("load_fighter"):
			data = gs.load_fighter(fighter_id)
	if _preview and _preview.has_method("configure"):
		_preview.configure(data)
	if _preview and _preview.has_method("play_clip"):
		_preview.play_clip(action)
