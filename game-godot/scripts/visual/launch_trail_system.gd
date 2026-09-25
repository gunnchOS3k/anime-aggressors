extends Node2D
class_name LaunchTrailSystem

## Defender-origin launch trails. Hierarchy: none / brief streak / smoke / critical elemental.

const _Identity = preload("res://scripts/visual/elemental_material_contract.gd")
const _Brand = preload("res://scripts/vxp2/vxp2_brand.gd")

var _points: PackedVector2Array = PackedVector2Array()
var _life: float = 0.0
var _tier: String = "LOW"
var _tint: Color = Color(0.92, 0.94, 0.96, 0.28)
var _active: bool = false
var _reduce: bool = false


func _ready() -> void:
	z_index = 6
	_reduce = _Brand.reduce_motion_active()


func begin(defender: Node2D, attacker_id: String, tier: String) -> void:
	if tier == "LOW":
		clear()
		return
	if tier not in ["MEDIUM", "HIGH", "CRITICAL"]:
		tier = "HIGH"
	_tier = tier
	_active = true
	_points = PackedVector2Array()
	_life = 0.22 if tier == "MEDIUM" else (0.42 if tier == "HIGH" else 0.62)
	if _reduce:
		_life *= 0.55
	var colors := _Identity.identity_colors(attacker_id)
	var accent: Color = colors.get("accent", Color(0.9, 0.9, 0.95))
	if _Brand.high_contrast_active():
		_tint = Color(1, 1, 1, 0.55)
	elif tier == "HIGH":
		_tint = Color(0.92, 0.94, 0.96, 0.28).lerp(Color(accent.r, accent.g, accent.b, 0.32), 0.35)
	else:
		_tint = Color(accent.r, accent.g, accent.b, 0.48)
	if defender != null:
		_points.append(defender.global_position)
	queue_redraw()


func follow(defender: Node2D, velocity: Vector2) -> void:
	if not _active or defender == null:
		return
	if velocity.length() < 6.0:
		end()
		return
	_points.append(defender.global_position)
	if _points.size() > 18:
		_points.remove_at(0)
	queue_redraw()


func end() -> void:
	_active = false
	_life = 0.12
	queue_redraw()


func clear() -> void:
	_active = false
	_life = 0.0
	_points = PackedVector2Array()
	queue_redraw()


func _process(delta: float) -> void:
	if _life <= 0.0:
		if _points.size() > 0:
			_points = PackedVector2Array()
			queue_redraw()
		return
	_life -= delta
	if _life <= 0.0:
		clear()


func _draw() -> void:
	if _points.size() < 2 or _life <= 0.0:
		return
	var width := 4.0 if _tier == "MEDIUM" else (7.0 if _tier == "HIGH" else 10.0)
	if _reduce:
		width *= 0.6
	for i in range(1, _points.size()):
		var a := to_local(_points[i - 1])
		var b := to_local(_points[i])
		var fade := float(i) / float(_points.size())
		var col := Color(_tint.r, _tint.g, _tint.b, _tint.a * fade * clampf(_life * 2.0, 0.0, 1.0))
		draw_line(a, b, col, width, true)
