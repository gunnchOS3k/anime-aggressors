extends Node
## Opens exactly one real SceneTree physics iteration. It never calls fighter
## physics/combat methods, grants contacts, or advances a paused wall clock.
signal frame_started
signal frame_finished(delta: float)

var pending := false
var stepping := false
var frames := 0
var _frame_delta := 0.0
var _previous_max_steps := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -10000

func request_frame() -> bool:
	if pending or stepping: return false
	# A low-render-rate catch-up must not run a second physics tick before
	# process_frame. Restore the caller's limit after this one requested tick.
	_previous_max_steps = Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame = 1
	pending = true
	return true

func cancel() -> void:
	pending = false
	stepping = false
	if is_inside_tree() and get_tree().process_frame.is_connected(finish_frame):
		get_tree().process_frame.disconnect(finish_frame)
	_restore_step_limit()

func _physics_process(delta: float) -> void:
	# Input can arrive after Main has already calculated this render frame's
	# catch-up count. Close before a second actor tick even in that case; the
	# first server step (and its next query flush) have already completed.
	if stepping:
		finish_frame()
		return
	if not pending: return
	pending = false
	stepping = true
	_frame_delta = delta
	# Godot runs PhysicsServer2D.step AFTER all SceneTree physics callbacks
	# (and deferred calls). Pausing from a late physics node disables that
	# server step and leaves Area2D contacts stale. process_frame is the first
	# public boundary after the server step and before idle presentation.
	get_tree().process_frame.connect(finish_frame, CONNECT_ONE_SHOT)
	frame_started.emit()

func finish_frame() -> void:
	if not stepping: return
	stepping = false
	if get_tree().process_frame.is_connected(finish_frame):
		get_tree().process_frame.disconnect(finish_frame)
	frames += 1
	_restore_step_limit()
	frame_finished.emit(_frame_delta)

func _restore_step_limit() -> void:
	if _previous_max_steps > 0:
		Engine.max_physics_steps_per_frame = _previous_max_steps
		_previous_max_steps = 0

func _exit_tree() -> void:
	cancel()
