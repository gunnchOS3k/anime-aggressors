extends RefCounted
class_name StageArtFactory

static func build_skyline_layers(parent: Node2D) -> void:
	var skyline := Node2D.new()
	skyline.name = "SkylineLayers"
	parent.add_child(skyline)

	for i in range(4):
		var layer := ColorRect.new()
		layer.color = Color(0.05 + i * 0.03, 0.08 + i * 0.02, 0.18 + i * 0.04, 1.0)
		layer.position = Vector2(-920, -520 + i * 40)
		layer.size = Vector2(1840, 120)
		skyline.add_child(layer)

	var neon := Node2D.new()
	neon.name = "NeonDepth"
	skyline.add_child(neon)
	for x in [-600, -200, 200, 600]:
		var stripe := ColorRect.new()
		stripe.color = Color(0.2, 0.5, 0.95, 0.35)
		stripe.position = Vector2(x, -180)
		stripe.size = Vector2(8, 260)
		neon.add_child(stripe)

	var railing := Polygon2D.new()
	railing.name = "ForegroundRailing"
	railing.color = Color(0.12, 0.14, 0.22, 0.85)
	railing.polygon = PackedVector2Array([
		Vector2(-900, 200), Vector2(900, 200), Vector2(900, 220), Vector2(-900, 220)
	])
	parent.add_child(railing)

static func thicken_platform(platform: StaticBody2D, thickness: float = 28.0) -> void:
	var visual := platform.get_node_or_null("FloorVisual") as Polygon2D
	if visual == null:
		visual = platform.get_node_or_null("Visual") as Polygon2D
	if visual == null:
		return
	var half_h := thickness * 0.5
	var half_w := 800.0
	if platform.name != "MainPlatform":
		half_w = 110.0
	visual.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h)
	])
