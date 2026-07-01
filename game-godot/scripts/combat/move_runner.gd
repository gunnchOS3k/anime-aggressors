extends Node
class_name MoveRunner

signal move_started(move_id: String)
signal move_ended(move_id: String)
signal active_frames_tick(move: Dictionary)

var active := false
var move_data: Dictionary = {}
var phase := ""
var frame_in_phase := 0
var owner: Node2D

func start_move(move: Dictionary, fighter: Node2D) -> void:
	if move.is_empty():
		return
	owner = fighter
	move_data = move
	active = true
	phase = "startup"
	frame_in_phase = 0
	move_started.emit(move.get("move_id", ""))

func cancel() -> void:
	if active:
		move_ended.emit(move_data.get("move_id", ""))
	active = false
	move_data = {}

func tick() -> void:
	if not active:
		return
	frame_in_phase += 1
	var startup: int = move_data.get("startup_frames", 0)
	var active_f: int = move_data.get("active_frames", 0)
	var recovery: int = move_data.get("recovery_frames", 0)
	match phase:
		"startup":
			if frame_in_phase >= startup:
				phase = "active"
				frame_in_phase = 0
		"active":
			active_frames_tick.emit(move_data)
			if frame_in_phase >= active_f:
				phase = "recovery"
				frame_in_phase = 0
		"recovery":
			if frame_in_phase >= recovery:
				move_ended.emit(move_data.get("move_id", ""))
				active = false

func is_active_phase() -> bool:
	return active and phase == "active"

func current_move_id() -> String:
	return move_data.get("move_id", "")
