extends RefCounted
## Observation only. Existing Fighter/MoveRunner own all input, cancels and
## damage. A practiced cancel is not proof of an inescapable combination.
const Data = preload("res://scripts/data/data_loader.gd")

var selection: Dictionary = {}
var attempt: Dictionary = {}
var message := "Choose an authored link in the Move List."
var _owner := 0

func choose(actor, source_id: String, target_id: String) -> bool:
	var source: Dictionary = Data.find_move(actor.move_manifest, source_id)
	var target: Dictionary = Data.find_move(actor.move_manifest, target_id)
	if source.is_empty() or target.is_empty(): return false
	var links: Array = source.get("cancel_windows", []).filter(func(row): return str(row.get("to", "")) == target_id and str(row.get("requires", "")) == "hit_confirm")
	if links.is_empty(): return false
	_owner = actor.get_instance_id()
	selection = {"fighter":actor.fighter_id, "source":source_id, "target":target_id,
		"source_command":source.get("input_command", ""), "target_command":target.get("input_command", ""),
		"base_windows":links.duplicate(true)}
	restart("Ready. Land the source, release, then press the target input inside its live cancel window.")
	return true

func clear(reason: String) -> void:
	selection.clear()
	_owner = 0
	restart(reason)

func restart(reason: String) -> void:
	attempt.clear()
	message = reason

func move_started(actor, move_id: String) -> void:
	if selection.is_empty() or actor.get_instance_id() != _owner: return
	if move_id == str(selection.source):
		attempt = {"source_activation":actor.move_runner.activation_id, "source_hit":false,
			"source_event":"", "target_instance":0, "target_activation":-1,
			"accepted_cancel":false, "target_contact":false, "recovered_between":false,
			"outcome":"source_started", "contacts":[], "resolved_windows":actor.move_runner.move_data.get("cancel_windows", []).duplicate(true)}
		message = "Source started. Awaiting a real body hit."
	elif not attempt.is_empty() and move_id == str(selection.target):
		var accepted: bool = bool(attempt.source_hit) and actor.authored_cancel_history.any(func(row):
			return str(row.from) == str(selection.source) and str(row.to) == str(selection.target) and int(row.activation) == int(attempt.source_activation) and int(row.gameplay_frame) == Engine.get_physics_frames())
		attempt.accepted_cancel = accepted
		attempt.target_activation = actor.move_runner.activation_id
		attempt.outcome = "accepted_cancel" if accepted else "separate_attack"
		message = "Cancel accepted. Awaiting target contact; the defender may escape." if accepted else "Separate attack. No hit-confirmed cancel was accepted."
	elif not attempt.is_empty() and not bool(attempt.target_contact):
		restart("Different move interrupted this attempt. Start the source again.")

func move_ended(actor) -> void:
	if selection.is_empty() or attempt.is_empty() or actor.get_instance_id() != _owner: return
	if actor.move_runner.activation_id == int(attempt.source_activation) and not bool(attempt.source_hit) and str(attempt.outcome) == "source_started":
		attempt.outcome = "no_body_hit"
		message = "No body hit. A whiff or interrupted attack cannot grant this link."
	elif actor.move_runner.activation_id == int(attempt.source_activation) and bool(attempt.source_hit) and not bool(attempt.accepted_cancel):
		attempt.outcome = "cancel_window_ended"
		message = "Source hit, but its cancel opportunity ended. Start the source again."
	elif actor.move_runner.activation_id == int(attempt.target_activation) and bool(attempt.accepted_cancel) and not bool(attempt.target_contact) and str(attempt.outcome) != "grab_whiff":
		attempt.outcome = "no_target_contact"
		message = "Cancel accepted; no target contact observed. Check spacing and defender escape."

