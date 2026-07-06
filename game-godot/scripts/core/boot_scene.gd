extends Control

func _ready() -> void:
	await get_tree().create_timer(0.35).timeout
	if TouchInputManager.should_show_touch():
		SceneRouter.go("mobile_playtest")
	else:
		SceneRouter.go("main_menu")
