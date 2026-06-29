extends Node
class_name Hitstun

signal hitstun_started(duration: float)
signal hitstun_ended

@export var duration: float = 0.0
var active: bool = false

func start(seconds: float) -> void:
	duration = maxf(0.0, seconds)
	active = duration > 0.0
	if active:
		hitstun_started.emit(duration)

func tick(delta: float) -> void:
	if not active:
		return
	duration = maxf(0.0, duration - delta)
	if duration <= 0.0:
		active = false
		hitstun_ended.emit()
