extends Node
## Opens exactly one real SceneTree physics iteration. It never calls fighter
## physics/combat methods, grants contacts, or advances a paused wall clock.
signal frame_started
signal frame_finished(delta: float)

var pending := false
var stepping := false
var frames := 0

class FrameEnd extends Node:
	var clock: Node
	func _physics_process(delta: float) -> void:
		clock.finish_frame(delta)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -10000
	var end := FrameEnd.new()
	end.name = "PhysicsFrameEnd"
	end.clock = self
	end.process_mode = Node.PROCESS_MODE_ALWAYS
	end.process_physics_priority = 10000
	add_child(end)

func request_frame() -> bool:
	if pending or stepping: return false
	pending = true
	return true

func cancel() -> void:
	pending = false
	stepping = false

func _physics_process(_delta: float) -> void:
	if not pending: return
	pending = false
	stepping = true
	frame_started.emit()

func finish_frame(delta: float) -> void:
	if not stepping: return
	stepping = false
	frames += 1
	frame_finished.emit(delta)
