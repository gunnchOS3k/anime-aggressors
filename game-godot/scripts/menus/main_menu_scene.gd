extends "res://scripts/ui/console_menu_base.gd"

const Vxp2BrandScript = preload("res://scripts/vxp2/vxp2_brand.gd")
const Vxp2A11yScript = preload("res://scripts/vxp2/vxp2_accessibility_chrome.gd")
const Vxp2GlyphScript = preload("res://scripts/vxp2/vxp2_glyph_strip.gd")

var _ambient_tween: Tween

func _ready() -> void:
	super._ready()
	Vxp2BrandScript.apply_surface_chrome(self, {"title_size": Vxp2BrandScript.TYPE_DISPLAY})
	_apply_brand_art()
	if title_label:
		title_label.text = "Anime Aggressors"
	var tag := get_node_or_null("%Tagline") as Label
	if tag:
		tag.add_theme_color_override("font_color", Vxp2BrandScript.COLOR_MUTED)
	var fight := get_node_or_null("%Fight") as Button
	if fight:
		fight.grab_focus()
	Vxp2GlyphScript.attach(self, ["confirm", "back", "fight"])
	Vxp2A11yScript.apply(self)
	_start_menu_ambient()
	_layout_for_viewport()
	get_viewport().size_changed.connect(_layout_for_viewport)


func _apply_brand_art() -> void:
	var seal := get_node_or_null("%Seal") as TextureRect
	if seal and ResourceLoader.exists(Vxp2BrandScript.SEAL_PATH):
		seal.texture = load(Vxp2BrandScript.SEAL_PATH) as Texture2D


func _layout_for_viewport() -> void:
	## Desktop + handheld landscape: tighten secondary column on narrow widths.
	var layout := get_node_or_null("Layout") as HBoxContainer
	var hero := get_node_or_null("Layout/HeroColumn") as Control
	var secondary := get_node_or_null("Layout/SecondaryColumn") as Control
	if layout == null or hero == null or secondary == null:
		return
	var w := get_viewport_rect().size.x
	if w < 960.0:
		layout.add_theme_constant_override("separation", 18)
		hero.size_flags_stretch_ratio = 1.1
		secondary.size_flags_stretch_ratio = 0.9
		layout.offset_left = 24.0
		layout.offset_right = -24.0
	else:
		layout.add_theme_constant_override("separation", 40)
		hero.size_flags_stretch_ratio = 1.35
		secondary.size_flags_stretch_ratio = 1.0
		layout.offset_left = 48.0
		layout.offset_right = -48.0


func _start_menu_ambient() -> void:
	if Vxp2BrandScript.reduce_motion_active():
		return
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = create_tween().set_loops()
	set_meta("vxp2_ambient_tween", _ambient_tween)
	_ambient_tween.tween_property(self, "modulate", Color(1.02, 1.02, 1.04, 1.0), 1.8)
	_ambient_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.8)
	if title_label:
		var title_pulse := create_tween().set_loops()
		title_pulse.tween_property(title_label, "modulate:a", 0.9, 1.4)
		title_pulse.tween_property(title_label, "modulate:a", 1.0, 1.4)


func _on_start_battle_pressed() -> void:
	_press_feedback()
	SceneRouter.go("mode_select")

func _on_training_pressed() -> void:
	_press_feedback()
	SceneRouter.go_training()

func _on_rulesets_pressed() -> void:
	_press_feedback()
	SceneRouter.go("ruleset")

func _on_fighter_vault_pressed() -> void:
	_press_feedback()
	SceneRouter.go("fighter_select")

func _on_stage_vault_pressed() -> void:
	_press_feedback()
	SceneRouter.go("stage_select")

func _on_controls_pressed() -> void:
	_press_feedback()
	SceneRouter.go("controls")

func _on_settings_pressed() -> void:
	_press_feedback()
	SceneRouter.go("settings")

func _on_labs_pressed() -> void:
	_press_feedback()
	SceneRouter.go("labs")

func _on_mobile_playtest_pressed() -> void:
	_press_feedback()
	SceneRouter.go_mobile_playtest()

func _on_credits_pressed() -> void:
	_press_feedback()
	SceneRouter.go("credits")

func _on_achievements_pressed() -> void:
	_press_feedback()
	SceneRouter.go("achievements")

func _press_feedback() -> void:
	if not Vxp2BrandScript.reduce_motion_active():
		var tap := create_tween()
		tap.tween_property(self, "scale", Vector2(0.995, 0.995), 0.05)
		tap.tween_property(self, "scale", Vector2.ONE, 0.08)
	var director = get_node_or_null("/root/AudioDirector")
	if director and director.has_method("play_ui"):
		director.play_ui("ui_confirm")
	else:
		var audio = load("res://scripts/audio/procedural_audio_bank.gd")
		if audio:
			audio.play_shared("ui_confirm", self)
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(18)

func footer_hint() -> String:
	return "Confirm · Back · FIGHT is the primary path"


func on_back() -> void:
	var router := get_node_or_null("/root/SceneRouter")
	if router:
		router.skip_boot_title = false
	SceneRouter.go("boot")


func focus_default() -> void:
	var fight := get_node_or_null("%Fight") as Control
	if fight and fight.visible:
		fight.grab_focus()
		return
	super.focus_default()
