extends "res://scripts/ui/console_menu_base.gd"

const Vxp2BrandScript = preload("res://scripts/vxp2/vxp2_brand.gd")
const Vxp2A11yScript = preload("res://scripts/vxp2/vxp2_accessibility_chrome.gd")
const Vxp2GlyphScript = preload("res://scripts/vxp2/vxp2_glyph_strip.gd")

func _ready() -> void:
	super._ready()
	Vxp2BrandScript.apply_surface_chrome(self)
	if title_label:
		title_label.text = "Choose Mode"
	_emphasize_primary_modes()
	Vxp2GlyphScript.attach(self, ["confirm", "back"])
	Vxp2A11yScript.apply(self)

func _emphasize_primary_modes() -> void:
	var versus := find_child("Versus", true, false) as Button
	if versus:
		versus.text = "Versus"
		versus.custom_minimum_size = Vector2(320, 72)
		versus.add_theme_font_size_override("font_size", 24)
		versus.grab_focus()
	for name in ["OnlineHub", "Tournament"]:
		var b := find_child(name, true, false) as Button
		if b:
			b.modulate = Color(0.78, 0.8, 0.86, 0.9)
			b.add_theme_font_size_override("font_size", 16)

func _on_versus_pressed() -> void:
	GameState.mode = "versus"
	GameState.arcade_active = false
	GameState.team_mode = false
	SceneRouter.go("ruleset")

func _on_training_pressed() -> void:
	GameState.mode = "training"
	GameState.arcade_active = false
	GameState.team_mode = false
	SceneRouter.go_training()

func _on_arcade_pressed() -> void:
	GameState.mode = "arcade"
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.team_mode = false
	SceneRouter.go("arcade")

func _on_tutorial_pressed() -> void:
	GameState.mode = "tutorial"
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.team_mode = false
	SceneRouter.go_tutorial()

func _on_hazards_pressed() -> void:
	GameState.mode = "hazards"
	GameState.team_mode = false
	SceneRouter.go_hazards()

func _on_team_pressed() -> void:
	GameState.mode = "team"
	SceneRouter.go("team")

func _on_challenges_pressed() -> void:
	GameState.mode = "challenges"
	SceneRouter.go("challenges")

func _on_online_pressed() -> void:
	GameState.mode = "online_private"
	SceneRouter.go("online_hub")

func _on_tournament_pressed() -> void:
	GameState.mode = "tournament"
	SceneRouter.go("tournament")

func footer_hint() -> String:
	return "Versus first · Confirm · Back"

func on_back() -> void:
	SceneRouter.go("main_menu")
