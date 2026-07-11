extends Node
class_name MoveRunner

signal move_started(move_id: String)
signal move_ended(move_id: String)
signal phase_changed(phase: String)
signal active_frames_tick(move: Dictionary)

const SIM_FPS := 60.0

var active := false
var move_data: Dictionary = {}
var phase := ""
var frame_in_phase := 0
var total_frame := 0
var _fighter_body: Node2D
var hit_targets: Dictionary = {}
var in_cancel_window := false

func start_move(move: Dictionary, fighter: Node2D) -> void:
	if move.is_empty():
		return
	_fighter_body = fighter
	move_data = move.duplicate(true)
	active = true
	phase = "startup"
	frame_in_phase = 0
	total_frame = 0
	hit_targets.clear()
	in_cancel_window = false
	move_started.emit(move.get("move_id", ""))
	phase_changed.emit(phase)

func cancel() -> void:
	if active:
		move_ended.emit(move_data.get("move_id", ""))
	active = false
	move_data = {}
	phase = ""
	hit_targets.clear()

func tick_sim_frame() -> void:
	if not active:
		return
	total_frame += 1
	frame_in_phase += 1
	var startup: int = int(move_data.get("startup_frames", 0))
	var active_f: int = int(move_data.get("active_frames", 0))
	var recovery: int = int(move_data.get("recovery_frames", 0))
	var cancels: Array = move_data.get("cancel_windows", [])
	in_cancel_window = false
	for w in cancels:
		if total_frame >= int(w.get("start", 0)) and total_frame <= int(w.get("end", 999)):
			in_cancel_window = true
	match phase:
		"startup":
			if frame_in_phase >= startup:
				_set_phase("active")
		"active":
			active_frames_tick.emit(move_data)
			if frame_in_phase >= active_f:
				_set_phase("recovery")
		"recovery":
			if frame_in_phase >= recovery:
				move_ended.emit(move_data.get("move_id", ""))
				active = false
				phase = ""

func _set_phase(next: String) -> void:
	phase = next
	frame_in_phase = 0
	phase_changed.emit(phase)

func is_active_phase() -> bool:
	return active and phase == "active"

func current_move_id() -> String:
	return move_data.get("move_id", "")

func can_hit_target(target: Node) -> bool:
	var id := str(target.get_instance_id())
	if hit_targets.has(id):
		return false
	hit_targets[id] = true
	return true

func debug_summary() -> String:
	if not active:
		return "move:— frame:— phase:— hitbox:false cancel:false"
	return "move:%s frame:%d phase:%s hitbox:%s cancel:%s" % [
		current_move_id(), total_frame, phase, str(is_active_phase()), str(in_cancel_window)
	]
