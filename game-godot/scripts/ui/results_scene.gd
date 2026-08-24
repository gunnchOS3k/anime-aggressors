extends "res://scripts/ui/console_menu_base.gd"

@onready var rematch_btn: Button = $VBox/Rematch
@onready var change_fighters_btn: Button = $VBox/ChangeFighters
@onready var change_stage_btn: Button = $VBox/ChangeStage

func _ready() -> void:
	super._ready()
	_ready_display()

func _ready_display() -> void:
	var winner := GameState.last_winner_slot
	var name := "P%d" % winner
	if winner == 1:
		name = GameState.load_fighter(GameState.p1_fighter_id).get("displayName", name)
	elif winner == 2:
		name = GameState.load_fighter(GameState.p2_fighter_id).get("displayName", name)
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

func _play_results_celebration() -> void:
	## Wave017: winner theme pulse + subtle VFX; no developer runtime label.
	if title_label == null:
		return
	title_label.pivot_offset = title_label.size * 0.5
	title_label.scale = Vector2(0.86, 0.86)
	var accent := Color(1.0, 0.55, 0.25)
	var winner := GameState.last_winner_slot
	var fid := GameState.p1_fighter_id if winner == 1 else GameState.p2_fighter_id
	var fdata: Dictionary = GameState.load_fighter(fid)
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
