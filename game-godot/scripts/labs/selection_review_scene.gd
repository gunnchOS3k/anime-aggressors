extends "res://scripts/ui/console_menu_base.gd"

## Selection review: tile / large preview / lock-in / showcase / match-start.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _Announcer = preload("res://scripts/audio/fighter_announcer.gd")
const _Callout = preload("res://scripts/ui/lockin_name_callout.gd")
const _Identity = preload("res://scripts/visual/elemental_material_contract.gd")
const _Fit = preload("res://scripts/visual/geometry_auto_fit.gd")

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const MODES := ["tile", "preview", "lockin", "showcase", "match_start"]

var _index := 0
var _mode := 1
var _preview: Node2D
var _info: Label
var _callout: CanvasLayer


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Selection Review"
	_info = Label.new()
	_info.position = Vector2(48, 80)
	_info.add_theme_font_size_override("font_size", 16)
	add_child(_info)
	_preview = MODEL_SCRIPT.new()
	_preview.position = Vector2(640, 360)
	add_child(_preview)
	_callout = _Callout.new()
	add_child(_callout)
	_refresh()


func footer_hint() -> String:
	return "Tile / preview / lock-in / showcase / match-start. [A] announce  [LB/RB] fighter  [X] mode"


func on_back() -> void:
	SceneRouter.go("labs")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_Announcer.announce_lock(1, FIGHTERS[_index], self, false)
		if _callout.has_method("play"):
			_callout.play(FIGHTERS[_index])
		return
	if event.is_action_pressed("ui_right"):
		_index = (_index + 1) % FIGHTERS.size()
		_refresh()
		return
	if event.is_action_pressed("ui_left"):
		_mode = (_mode + 1) % MODES.size()
		_refresh()
		return
	super._unhandled_input(event)


func _refresh() -> void:
	var fid: String = FIGHTERS[_index]
	var ctx := "SELECT_CARD"
	match MODES[_mode]:
		"preview", "lockin":
			ctx = "SELECT_PREVIEW"
		"showcase":
			ctx = "SHOWCASE"
		"match_start":
			ctx = "MATCH_START"
	if _preview.has_method("set_presentation_context"):
		_preview.set_presentation_context(ctx)
	if _preview.has_method("configure"):
		_preview.configure({"id": fid})
	var colors := _Identity.identity_colors(fid)
	var report := {}
	if _preview.has_method("get_select_framing_report"):
		report = _preview.get_select_framing_report()
	_info.text = "%s  mode=%s  family=%s  hue=%.0f  alpha_floor=%.2f  clip=%s" % [
		fid, MODES[_mode], colors.get("roygbiv_family"), colors.get("family_hue_deg"),
		_Identity.BODY_ALPHA_MIN, not bool(report.get("no_clip", true)),
	]
