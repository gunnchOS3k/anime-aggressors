extends Node
## Wave017: dynamic battle framing — zoom by separation, bounded stage, smooth lerp.

var _camera: Camera2D
var _profile: Dictionary = {}
var _fighters: Array = []
var _blast: Dictionary = {}
var _base_zoom: float = 1.2
var _impact_zoom_boost: float = 0.0
var _recovery_bias: Vector2 = Vector2.ZERO
var _enabled: bool = true


func configure(camera: Camera2D, profile: Dictionary, fighters: Array, blast: Dictionary) -> void:
	_camera = camera
	_profile = profile.duplicate(true) if not profile.is_empty() else {
		"minZoom": 0.82,
		"maxZoom": 1.35,
		"lerp": 0.12,
		"deadzone": {"x": 90, "y": 60},
	}
	_fighters = fighters
	_blast = blast
	if _camera:
		_base_zoom = _camera.zoom.x if _camera.zoom.x > 0.01 else 1.2
	set_process(true)


func trigger_impact_zoom(amount: float = 0.08, duration: float = 0.12) -> void:
	_impact_zoom_boost = maxf(_impact_zoom_boost, amount)
	var tw := create_tween()
	tw.tween_property(self, "_impact_zoom_boost", 0.0, duration).set_ease(Tween.EASE_OUT)


func bias_recovery(offset: Vector2, duration: float = 0.35) -> void:
	_recovery_bias = offset
	var tw := create_tween()
	tw.tween_property(self, "_recovery_bias", Vector2.ZERO, duration).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	if not _enabled or _camera == null or not is_instance_valid(_camera):
		return
	var alive: Array = []
	for f in _fighters:
		if f != null and is_instance_valid(f) and ("stocks" not in f or int(f.stocks) > 0):
			alive.append(f)
	if alive.is_empty():
		return
	var mid := Vector2.ZERO
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for f in alive:
		var p: Vector2 = f.global_position
		mid += p
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	mid /= float(alive.size())
	mid += _recovery_bias

	var sep_x := maxf(120.0, max_x - min_x)
	var sep_y := maxf(80.0, max_y - min_y)
	var min_z: float = float(_profile.get("minZoom", 0.82))
	var max_z: float = float(_profile.get("maxZoom", 1.35))
	# Wider separation → zoom out (lower zoom value in Godot Camera2D means more zoomed out when using size? Camera2D.zoom: larger = more zoomed in)
	var t := clampf((sep_x - 180.0) / 520.0, 0.0, 1.0)
	var target_zoom := lerpf(max_z, min_z, t)
	# Prefer slightly lower empty sky: bias mid downward toward platforms.
	mid.y = lerpf(mid.y, mid.y + 28.0, 0.35)
	target_zoom = clampf(target_zoom + _impact_zoom_boost, min_z * 0.92, max_z + 0.08)

	var left := float(_blast.get("left", -580))
	var right := float(_blast.get("right", 580))
	var top := float(_blast.get("top", -370))
	var bottom := float(_blast.get("bottom", 450))
	var margin := 80.0
	mid.x = clampf(mid.x, left + margin, right - margin)
	mid.y = clampf(mid.y, top + margin, bottom - margin)

	var lerp_k: float = float(_profile.get("lerp", 0.12))
	var dead: Dictionary = _profile.get("deadzone", {})
	var dz_x: float = float(dead.get("x", 90))
	var dz_y: float = float(dead.get("y", 60))
	var cur := _camera.global_position
	var dx := mid.x - cur.x
	var dy := mid.y - cur.y
	if absf(dx) < dz_x * 0.35:
		dx *= 0.35
	if absf(dy) < dz_y * 0.35:
		dy *= 0.35
	_camera.global_position = cur.lerp(cur + Vector2(dx, dy), lerp_k)
	var z := _camera.zoom.x
	var nz := lerpf(z, target_zoom, lerp_k)
	_camera.zoom = Vector2(nz, nz)
