extends Control
## Vector stylized silhouette for select tiles / HUD — readable at phone scale.
## Distinct shapes per fighter (not one body recolored).

@export var fighter_id: String = "ember-vale"
@export var primary: Color = Color(1, 0.4, 0.2)
@export var accent: Color = Color(1, 0.85, 0.3)
@export var focused: bool = false

var _pulse: float = 0.0


func configure(id: String, primary_color: Color, accent_color: Color) -> void:
	fighter_id = id
	primary = primary_color
	accent = accent_color
	queue_redraw()


func set_focused(value: bool) -> void:
	focused = value
	queue_redraw()


func _process(delta: float) -> void:
	if focused:
		_pulse += delta * 4.0
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var ground := h * 0.92
	var lift := 4.0 + (sin(_pulse) * 3.0 if focused else 0.0)
	# Ground plate
	draw_rect(Rect2(8, ground - 4, w - 16, 6), Color(0, 0, 0, 0.35))
	match fighter_id:
		"ember-vale":
			_draw_ember(cx, ground - lift)
		"rook-ironside":
			_draw_rook(cx, ground - lift)
		"juno-spark":
			_draw_juno(cx, ground - lift)
		"kaia-windrow":
			_draw_kaia(cx, ground - lift)
		"nix-calder":
			_draw_nix(cx, ground - lift)
		"orion-vell":
			_draw_orion(cx, ground - lift)
		"vesper-nyx":
			_draw_vesper(cx, ground - lift)
		_:
			_draw_athlete(cx, ground - lift)
	if focused:
		draw_arc(Vector2(cx, h * 0.45), minf(w, h) * 0.38, 0.0, TAU, 32, accent, 2.0)


func _draw_athlete(cx: float, g: float) -> void:
	draw_circle(Vector2(cx, g - 112), 14, primary)
	draw_rect(Rect2(cx - 16, g - 98, 32, 48), primary)
	draw_rect(Rect2(cx - 22, g - 50, 12, 50), primary)
	draw_rect(Rect2(cx + 10, g - 50, 12, 50), primary)


func _draw_ember(cx: float, g: float) -> void:
	# Forward lean + oversized gauntlets
	draw_circle(Vector2(cx + 6, g - 118), 15, primary)
	draw_colored_polygon(
		PackedVector2Array([Vector2(cx - 8, g - 100), Vector2(cx + 28, g - 92), Vector2(cx + 18, g - 48), Vector2(cx - 18, g - 52)]),
		primary
	)
	draw_rect(Rect2(cx - 34, g - 88, 22, 28), accent) # left gauntlet
	draw_rect(Rect2(cx + 20, g - 86, 24, 30), accent) # right gauntlet
	draw_rect(Rect2(cx - 10, g - 48, 10, 48), primary)
	draw_rect(Rect2(cx + 14, g - 46, 10, 46), primary)
	# Flame crest
	draw_colored_polygon(
		PackedVector2Array([Vector2(cx + 6, g - 148), Vector2(cx + 18, g - 122), Vector2(cx - 4, g - 122)]),
		accent
	)


func _draw_rook(cx: float, g: float) -> void:
	draw_rect(Rect2(cx - 18, g - 122, 36, 20), primary) # helm brow
	draw_circle(Vector2(cx, g - 108), 14, primary)
	draw_rect(Rect2(cx - 28, g - 92, 56, 52), primary) # wide torso
	draw_rect(Rect2(cx - 40, g - 90, 18, 28), accent) # pauldron L
	draw_rect(Rect2(cx + 22, g - 90, 18, 28), accent)
	draw_rect(Rect2(cx - 22, g - 42, 16, 42), primary)
	draw_rect(Rect2(cx + 6, g - 42, 16, 42), primary)


func _draw_juno(cx: float, g: float) -> void:
	draw_circle(Vector2(cx - 4, g - 118), 12, primary)
	draw_rect(Rect2(cx - 14, g - 104, 24, 42), primary)
	# Asymmetric stance
	draw_rect(Rect2(cx - 24, g - 58, 10, 58), primary)
	draw_rect(Rect2(cx + 6, g - 50, 10, 50), primary)
	# Scarf bolt
	draw_colored_polygon(
		PackedVector2Array([Vector2(cx + 10, g - 100), Vector2(cx + 48, g - 88), Vector2(cx + 38, g - 70), Vector2(cx + 8, g - 78)]),
		accent
	)
	draw_circle(Vector2(cx + 46, g - 86), 5, accent)


func _draw_kaia(cx: float, g: float) -> void:
	draw_circle(Vector2(cx, g - 126), 13, primary)
	draw_rect(Rect2(cx - 12, g - 110, 24, 50), primary)
	draw_rect(Rect2(cx - 16, g - 58, 9, 58), primary)
	draw_rect(Rect2(cx + 8, g - 58, 9, 58), primary)
	# Flowing ribbon
	draw_polyline(
		PackedVector2Array([Vector2(cx - 14, g - 96), Vector2(cx - 40, g - 80), Vector2(cx - 28, g - 50), Vector2(cx - 46, g - 30)]),
		accent,
		5.0
	)


func _draw_nix(cx: float, g: float) -> void:
	# Crystal crest + upright
	draw_colored_polygon(
		PackedVector2Array([Vector2(cx, g - 140), Vector2(cx + 10, g - 118), Vector2(cx - 10, g - 118)]),
		accent
	)
	draw_circle(Vector2(cx, g - 112), 12, primary)
	draw_rect(Rect2(cx - 12, g - 98, 24, 48), primary)
	draw_rect(Rect2(cx - 14, g - 50, 10, 50), primary)
	draw_rect(Rect2(cx + 4, g - 50, 10, 50), primary)
	draw_rect(Rect2(cx - 8, g - 86, 6, 18), accent)


func _draw_orion(cx: float, g: float) -> void:
	draw_circle(Vector2(cx, g - 124), 13, primary)
	draw_rect(Rect2(cx - 11, g - 108, 22, 52), primary)
	draw_rect(Rect2(cx - 15, g - 54, 10, 54), primary)
	draw_rect(Rect2(cx + 5, g - 54, 10, 54), primary)
	draw_arc(Vector2(cx, g - 86), 34, 0.2, TAU - 0.2, 28, accent, 2.5)
	draw_circle(Vector2(cx + 30, g - 86), 4, accent)


func _draw_vesper(cx: float, g: float) -> void:
	draw_circle(Vector2(cx + 4, g - 116), 12, primary)
	draw_rect(Rect2(cx - 10, g - 102, 24, 46), primary)
	# Cloak flare asymmetric
	draw_colored_polygon(
		PackedVector2Array([Vector2(cx - 8, g - 100), Vector2(cx - 44, g - 40), Vector2(cx - 8, g - 50)]),
		accent.darkened(0.25)
	)
	draw_rect(Rect2(cx - 18, g - 54, 10, 54), primary)
	draw_rect(Rect2(cx + 10, g - 48, 10, 48), primary)
