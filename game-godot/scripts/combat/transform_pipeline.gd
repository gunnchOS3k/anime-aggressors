extends RefCounted
class_name TransformPipeline

## Pause-safe transform sequence orchestration (Wave021 OWNER-REG-023).

signal transform_started(fighter_id: String, from_form: String, to_form: String)
signal transform_completed(fighter_id: String, form_id: String)
signal transform_failed(reason: String)

const _AuraTier = preload("res://scripts/combat/aura_tier_contract.gd")
const _FormDefinition = preload("res://scripts/combat/form_definition.gd")

const STATE_IDLE := "idle"
const STATE_CHARGING := "charging"
const STATE_SEQUENCE := "sequence"
const STATE_COMPLETE := "complete"

var _state: String = STATE_IDLE
var _fighter = null
var _from_form: String = ""
var _to_form: String = ""
var _sequence_t: float = 0.0
var _sequence_duration: float = 1.2
var _pause_safe: bool = true


func setup(fighter) -> void:
	_fighter = fighter


func get_state() -> String:
	return _state


func is_transforming() -> bool:
	return _state in [STATE_CHARGING, STATE_SEQUENCE]


func can_attempt_transform() -> bool:
	if _fighter == null:
		return false
	if is_transforming():
		return false
	if not _fighter.has_method("get_aura"):
		return false
	if not _AuraTier.can_initiate_transform(_fighter.get_aura()):
		return false
	if not _fighter.has_method("get_current_form_id"):
		return false
	var forms_doc: Dictionary = _fighter.get_forms_doc() if _fighter.has_method("get_forms_doc") else {}
	if forms_doc.is_empty():
		return false
	var current: String = _fighter.get_current_form_id()
	var nxt := _FormDefinition.next_form_id(forms_doc, current)
	return nxt != current


func attempt_transform() -> bool:
	if not can_attempt_transform():
		transform_failed.emit("not_ready")
		return false
	var forms_doc: Dictionary = _fighter.get_forms_doc()
	_from_form = _fighter.get_current_form_id()
	_to_form = _FormDefinition.next_form_id(forms_doc, _from_form)
	var target: Dictionary = _FormDefinition.form_entry(forms_doc, _to_form)
	_sequence_duration = float(target.get("transform_in_seconds", 1.2))
	_pause_safe = bool(forms_doc.get("transform_rules", {}).get("pause_safe", true))
	_state = STATE_SEQUENCE
	_sequence_t = 0.0
	transform_started.emit(_fighter.fighter_id, _from_form, _to_form)
	if _fighter.has_method("on_transform_sequence_start"):
		_fighter.on_transform_sequence_start(_from_form, _to_form)
	return true


func tick(delta: float, game_paused: bool) -> void:
	if _state != STATE_SEQUENCE:
		return
	if game_paused and not _pause_safe:
		return
	_sequence_t += delta
	var progress := clampf(_sequence_t / maxf(_sequence_duration, 0.01), 0.0, 1.0)
	if _fighter != null and _fighter.has_method("on_transform_sequence_tick"):
		_fighter.on_transform_sequence_tick(progress)
	if progress >= 1.0:
		_complete()


func _complete() -> void:
	_state = STATE_COMPLETE
	if _fighter != null and _fighter.has_method("apply_form"):
		_fighter.apply_form(_to_form)
	transform_completed.emit(_fighter.fighter_id if _fighter else "", _to_form)
	_state = STATE_IDLE
	_from_form = ""
	_to_form = ""
	_sequence_t = 0.0


func force_reset() -> void:
	_state = STATE_IDLE
	_from_form = ""
	_to_form = ""
	_sequence_t = 0.0
