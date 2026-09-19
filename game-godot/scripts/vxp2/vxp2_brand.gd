extends RefCounted
class_name Vxp2Brand

## VXP-2 AURA FORGE design tokens. Design label only — product name is Anime Aggressors.

const THEME_PATH := "res://assets/ui/themes/aa_vxp2_theme.tres"
const LEGACY_THEME_PATH := "res://assets/placeholder/aa_theme.tres"
const SEAL_PATH := "res://assets/branding/vxp2/aa_seal.png"
const WORDMARK_PATH := "res://assets/branding/vxp2/aa_wordmark.png"
const HERO_PATH := "res://assets/branding/vxp2/aa_hero_backdrop.png"
const GLYPH_DIR := "res://assets/branding/vxp2/glyphs/"

const COLOR_NAVY_DEEP := Color(0.039, 0.071, 0.125, 1.0)
const COLOR_NAVY_MID := Color(0.075, 0.11, 0.18, 1.0)
const COLOR_GOLD := Color(0.91, 0.72, 0.29, 1.0)
const COLOR_GOLD_BRIGHT := Color(0.96, 0.82, 0.42, 1.0)
const COLOR_EMBER := Color(0.91, 0.35, 0.16, 1.0)
const COLOR_INK := Color(0.95, 0.94, 0.91, 1.0)
const COLOR_MUTED := Color(0.56, 0.64, 0.77, 1.0)
const COLOR_HC_BG := Color(0.0, 0.0, 0.0, 1.0)
const COLOR_HC_FG := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HC_ACCENT := Color(1.0, 0.92, 0.2, 1.0)

## Type scale (px). Custom face deferred; hierarchy is the contract.
const TYPE_DISPLAY := 48
const TYPE_HERO := 36
const TYPE_TITLE := 28
const TYPE_SUBTITLE := 20
const TYPE_BODY := 18
const TYPE_META := 14
const TYPE_HUD := 16
const TYPE_HUD_PCT := 28

const TOUCH_MIN := 48.0


static func theme() -> Theme:
	if ResourceLoader.exists(THEME_PATH):
		return load(THEME_PATH) as Theme
	if ResourceLoader.exists(LEGACY_THEME_PATH):
		return load(LEGACY_THEME_PATH) as Theme
	return null


static func reduce_motion_active() -> bool:
	var role = Engine.get_main_loop().root.get_node_or_null("/root/DeviceRoleRuntime") if Engine.get_main_loop() else null
	if role != null:
		return bool(role.reduce_motion)
	return bool(ProjectSettings.get_setting("rendering/accessibility/reduce_motion", false))


static func high_contrast_active() -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState") if Engine.get_main_loop() else null
	if gs != null:
		return bool(gs.high_contrast)
	return false


static func apply_surface_chrome(root: Control, opts: Dictionary = {}) -> void:
	if root == null:
		return
	var t := theme()
	if t != null:
		root.theme = t
	var bg := root.get_node_or_null("Background") as ColorRect
	if bg != null:
		if high_contrast_active():
			bg.color = COLOR_HC_BG
		else:
			bg.color = COLOR_NAVY_DEEP
	var title := root.get_node_or_null("%Title") as Label
	if title == null:
		title = root.find_child("Title", true, false) as Label
	if title != null:
		title.add_theme_font_size_override("font_size", int(opts.get("title_size", TYPE_TITLE)))
		title.add_theme_color_override("font_color", COLOR_HC_FG if high_contrast_active() else COLOR_GOLD_BRIGHT)
	_ensure_min_touch_targets(root)


static func _ensure_min_touch_targets(node: Node) -> void:
	if node is Button:
		var b := node as Button
		var min_sz := b.custom_minimum_size
		b.custom_minimum_size = Vector2(maxf(min_sz.x, 160.0), maxf(min_sz.y, TOUCH_MIN))
	for c in node.get_children():
		_ensure_min_touch_targets(c)


static func glyph_texture(name: String) -> Texture2D:
	var path := GLYPH_DIR + "glyph_%s.png" % name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func player_destination_copy(stage_data: Dictionary) -> String:
	## Never surface PROCEDURAL_FINAL / engineer artStatus in player UI.
	var name := str(stage_data.get("displayName", stage_data.get("id", "Stage")))
	var layout := str(stage_data.get("layoutType", "")).strip_edges()
	if layout.is_empty():
		return name
	return "%s\n%s" % [name, layout]


static func strip_engineer_status(text: String) -> String:
	var out := text
	for token in ["PROCEDURAL_FINAL", "PROCEDURAL_PRODUCTION_PROXY", "REQUIRES_ART_PRODUCTION", "LEGACY_PROCEDURAL_FINAL"]:
		out = out.replace(token, "")
	return out.strip_edges()
