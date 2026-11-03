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
var activation_id := 0
# Runtime callback ownership, deliberately NOT serialized or rewound. An old
# deferred collision request must not become valid again after state restore.
var contact_generation := 0
var in_cancel_window := false
var confirmed_body_hit := false

func start_move(move: Dictionary, fighter: Node2D) -> void:
	if move.is_empty():
		return
	_fighter_body = fighter
	contact_generation += 1
	activation_id += 1
	move_data = move.duplicate(true)
	active = true
	phase = "startup"
	frame_in_phase = 0
	total_frame = 0
	hit_targets.clear()
	in_cancel_window = false
	confirmed_body_hit = false
	move_started.emit(move.get("move_id", ""))
	phase_changed.emit(phase)

func cancel() -> void:
	contact_generation += 1
	if active:
		move_ended.emit(move_data.get("move_id", ""))
	active = false
	move_data = {}
	phase = ""
	hit_targets.clear()
	confirmed_body_hit = false
	in_cancel_window = false

func record_confirmed_contact(info: Dictionary) -> void:
	if owns_confirmed_contact(info): confirmed_body_hit = true

func owns_confirmed_contact(info: Dictionary) -> bool:
	if not active or not bool(info.get("confirmed_contact", false)) or str(info.get("contact_result", "")) != "hit" or bool(info.get("blocked", false)) or bool(info.get("armor_block", false)) or int(info.get("attack_activation_id", -1)) != activation_id: return false
	if str(info.get("contact_owner", "")) == "melee": return true
	# Nix's existing authored Frost Shot -> Grab needs its own cast's actual
	# body contact. A lingering shot cannot confirm a replacement activation;
	# no projectile gains a generic cancel or changes its fighter-impact rules.
	if str(info.get("contact_owner", "")) != "projectile" or not move_data.has("projectile") or str(info.get("move_id", "")) != current_move_id(): return false
	if not move_data.get("cancel_windows", []).any(func(window): return str(window.get("to", "")) == "grab" and str(window.get("requires", "")) == "hit_confirm" and int(window.get("end", -1)) >= total_frame): return false
	var instance := int(info.get("projectile_instance_id", 0))
	if instance <= 0 or not is_instance_id_valid(instance): return false
	var shot = instance_from_id(instance)
	return is_instance_valid(shot) and "owner_fighter" in shot and shot.owner_fighter == _fighter_body and "move_data" in shot and int(shot.move_data.get("_attack_activation_id", -1)) == activation_id and str(shot.move_data.get("move_id", "")) == current_move_id()

func can_cancel_to(target_move: String) -> bool:
	if not active:return false
	for window in move_data.get("cancel_windows",[]):
		# Untargeted taxonomy windows are not blanket permission to cancel.
		if str(window.get("to",""))!=target_move:continue
		if total_frame<int(window.get("start",0)) or total_frame>int(window.get("end",-1)):continue
		if str(window.get("requires",""))!="hit_confirm" or not confirmed_body_hit:continue
		return true
	return false

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
				contact_generation += 1
				move_ended.emit(move_data.get("move_id", ""))
				active = false
				phase = ""

func _set_phase(next: String) -> void:
	contact_generation += 1
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


# Local trusted rollback COMPONENT state. This is not a full Fighter/physics/
# projectile/timer snapshot and is never accepted from a network peer.
func capture_component_state() -> Dictionary:
	var result := {"schema":"move_runner/v1"}
	result["owner"] = {"instance":_fighter_body.get_instance_id() if is_instance_valid(_fighter_body) else 0, "fighter":str(_fighter_body.fighter_id) if is_instance_valid(_fighter_body) and "fighter_id" in _fighter_body else ""}
	for key in ["active", "move_data", "phase", "frame_in_phase", "total_frame", "hit_targets", "activation_id", "in_cancel_window", "confirmed_body_hit"]:
		var value = get(key)
		result[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result

func restore_component_state(state: Dictionary) -> bool:
	var baseline := capture_component_state()
	if state.size() != baseline.size() or state.get("schema", "") != baseline.schema: return false
	if state.get("owner", {}) != baseline.owner: return false
	# Validate the entire record BEFORE writes. Restore does not call enter(),
	# start_move(), cancel(), emit signals, spend aura or dispatch presentation.
	for key in baseline:
		if not state.has(key) or typeof(state[key]) != typeof(baseline[key]): return false
	if state.phase not in ["", "startup", "active", "recovery"] or state.total_frame < 0 or state.frame_in_phase < 0 or state.activation_id < 0: return false
	if state.active and (state.phase.is_empty() or str(state.move_data.get("move_id", "")).is_empty()): return false
	contact_generation += 1
	for key in baseline:
		if key in ["schema", "owner"]: continue
		var value = state[key]
		set(key, value.duplicate(true) if value is Dictionary or value is Array else value)
	return true
