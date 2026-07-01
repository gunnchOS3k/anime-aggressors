extends Node
class_name BattleSim

## Fixed 60 Hz combat tick accumulator for move runner frame phases.

const SIM_FPS := 60.0
const STEP := 1.0 / SIM_FPS

var fighters: Array = []
var paused := false
var _accum := 0.0

func bind_fighters(list: Array) -> void:
	fighters = list

func set_paused(v: bool) -> void:
	paused = v

func _physics_process(delta: float) -> void:
	if paused:
		return
	_accum += delta
	while _accum >= STEP:
		_accum -= STEP
		_tick_sim_frame()

func _tick_sim_frame() -> void:
	for f in fighters:
		if f == null or not is_instance_valid(f):
			continue
		if f.has_method("tick_combat_frame"):
			f.tick_combat_frame()
