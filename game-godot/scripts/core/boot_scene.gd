extends Control

func _ready() -> void:
	await get_tree().create_timer(0.35).timeout
	SceneRouter.go("main_menu")
