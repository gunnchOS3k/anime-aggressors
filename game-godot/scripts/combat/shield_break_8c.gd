extends RefCounted
## Lifecycle/configuration for the EXISTING shield-break state. No hit resolver,
## damage, invulnerability, Story progression or new input authority.
var fighter
var active := false
var candidate := false
var activation := 0
var needs_guard_release := false
var history: Array = []
var _config: Dictionary = {}

func setup(actor) -> void:
	fighter = actor
	_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/shield_break_candidate_8c.json"))

func requested() -> bool:
	if not is_instance_valid(fighter) or not bool(fighter.get_meta("shield_break_8c_candidate", false)):return false
	var gs = fighter.get_node_or_null("/root/GameState")
	return gs != null and str(gs.mode) in ["versus", "training", "hazards"]

func begin() -> void:
	activation += 1;active = true;candidate = requested()
	if candidate:needs_guard_release = true
	var info := {"result":"shield_break", "event_id":"shield-break:%d:%d" % [fighter.get_instance_id(), activation], "fighter":fighter.fighter_id, "candidate":candidate, "health":fighter.shield_health, "state":fighter.state_machine.current_state, "recovery_frames":int(_config.recovery_frames) if candidate else -1, "baseline_seconds":.4, "gameplay_frame":Engine.get_physics_frames()}
	if fighter._guard_presentation != null:info["primary_shown"] = fighter._guard_presentation.break_event(info.event_id)
	_record(info)

func observe_guard(held: bool) -> void:
	if not held:needs_guard_release = false

func guard_allowed() -> bool:
	return not needs_guard_release

func holds_lock() -> bool:
	return active and candidate and fighter.state_machine.current_state == "shield_break"

func ready(frame: int, seconds: float) -> bool:
	# Preserve the accepted strict .4s baseline. Only the explicit candidate
	# opts into a fixed simulation-frame experiment.
	return frame >= int(_config.recovery_frames) if active and candidate else seconds > .4

func recover() -> void:
	var maximum: float = float(fighter.data.get("shieldProfile", {}).get("maxHealth", 100))
	fighter.shield_health = maximum * (float(_config.restored_health_fraction) if active and candidate else 1.0)
	_record({"result":"shield_recovered", "fighter":fighter.fighter_id, "activation":activation, "candidate":candidate, "health":fighter.shield_health, "gameplay_frame":Engine.get_physics_frames()})
	active = false

func state_changed(to: String) -> void:
	if active and to != "shield_break":
		_record({"result":"shield_break_retired", "reason":to, "activation":activation, "candidate":candidate})
		active = false

func reset(reason: String) -> void:
	if active:_record({"result":"shield_break_retired", "reason":reason, "activation":activation, "candidate":candidate})
	active = false;candidate = false;needs_guard_release = false

func _record(info: Dictionary) -> void:
	history.append(info)
	if history.size() > 64:history.pop_front()
	if is_instance_valid(fighter) and fighter.has_signal("shield_event"):fighter.shield_event.emit(info)

func snapshot() -> Dictionary:
	return {"active":active, "candidate":candidate, "activation":activation, "needs_guard_release":needs_guard_release, "candidate_frames":int(_config.get("recovery_frames",66)), "status":"TUNING_CANDIDATE_NOT_BALANCE_APPROVED", "baseline_changed":false}
