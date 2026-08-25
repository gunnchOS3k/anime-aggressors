extends Node
class_name CharacterSelectShowcaseFlourish

## Wave020 revised — fighter-specific select showcase flourish + audio integration.

const _AudioBank = preload("res://scripts/audio/procedural_audio_bank.gd")

signal flourish_finished(fighter_id: String, source: String)

var _model: Node2D
var _fighter_id: String = ""
var _active := false
var _cooldown_until_ms: int = 0
var _debounce_ms: int = 900
var _cooldown_ms: int = 1800

var flourish_trigger_cases: int = 0
var flourish_wrong_fighter_cases: int = 0
var flourish_stuck_state_cases: int = 0
var flourish_visibility_regressions: int = 0
var flourish_battle_handoff_regressions: int = 0
var fighters_covered: Dictionary = {}


func bind_model(model: Node2D) -> void:
	_model = model


func set_fighter(fighter_id: String) -> void:
	if _active and _fighter_id != fighter_id:
		cancel_flourish("fighter_switch")
	_fighter_id = fighter_id


func can_trigger() -> bool:
	if _fighter_id.is_empty() or _model == null:
		return false
	if _active:
		return false
	return Time.get_ticks_msec() >= _cooldown_until_ms


func trigger(source: String, expected_fighter_id: String = "") -> bool:
	var fid := expected_fighter_id if not expected_fighter_id.is_empty() else _fighter_id
	if fid.is_empty() or _model == null:
		return false
	if not fid.is_empty() and not _fighter_id.is_empty() and fid != _fighter_id:
		flourish_wrong_fighter_cases += 1
		return false
	if not can_trigger():
		return false
	if _model.has_method("is_visible_renderable_body") and not _model.is_visible_renderable_body():
		flourish_visibility_regressions += 1
		return false
	_active = true
	flourish_trigger_cases += 1
	fighters_covered[fid] = true
	_play_flourish(fid, source)
	return true


func cancel_flourish(reason: String = "") -> void:
	if not _active:
		return
	_active = false
	_cooldown_until_ms = Time.get_ticks_msec() + _debounce_ms
	if _model != null and _model.has_method("play_selection_focus"):
		_model.play_selection_focus()
	if reason == "stuck":
		flourish_stuck_state_cases += 1


func is_active() -> bool:
	return _active


func note_battle_handoff(ok: bool) -> void:
	if not ok:
		flourish_battle_handoff_regressions += 1


func counters() -> Dictionary:
	return {
		"FLOURISH_FIGHTERS_COVERED": fighters_covered.size(),
		"FLOURISH_TRIGGER_CASES": flourish_trigger_cases,
		"FLOURISH_WRONG_FIGHTER_CASES": flourish_wrong_fighter_cases,
		"FLOURISH_STUCK_STATE_CASES": flourish_stuck_state_cases,
		"FLOURISH_VISIBILITY_REGRESSIONS": flourish_visibility_regressions,
		"FLOURISH_BATTLE_HANDOFF_REGRESSIONS": flourish_battle_handoff_regressions,
	}


func reset_for_test_harness() -> void:
	_active = false
	_cooldown_until_ms = 0

func _play_flourish(fid: String, source: String) -> void:
	if _model.has_method("set_aura_level"):
		_model.set_aura_level(3)
	if _model.has_method("set_expression"):
		_model.set_expression("confident")
	match fid:
		"ember-vale":
			if _model.has_method("set_aura_level"):
				_model.set_aura_level(4)
			if _model.has_method("play_for_state"):
				_model.play_for_state("special", {"move_id": "flame_burst"})
		"rook-ironside":
			if _model.has_method("play_for_state"):
				_model.play_for_state("throw_startup", {"throw_direction": "down"})
		"juno-spark":
			if _model.has_method("play_for_state"):
				_model.play_for_state("run", {})
		"kaia-windrow":
			if _model.has_method("play_for_state"):
				_model.play_for_state("jump", {})
		"nix-calder":
			if _model.has_method("play_for_state"):
				_model.play_for_state("shield", {})
		"orion-vell":
			if _model.has_method("play_for_state"):
				_model.play_for_state("aura_charge", {})
		"vesper-nyx":
			if _model.has_method("play_for_state"):
				_model.play_for_state("special", {"move_id": "shadow_phase"})
		_:
			if _model.has_method("play_lock_in"):
				_model.play_lock_in()
	_play_flourish_audio(fid)
	var t := get_tree().create_timer(1.05)
	t.timeout.connect(func():
		if _model != null and is_instance_valid(_model):
			if _model.has_method("set_aura_level"):
				_model.set_aura_level(1)
			if _model.has_method("play_selection_focus"):
				_model.play_selection_focus()
			if _model.has_method("is_visible_renderable_body") and not _model.is_visible_renderable_body():
				flourish_visibility_regressions += 1
		_active = false
		_cooldown_until_ms = Time.get_ticks_msec() + _cooldown_ms
		emit_signal("flourish_finished", fid, source)
	, CONNECT_ONE_SHOT)


func _play_flourish_audio(fid: String) -> void:
	for cat in ["charge", "signature"]:
		var path := _AudioBank.fighter_path(fid, cat)
		_AudioBank.play(path, self, -2.0)
