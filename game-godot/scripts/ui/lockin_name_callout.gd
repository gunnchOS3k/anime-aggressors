extends CanvasLayer
class_name LockinNameCallout

## Brief original lock-in name treatment. Not Smash typography or layout.

const _Announcer = preload("res://scripts/audio/fighter_announcer.gd")
const _Brand = preload("res://scripts/vxp2/vxp2_brand.gd")

var _label: Label
var _streak: ColorRect
var _edge: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 48
	_edge = ColorRect.new()
	_edge.name = "HudEdge"
	_edge.color = Color(1, 1, 1, 0)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_edge)
	_streak = ColorRect.new()
	_streak.name = "ElementalStreak"
	_streak.size = Vector2(420, 8)
	_streak.position = Vector2(430, 118)
	_streak.color = Color(1, 1, 1, 0)
	_streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_streak)
	_label = Label.new()
	_label.name = "LockinName"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(80, 64)
	_label.size = Vector2(1120, 72)
	_label.add_theme_font_size_override("font_size", 42)
	_label.modulate.a = 0.0
	add_child(_label)


func play(fighter_id: String) -> Dictionary:
	var reduce := _Brand.reduce_motion_active()
	var accent := _Announcer.identity_color(fighter_id)
	if _Brand.high_contrast_active():
		accent = Color(1.0, 1.0, 1.0, 1.0)
	_label.text = _Announcer.shout_label(fighter_id)
	_label.add_theme_color_override("font_color", accent)
	_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.07, 1.0))
	_label.add_theme_constant_override("outline_size", 8)
	_streak.color = Color(accent.r, accent.g, accent.b, 0.0)
	_edge.color = Color(accent.r, accent.g, accent.b, 0.0)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var dur := 0.42 if reduce else 0.62
	_label.modulate.a = 0.0
	if reduce:
		_tween.tween_property(_label, "modulate:a", 1.0, 0.12)
		_tween.tween_interval(dur)
		_tween.tween_property(_label, "modulate:a", 0.0, 0.16)
	else:
		_label.position.y = 78
		_tween.set_parallel(true)
		_tween.tween_property(_label, "modulate:a", 1.0, 0.12)
		_tween.tween_property(_label, "position:y", 64.0, 0.18)
		_tween.tween_property(_streak, "color:a", 0.85, 0.14)
		_tween.tween_property(_edge, "color:a", 0.18, 0.1)
		_tween.chain().tween_interval(dur)
		_tween.chain().set_parallel(true)
		_tween.tween_property(_label, "modulate:a", 0.0, 0.18)
		_tween.tween_property(_streak, "color:a", 0.0, 0.18)
		_tween.tween_property(_edge, "color:a", 0.0, 0.18)
	return {
		"fighter_id": fighter_id,
		"text": _label.text,
		"reduce_motion": reduce,
		"duration_ms": int(dur * 1000.0),
	}
