extends ConsoleMenuBase

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
	if title_label:
		title_label.text = "%s Wins!" % name

func _on_rematch_pressed() -> void:
	GameState.reset_match()
	SceneRouter.go("battle")

func _on_change_fighters_pressed() -> void:
	SceneRouter.go("fighter_select")

func _on_change_stage_pressed() -> void:
	SceneRouter.go("stage_select")

func _on_home_pressed() -> void:
	SceneRouter.go("main_menu")

func on_back() -> void:
	SceneRouter.go("main_menu")