func contact(attacker, defender, info: Dictionary) -> void:
	# Caller first deduplicates with PracticeStats.contact().
	if selection.is_empty() or attempt.is_empty() or attacker.get_instance_id() != _owner: return
	var activation := int(info.get("attack_activation_id", -1))
	var result := str(info.get("contact_result", ""))
	var body_hit := result == "hit" and not bool(info.get("blocked", false)) and not bool(info.get("armor_block", false))
	var move_id := str(info.get("move_id", ""))
	if activation == int(attempt.source_activation) and move_id == str(selection.source):
		var owns_source: bool = attacker.move_runner.owns_confirmed_contact(info) and attacker.move_runner.current_move_id() == move_id
		# A defended source never earns a cancel, but still needs honest block/
		# Perfect Guard feedback in the lesson rather than an ownership error.
		if not body_hit and attacker.move_runner.active and attacker.move_runner.activation_id == activation and attacker.move_runner.current_move_id() == move_id: owns_source = true
		if not owns_source:
			attempt.outcome = "source_cancel_ownership_unavailable"
			message = "This source contact has no current authored cancel ownership. Route execution remains unverified."
		elif body_hit and not bool(attempt.source_hit):
			attempt.source_hit = true
			attempt.source_event = str(info.get("combat_event_id", ""))
			attempt.target_instance = defender.get_instance_id()
			attempt.outcome = "source_body_hit"
			message = "Body hit confirmed. Release, then press the target input during the live window."
		elif not body_hit:
			attempt.outcome = "source_defended"
			message = "Source %s. Body-hit cancel not earned." % result.to_upper()
	elif activation == int(attempt.target_activation) and move_id == str(selection.target) and bool(attempt.accepted_cancel):
		if defender.get_instance_id() != int(attempt.target_instance):
			message = "Target touched a different opponent; this does not complete the original link."
			return
		attempt.target_contact = true
		if not body_hit:
			attempt.outcome = "target_defended"
			message = "Follow-up %s. Defender counterplay preserved." % result.to_upper()
		elif bool(attempt.recovered_between) or not bool(info.get("defender_in_hitstun_before", false)):
			attempt.outcome = "recovered_follow_up"
			message = "Follow-up hit after defender recovery. Escapable; not a continuous combo."
		else:
			attempt.outcome = "contact_before_recovery"
			message = "Observed target hit before recovery. This attempt does not prove a guaranteed combo."
	else: return
	attempt.contacts.append({"event":info.get("combat_event_id", ""), "frame":info.get("gameplay_frame", -1), "move":move_id, "activation":activation, "result":result, "damage_applied":info.get("damage_applied", 0.0), "defender_in_hitstun_before":info.get("defender_in_hitstun_before", false)})
	if attempt.contacts.size() > 16: attempt.contacts.pop_front()

func observe_defender(actor) -> void:
	if attempt.is_empty() or not bool(attempt.source_hit) or bool(attempt.target_contact) or actor.get_instance_id() != int(attempt.target_instance): return
	if actor.controls_enabled and actor._hitstop <= 0.0 and (actor.state_machine.can_move() or actor.state_machine.can_attack()):
		attempt.recovered_between = true

func grab(actor, info: Dictionary) -> void:
	if selection.is_empty() or attempt.is_empty() or actor.get_instance_id() != _owner or str(selection.target) != "grab" or not bool(attempt.accepted_cancel) or actor.move_runner.activation_id != int(attempt.target_activation): return
	if str(info.get("result", "")) == "whiff":
		attempt.outcome = "grab_whiff"
		message = "Grab cancel accepted; acquisition missed. Range, height and escape remain authoritative."
		return
	if str(info.get("result", "")) != "success" or not is_instance_valid(actor.grabbed_target): return
	var target = actor.grabbed_target
	if target.get_instance_id() != int(attempt.target_instance) or target.grabbed_by != actor: return
	attempt.target_contact = true
	attempt.outcome = "grab_after_recovery" if bool(attempt.recovered_between) else "grab_before_observed_recovery"
	attempt["grab_frame"] = Engine.get_physics_frames()
	message = "Grab acquired after accepted cancel. Defender control had returned; not guaranteed." if bool(attempt.recovered_between) else "Grab acquired before observed recovery. Acquisition is not a damage hit or guaranteed-combo proof."

func snapshot() -> Dictionary:
	return {"selection":selection.duplicate(true), "attempt":attempt.duplicate(true), "message":message}
