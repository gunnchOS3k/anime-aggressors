extends "res://scripts/ui/console_menu_base.gd"

## Dev-only Launch Feedback lab. Predictor text is debug-only.

const _Predictor = preload("res://scripts/combat/critical_launch_predictor.gd")
const _Cue = preload("res://scripts/visual/critical_launch_cue.gd")
const _Trail = preload("res://scripts/visual/launch_trail_system.gd")
const _Identity = preload("res://scripts/visual/elemental_material_contract.gd")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const POSITIONS := ["center", "ledge", "offstage"]
const HITS := ["light", "heavy", "special_a", "special_b", "super"]
const RECOVERY := ["full", "reduced", "none"]
const SPEEDS := [1.0, 0.5, 0.25]

var _atk := 0
var _def := 1
var _pct := 80
var _pos := 0
var _hit := 1
var _rec := 0
var _vfx := true
var _speed := 0
var _freeze_contact := false
var _freeze_critical := false
var _debug: Label
var _preview: Node2D


func _ready() -> void:
	super._ready()
	if title_label:
		title_label.text = "Launch Feedback Review"
	_debug = Label.new()
	_debug.name = "PredictorDebug"
	_debug.position = Vector2(48, 88)
	_debug.add_theme_font_size_override("font_size", 16)
	add_child(_debug)
	_preview = MODEL_SCRIPT.new()
	_preview.name = "LaunchPreview"
	_preview.position = Vector2(640, 360)
	add_child(_preview)
	_refresh()


func footer_hint() -> String:
	return "Debug predictor only. [A] fire  [LB/RB] attacker  [X] defender  [Y] hit  [Select] position"


func on_back() -> void:
	Engine.time_scale = 1.0
	SceneRouter.go("labs")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_fire()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right"):
		_atk = (_atk + 1) % FIGHTERS.size()
		_refresh()
		return
	if event.is_action_pressed("ui_left"):
		_def = (_def + 1) % FIGHTERS.size()
		_refresh()
		return
	super._unhandled_input(event)


func _fire() -> void:
	var pred := simulate_current()
	if _debug:
		_debug.text = _format(pred)
	if not _vfx:
		return
	var trail := _preview.get_node_or_null("LaunchTrail")
	if trail == null:
		trail = _Trail.new()
		trail.name = "LaunchTrail"
		_preview.add_child(trail)
	if trail.has_method("begin"):
		trail.begin(_preview, FIGHTERS[_atk], str(pred.get("trail_tier", "HIGH")))
	if str(pred.get("tier")) in ["CRITICAL_RECOVERABLE", "NEAR_CERTAIN_KO"]:
		var cue := _Cue.new()
		add_child(cue)
		cue.play(FIGHTERS[_atk], _preview.global_position, Vector2(18, -16), str(pred.get("tier")))


func simulate_current() -> Dictionary:
	var pos := Vector2(0, 200)
	match POSITIONS[_pos]:
		"ledge":
			pos = Vector2(500, 260)
		"offstage":
			pos = Vector2(560, 240)
	var kb := Vector2(6, -4)
	match HITS[_hit]:
		"heavy":
			kb = Vector2(16, -14)
		"special_a":
			kb = Vector2(18, -12)
		"special_b":
			kb = Vector2(14, -18)
		"super":
			kb = Vector2(24, -20)
	if _pct >= 120:
		kb *= 1.35
	var jumps := 1
	match RECOVERY[_rec]:
		"reduced":
			jumps = 0
		"none":
			jumps = 0
	var pred := _Predictor.evaluate({
		"position": pos,
		"launch_velocity": kb,
		"remaining_jumps": jumps,
		"recovery_ready": RECOVERY[_rec] != "none",
		"hitstun_sec": 0.22,
	})
	pred["trail_tier"] = _Predictor.trail_tier(pred, kb.length())
	pred["attacker"] = FIGHTERS[_atk]
	pred["defender"] = FIGHTERS[_def]
	pred["cue"] = _Cue.family_for(FIGHTERS[_atk])
	pred["gameplay_exposed"] = false
	return pred


func _format(pred: Dictionary) -> String:
	return "ATK %s  DEF %s  pct %d  pos %s  hit %s  rec %s\nDEBUG %s  trail %s  cue %s\nVFX %s  speed %.2f  freeze_c %s  freeze_crit %s" % [
		FIGHTERS[_atk], FIGHTERS[_def], _pct, POSITIONS[_pos], HITS[_hit], RECOVERY[_rec],
		pred.get("tier"), pred.get("trail_tier"), pred.get("cue"),
		"ON" if _vfx else "OFF", SPEEDS[_speed], _freeze_contact, _freeze_critical,
	]


func _refresh() -> void:
	Engine.time_scale = 0.0 if (_freeze_contact or _freeze_critical) else float(SPEEDS[_speed])
	if _preview.has_method("set_presentation_context"):
		_preview.set_presentation_context("SELECT_PREVIEW")
	if _preview.has_method("configure"):
		_preview.configure({"id": FIGHTERS[_def]})
	if _debug:
		_debug.text = _format(simulate_current())
