extends RefCounted
## EXPERIMENTAL 2-human-seat input history + world-snapshot resimulation over
## flat_combat_trial. Corrected late remote inputs restore an owned snapshot,
## retire abandoned contact intents, and re-advance. Never flips shipping LAN
## CharacterBody / host-authoritative BattleSim on.

const HumanSeats = preload("res://scripts/net/experimental/human_seat_policy.gd")
const SHIPPING_BACKEND_ENABLED := false
const MAX_ROLLBACK_FRAMES := 8
const SNAPSHOT_INTERVAL := 4

var trial
var seats: Array = []
var history: Array = []
var snapshots: Dictionary = {}
var last_reconciliation: Dictionary = {}
var rollback_count := 0
var failure := ""

func shipping_backend_enabled() -> bool:
	return SHIPPING_BACKEND_ENABLED

func bind(trial_node, roster: Array) -> bool:
	failure = ""
	last_reconciliation = {}
	history.clear()
	snapshots.clear()
	rollback_count = 0
	var gate: Dictionary = HumanSeats.validated_two_human_fighters(roster)
	if not bool(gate.get("ok", false)):
		failure = "validated_2_human_fighting_seats_required"
		return false
	if trial_node == null or not trial_node._ready_trial:
		failure = "trial_not_ready"
		return false
	if shipping_backend_enabled():
		failure = "shipping_backend_must_remain_disabled"
		return false
	trial = trial_node
	seats = gate.get("human_seats", []).duplicate(true)
	_store_snapshot(int(trial.frame))
	return true

func advance_confirmed(p1: Dictionary, p2: Dictionary) -> bool:
	return _advance([p1, p2], [true, true])

func advance_with_prediction(local_seat: int, local_input: Dictionary, predicted_remote: Dictionary) -> bool:
	if local_seat not in [0, 1]:
		failure = "local_seat_out_of_range"
		return false
	var pair: Array = [{}, {}]
	var flags: Array = [false, false]
	pair[local_seat] = local_input
	pair[1 - local_seat] = predicted_remote
	flags[local_seat] = true
	flags[1 - local_seat] = false
	return _advance(pair, flags)

func correct_remote_input(frame: int, remote_seat: int, corrected: Dictionary) -> Dictionary:
	last_reconciliation = {}
	if trial == null or failure != "":
		return _fail("resim_not_bound")
	if remote_seat not in [0, 1]:
		return _fail("remote_seat_out_of_range")
	if frame < 1 or frame > trial.frame:
		return _fail("correction_frame_out_of_range")
	if trial.frame - frame > MAX_ROLLBACK_FRAMES:
		return _fail("beyond_rollback_window")
	var snap_frame: int = _nearest_snapshot_at_or_before(frame - 1)
	if snap_frame < 0 or not snapshots.has(snap_frame):
		return _fail("missing_world_snapshot")
	var before_events: Array = trial.events.duplicate(true)
	var tip_frame: int = int(trial.frame)
	if not trial.restore(snapshots[snap_frame].duplicate(true)):
		return _fail("world_snapshot_restore_rejected")
	# Replay owned history from the snapshot, substituting the corrected remote
	# input only on the declared correction frame. Local confirmed inputs stay.
	var rebuilt: Array = []
	for step in history:
		var step_frame: int = int(step.frame)
		if step_frame <= snap_frame:
			continue
		if step_frame > tip_frame:
			break
		var inputs: Array = [step.inputs[0].duplicate(true), step.inputs[1].duplicate(true)]
		var confirmed: Array = [bool(step.confirmed[0]), bool(step.confirmed[1])]
		if step_frame == frame:
			inputs[remote_seat] = corrected.duplicate(true)
			confirmed[remote_seat] = true
		if not trial.advance_owned(trial.epoch, step_frame, inputs[0], inputs[1]):
			return _fail("resim_advance_failed:" + trial.failure)
		rebuilt.append({"frame": step_frame, "inputs": inputs, "confirmed": confirmed})
	# Replace the mutable tip of history with the rebuilt confirmed path.
	history = history.filter(func(step): return int(step.frame) <= snap_frame) + rebuilt
	_prune_snapshots_after(snap_frame)
	_store_snapshot(trial.frame)
	rollback_count += 1
	var after_events: Array = trial.events.duplicate(true)
	var retired: Array = before_events.filter(func(event): return not after_events.any(func(keep): return keep == event))
	var added: Array = after_events.filter(func(event): return not before_events.any(func(old): return old == event))
	last_reconciliation = {
		"ok": true,
		"rolled_back": true,
		"correction_frame": frame,
		"remote_seat": remote_seat,
		"snapshot_frame": snap_frame,
		"tip_frame": tip_frame,
		"resim_tip": trial.frame,
		"rollback_count": rollback_count,
		"retired_intents": retired,
		"replacement_intents": added,
		"shipping_backend_enabled": shipping_backend_enabled(),
		"human_seats": seats.duplicate(true),
	}
	return last_reconciliation

func capture_world() -> Dictionary:
	if trial == null:
		return {}
	return trial.capture()

func _advance(inputs: Array, confirmed: Array) -> bool:
	if trial == null:
		failure = "resim_not_bound"
		return false
	if shipping_backend_enabled():
		failure = "shipping_backend_must_remain_disabled"
		return false
	var next_frame: int = int(trial.frame) + 1
	if not trial.advance_owned(trial.epoch, next_frame, inputs[0], inputs[1]):
		failure = trial.failure if not trial.failure.is_empty() else "advance_rejected"
		return false
	history.append({
		"frame": next_frame,
		"inputs": [inputs[0].duplicate(true), inputs[1].duplicate(true)],
		"confirmed": [bool(confirmed[0]), bool(confirmed[1])],
	})
	while history.size() > MAX_ROLLBACK_FRAMES + SNAPSHOT_INTERVAL + 2:
		history.pop_front()
	if next_frame % SNAPSHOT_INTERVAL == 0 or next_frame == 1:
		_store_snapshot(next_frame)
	return true

func _store_snapshot(frame: int) -> void:
	snapshots[frame] = trial.capture()
	var keep_after: int = maxi(0, int(trial.frame) - MAX_ROLLBACK_FRAMES - SNAPSHOT_INTERVAL)
	for key in snapshots.keys():
		if int(key) < keep_after:
			snapshots.erase(key)

func _prune_snapshots_after(frame: int) -> void:
	for key in snapshots.keys():
		if int(key) > frame:
			snapshots.erase(key)

func _nearest_snapshot_at_or_before(frame: int) -> int:
	var best: int = -1
	for key in snapshots.keys():
		var value: int = int(key)
		if value <= frame and value > best:
			best = value
	return best

func _fail(reason: String) -> Dictionary:
	failure = reason
	last_reconciliation = {
		"ok": false,
		"rolled_back": false,
		"error": reason,
		"shipping_backend_enabled": shipping_backend_enabled(),
	}
	return last_reconciliation
