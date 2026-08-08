extends Control

## Digital RC crash/recovery screen — routes back to boot without claiming store packaging.

@onready var status: Label = %Status
@onready var recover_btn: Button = %Recover

var crash_reason: String = "uncaught_error"


func _ready() -> void:
	if status:
		status.text = "Something went wrong.\n%s\nProgress save will be verified on recover." % crash_reason
	if recover_btn:
		recover_btn.pressed.connect(_on_recover)


func configure(reason: String) -> void:
	crash_reason = reason
	if status:
		status.text = "Something went wrong.\n%s\nProgress save will be verified on recover." % crash_reason


func _on_recover() -> void:
	if GameState:
		GameState.ensure_save_loaded()
		GameState.recover_corrupted_profile()
	SceneRouter.go("boot")
