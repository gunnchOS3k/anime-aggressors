extends RefCounted
class_name Vxp2AccessibilityChrome

## Applies designed high-contrast + reduce-motion presentation without inventing human validation.

static func apply(root: Control) -> void:
	if root == null:
		return
	var hc := Vxp2Brand.high_contrast_active()
	var rm := Vxp2Brand.reduce_motion_active()
	if hc:
		_walk_hc(root)
	if rm:
		_kill_ambient_tweens(root)
	root.set_meta("vxp2_a11y_applied", true)
	root.set_meta("vxp2_high_contrast", hc)
	root.set_meta("vxp2_reduce_motion", rm)


static func _walk_hc(node: Node) -> void:
	if node is Label:
		var l := node as Label
		l.add_theme_color_override("font_color", Vxp2Brand.COLOR_HC_FG)
		# Non-color cue: underline titles via border meta marker.
		if l.name == "Title" or l.name.begins_with("P1") or l.name.begins_with("P2"):
			l.add_theme_color_override("font_outline_color", Vxp2Brand.COLOR_HC_ACCENT)
			l.add_theme_constant_override("outline_size", 2)
	elif node is Button:
		var b := node as Button
		b.add_theme_color_override("font_color", Vxp2Brand.COLOR_HC_FG)
		b.add_theme_color_override("font_hover_color", Vxp2Brand.COLOR_HC_ACCENT)
		b.add_theme_color_override("font_focus_color", Vxp2Brand.COLOR_HC_ACCENT)
		# Shape cue: thicker border via flat style clone when possible.
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(0.08, 0.08, 0.08, 1)
		focus.border_color = Vxp2Brand.COLOR_HC_ACCENT
		focus.set_border_width_all(4)
		focus.set_corner_radius_all(4)
		focus.content_margin_left = 16
		focus.content_margin_right = 16
		focus.content_margin_top = 10
		focus.content_margin_bottom = 10
		b.add_theme_stylebox_override("focus", focus)
		b.add_theme_stylebox_override("hover", focus)
	elif node is ColorRect and node.name == "Background":
		(node as ColorRect).color = Vxp2Brand.COLOR_HC_BG
	for c in node.get_children():
		_walk_hc(c)


static func _kill_ambient_tweens(node: Node) -> void:
	# Stop looping decorative modulate pulses; keep functional transitions short.
	if node.has_meta("vxp2_ambient_tween"):
		var tw = node.get_meta("vxp2_ambient_tween")
		if tw is Tween and (tw as Tween).is_valid():
			(tw as Tween).kill()
	for c in node.get_children():
		_kill_ambient_tweens(c)
