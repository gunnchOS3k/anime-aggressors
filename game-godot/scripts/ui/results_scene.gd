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
	elif title_label:
		title_label.text = "%s Wins!" % name

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
