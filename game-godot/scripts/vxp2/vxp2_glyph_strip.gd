extends RefCounted
class_name Vxp2GlyphStrip

## Touch / controller glyph foundation for player chrome footers.

static func attach(parent: Control, actions: Array = ["confirm", "back"]) -> HBoxContainer:
	if parent == null:
		return null
	var existing := parent.get_node_or_null("Vxp2GlyphStrip") as HBoxContainer
	if existing != null:
		return existing
	var row := HBoxContainer.new()
	row.name = "Vxp2GlyphStrip"
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	row.position = Vector2(24, -72)
	row.offset_top = -72
	row.offset_bottom = -24
	row.offset_left = 24
	for action in actions:
		var tex: Texture2D = Vxp2Brand.glyph_texture(str(action))
		if tex == null:
			continue
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color(1, 1, 1, 0.95)
		# Non-color cue: also show text label for high-contrast / colorblind.
		var wrap := HBoxContainer.new()
		wrap.add_theme_constant_override("separation", 6)
		wrap.add_child(icon)
		var lbl := Label.new()
		lbl.text = str(action).capitalize()
		lbl.add_theme_font_size_override("font_size", Vxp2Brand.TYPE_META)
		lbl.add_theme_color_override("font_color", Vxp2Brand.COLOR_HC_FG if Vxp2Brand.high_contrast_active() else Vxp2Brand.COLOR_MUTED)
		wrap.add_child(lbl)
		row.add_child(wrap)
	parent.add_child(row)
	return row
