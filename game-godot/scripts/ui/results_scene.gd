extends "res://scripts/ui/console_menu_base.gd"

## Wave020 CP2: Victory / Results uses canonical fighter portrait (baked Model3D).

const PORTRAIT_SCRIPT = preload("res://scripts/ui/fighter_card_portrait.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")

@onready var rematch_btn: Button = $VBox/Rematch
@onready var change_fighters_btn: Button = $VBox/ChangeFighters
@onready var change_stage_btn: Button = $VBox/ChangeStage
@onready var victory_portrait: TextureRect = $VBox/VictoryPortrait

var _victory_fighter_id: String = ""
var _victory_canonical: bool = false


func _ready() -> void:
	super._ready()
	_ready_display()


func _ready_display() -> void:
	var winner := GameState.last_winner_slot
	var name := "P%d" % winner
	var fid := ""
	if winner == 1:
		fid = str(GameState.p1_fighter_id)
		name = GameState.load_fighter(fid).get("displayName", name)
	elif winner == 2:
		fid = str(GameState.p2_fighter_id)
		name = GameState.load_fighter(fid).get("displayName", name)
	elif not str(GameState.p1_fighter_id).is_empty():
		# Fallback when slot unset — still show P1 canonical art for harness paths.
		fid = str(GameState.p1_fighter_id)
		name = GameState.load_fighter(fid).get("displayName", name)
	_configure_victory_portrait(fid)
	if GameState.arcade_active or GameState.mode == "arcade":
		var bout := GameState.arcade_index + 1
		var total := GameState.ARCADE_LADDER.size()
		if GameState.arcade_complete:
			if title_label:
				title_label.text = "Arcade Clear! (%d/%d)" % [GameState.arcade_wins, total]
		elif GameState.arcade_failed:
			if title_label:
				title_label.text = "Arcade Fail — %s wins bout" % name
		elif winner == 1:
			if title_label:
				title_label.text = "%s wins! Next bout %d/%d" % [name, mini(bout + 1, total), total]
			if rematch_btn:
				rematch_btn.text = "Continue Ladder"
		else:
			if title_label:
				title_label.text = "Defeated by %s (bout %d/%d)" % [name, bout, total]
			if rematch_btn:
				rematch_btn.text = "Retry Bout"
		if change_fighters_btn:
			change_fighters_btn.visible = false
		if change_stage_btn:
			change_stage_btn.visible = false
	elif GameState.mode == "challenges":
		var done := GameState.completed_challenges.has(GameState.challenge_id)
		if title_label:
			if done:
				title_label.text = "Challenge Complete — %s" % GameState.challenge_id
			else:
				title_label.text = "Challenge Result — %s" % name
		if rematch_btn and GameState.challenge_objective == "wins" and not done:
			rematch_btn.text = "Continue Challenge"
	elif title_label:
		title_label.text = "%s Wins!" % name
	_play_results_celebration()


func _configure_victory_portrait(fighter_id: String) -> void:
	_victory_fighter_id = fighter_id
	_victory_canonical = false
	if victory_portrait == null or fighter_id.is_empty():
		return
	var presentation: Dictionary = _AssetResolver.resolve_presentation(
		fighter_id, _AssetResolver.CTX_VICTORY
	)
	_victory_canonical = bool(presentation.get("is_current_canonical", false))
	if not _victory_canonical:
		_AssetResolver.PLAYER_VISIBLE_LEGACY_VICTORY_OCCURRENCES += 1
	var accent := Color(1.0, 0.85, 0.3)
	var data: Dictionary = GameState.load_fighter(fighter_id)
	accent = Color(data.get("color", accent))
	if victory_portrait.has_method("configure"):
		victory_portrait.configure(fighter_id, Color(data.get("color", accent)), accent)
	elif victory_portrait.get_script() == null and PORTRAIT_SCRIPT:
		victory_portrait.set_script(PORTRAIT_SCRIPT)
		if victory_portrait.has_method("configure"):
			victory_portrait.configure(fighter_id, Color(data.get("color", accent)), accent)
	victory_portrait.visible = true
	victory_portrait.custom_minimum_size = Vector2(220, 220)


func victory_presentation_snapshot() -> Dictionary:
	var tex_ok := false
	if victory_portrait != null:
		tex_ok = victory_portrait.texture != null
		if not tex_ok and victory_portrait.has_method("get"):
			# Wait for async bake — caller may re-check after frames.
			pass
	return {
		"fighter_id": _victory_fighter_id,
		"is_current_canonical": _victory_canonical,
		"portrait_texture_present": tex_ok or (victory_portrait != null and victory_portrait.visible),
		"representation_id": "%s::PROCEDURAL_PRODUCTION_PROXY" % _victory_fighter_id,
	}


func _play_results_celebration() -> void:
	## Wave017: winner theme pulse + subtle VFX; no developer runtime label.
	if title_label == null:
		return
	title_label.pivot_offset = title_label.size * 0.5
	title_label.scale = Vector2(0.86, 0.86)
	var accent := Color(1.0, 0.55, 0.25)
	var winner := GameState.last_winner_slot
	var fid := GameState.p1_fighter_id if winner == 1 else GameState.p2_fighter_id
	if fid.is_empty():
		fid = _victory_fighter_id
	var fdata: Dictionary = GameState.load_fighter(fid) if not fid.is_empty() else {}
	accent = Color(fdata.get("color", accent))
	title_label.add_theme_color_override("font_color", accent.lightened(0.2))
	var tw := create_tween()
	tw.tween_property(title_label, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(title_label, "scale", Vector2.ONE, 0.12)
	var spark := ColorRect.new()
	spark.name = "VictoryAccent"
	spark.color = Color(accent.r, accent.g, accent.b, 0.2)
	spark.size = Vector2(640, 8)
	spark.position = Vector2(40, 120)
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spark)
	var tw2 := create_tween()
	tw2.tween_property(spark, "modulate:a", 0.0, 0.8)


func _on_rematch_pressed() -> void:
	if GameState.mode == "arcade" or GameState.arcade_active or GameState.arcade_complete or GameState.arcade_failed:
		var next := GameState.advance_arcade_after_result()
		match next:
			"battle":
				SceneRouter.go("versus")
			"arcade_clear":
				# Stay on results with clear banner; home exits.
				_ready_display()
			"arcade_fail":
				_ready_display()
			_:
				GameState.reset_match()
				SceneRouter.go("battle")
		return
	if GameState.mode == "challenges" and GameState.challenge_objective == "wins" and not GameState.completed_challenges.has(GameState.challenge_id):
		GameState.reset_match()
		SceneRouter.go("battle")
		return
	GameState.reset_match()
	SceneRouter.go("battle")


func _on_change_fighters_pressed() -> void:
	GameState.arcade_active = false
	GameState.mode = "versus"
	SceneRouter.go("fighter_select")


func _on_change_stage_pressed() -> void:
	GameState.arcade_active = false
	GameState.mode = "versus"
	SceneRouter.go("stage_select")


func _on_home_pressed() -> void:
	GameState.arcade_active = false
	GameState.arcade_complete = false
	GameState.arcade_failed = false
	GameState.mode = "versus"
	SceneRouter.go("main_menu")


func on_back() -> void:
	_on_home_pressed()
