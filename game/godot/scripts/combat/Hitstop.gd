extends Node
class_name Hitstop

signal hitstop_started(duration: float)
signal hitstop_ended

@export var default_hitstop: float = 0.06
var timer: float = 0.0
var is_active: bool = false

func start(duration: float = -1.0) -> void:
	timer = default_hitstop if duration < 0.0 else duration
	is_active = true
	hitstop_started.emit(timer)

func tick(delta: float) -> void:
	if not is_active:
		return
	timer -= delta
	if timer <= 0.0:
		timer = 0.0
		is_active = false
		hitstop_ended.emit()
