extends Node
class_name BattleSim

## Fixed 60 Hz combat tick accumulator for move runner frame phases.

const SIM_FPS := 60.0
const STEP := 1.0 / SIM_FPS
signal frame_completed(frame: int)
# frame_completed is the synchronous move/projectile phase, NOT physics commit.
# PhysicsServer flushes the previous step's queries before physics_frame. That
# per-physics boundary also works when several ticks share one render frame.
signal frame_committing(frame: int, active_at_step: bool)
signal frame_committed(frame: int)
var simulation_frame := 0
var completed_engine_frame := 0
var network_commit_enabled := false
var commit_in_progress := false
var committed_frame := 0
var committed_engine_frame := 0
var committed_at_engine_frame := 0
var committed_active := false
var network_epoch := 0
var _pending_frame: Dictionary = {}
var _commit_owner: WeakRef

var fighters: Array = []
var paused := false
var freeze := false
var _accum := 0.0
var _step_once := false
var projectile_interactions = preload("res://scripts/combat/projectile_interactions.gd").new()
var body_spacing = preload("res://scripts/combat/fighter_body_spacing.gd").new()

func _init() -> void:
	# Fighters first finish stage movement; spacing and combat then see one
	# completed snapshot, regardless of their child/list update order.
	process_physics_priority = 1

func enable_network_commit(owner: Node, epoch: int) -> void:
	assert(is_inside_tree() and epoch > 0 and not network_commit_enabled)
	_commit_owner = weakref(owner)
	network_epoch = epoch
	network_commit_enabled = true
	get_tree().physics_frame.connect(_close_physics_frame)

func _close_physics_frame() -> void:
	if not network_commit_enabled or _pending_frame.is_empty(): return
	var owner = _commit_owner.get_ref() if _commit_owner != null else null
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner._network_abandoned:
		_pending_frame.clear()
		return
	var session = owner.get_node_or_null("/root/LanSession")
	if session == null or session.role != "host" or session.epoch != network_epoch:
		_pending_frame.clear()
		return
	# Previous step's deferred polls and PhysicsServer query callbacks have
	# completed. No next-frame actor/input callback has run at this boundary.
	if Engine.get_physics_frames() <= int(_pending_frame.engine_frame): return
	commit_in_progress = true
	var frame: int = _pending_frame.frame
	frame_committing.emit(frame, bool(_pending_frame.active))
	committed_frame = frame
	committed_engine_frame = int(_pending_frame.engine_frame)
	committed_at_engine_frame = Engine.get_physics_frames()
	committed_active = bool(_pending_frame.active)
	_pending_frame.clear()
	commit_in_progress = false
	frame_committed.emit(frame)

func _exit_tree() -> void:
	if get_tree().physics_frame.is_connected(_close_physics_frame):
		get_tree().physics_frame.disconnect(_close_physics_frame)
	_pending_frame.clear()
	_commit_owner = null

func bind_fighters(list: Array) -> void:
	for f in fighters:
		if is_instance_valid(f) and "_batch_locomotion" in f:f._batch_locomotion=false
	fighters = list
	for f in fighters:
		if is_instance_valid(f) and "_batch_locomotion" in f:f._batch_locomotion=true

func set_paused(v: bool) -> void:
	paused = v

func set_freeze(v: bool) -> void:
	freeze = v
	paused = v

func step_frame() -> void:
	_step_once = true

func _physics_process(delta: float) -> void:
	if paused and not _step_once:
		return
	if freeze and not _step_once:
		return
	_accum += delta if not _step_once else STEP
	while _accum >= STEP:
		_accum -= STEP
		_tick_sim_frame()
		if _step_once:
			_step_once = false
			break

func _tick_sim_frame() -> void:
	var step_active := false
	if network_commit_enabled:
		var owner = _commit_owner.get_ref() if _commit_owner != null else null
		step_active = is_instance_valid(owner) and bool(owner._active)
	body_spacing.resolve(fighters)
	for f in fighters:
		if is_instance_valid(f) and f.has_method("sync_locomotion_presentation") and f._hitstop<=0:
			f.sync_locomotion_presentation()
	projectile_interactions.begin_frame(fighters)
	for f in fighters:
		if f == null or not is_instance_valid(f):
			continue
		if f.has_method("tick_combat_frame"):
			f.tick_combat_frame()
	projectile_interactions.resolve_frame(fighters)
	simulation_frame += 1
	completed_engine_frame = Engine.get_physics_frames()
	if network_commit_enabled:
		assert(_pending_frame.is_empty(), "Network combat requires one complete step per physics iteration")
		_pending_frame = {"frame":simulation_frame, "engine_frame":completed_engine_frame, "active":step_active}
	frame_completed.emit(simulation_frame)
