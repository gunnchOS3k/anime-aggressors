extends RefCounted
## Reconciled from Cursor1d7eda52: existing flat_combat_resim API, with atomic
## late-input correction. Local owned-world only, never shipping CharacterBody
## restore, remote state installation, rendered side effects or earned results.
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
var _epoch := 0

func shipping_backend_enabled() -> bool:
	return SHIPPING_BACKEND_ENABLED

func bind(trial_node, roster: Array) -> bool:
	if trial != null: return false # Rebinding cannot silently retire a live history.
	var gate: Dictionary = HumanSeats.validated_two_human_fighters(roster)
	if not bool(gate.get("ok", false)) or trial_node == null or not trial_node._ready_trial:
		failure = "validated_two_owned_fighters_required"; return false
	var selected: Array = gate.human_seats
	for i in range(2):
		if selected[i].fighter_id != trial_node.actors[i].fighter_id or selected[i].seat_id != i + 1:
			failure = "seat_actor_identity_mismatch"; return false
	trial = trial_node; _epoch = int(trial.epoch)
	seats = selected.duplicate(true)
	history.clear(); snapshots.clear(); last_reconciliation = {}; rollback_count = 0; failure = ""
	_store_snapshot(int(trial.frame))
	return true

func advance_confirmed(p1: Dictionary, p2: Dictionary) -> bool:
	return _advance([p1,p2],[true,true])

func advance_with_prediction(local_seat: int, local_input: Dictionary, predicted_remote: Dictionary) -> bool:
	if local_seat not in [0,1]: return false
	var pair: Array = [{},{}]; var flags: Array = [false,false]
	pair[local_seat] = local_input; pair[1-local_seat] = predicted_remote
	flags[local_seat] = true
	return _advance(pair,flags)

func correct_remote_input(frame: int, remote_seat: int, corrected: Dictionary, input_epoch: int = -1) -> Dictionary:
	# Peer/session authorization belongs to the real transport adapter. This
	# API additionally requires its explicit epoch and refuses confirmed rewrite.
	if trial == null or not failure.is_empty(): return _fail("resim_not_bound")
	if input_epoch != _epoch or trial.epoch != _epoch: return _fail("foreign_or_missing_epoch")
	if remote_seat not in [0,1] or not trial.valid_input(corrected): return _fail("invalid_owned_input")
	if frame < 1 or frame > trial.frame or trial.frame-frame > MAX_ROLLBACK_FRAMES: return _fail("outside_retained_window")
	var index := -1
	for i in range(history.size()):
		if int(history[i].frame) == frame: index = i; break
	if index < 0: return _fail("missing_input_history")
	var normalized: Dictionary = trial.normalize_input(corrected)
	if bool(history[index].confirmed[remote_seat]):
		if history[index].inputs[remote_seat] != normalized: return _fail("conflicting_confirmation")
		last_reconciliation = {"ok":true,"rolled_back":false,"duplicate":true,"correction_frame":frame}
		return last_reconciliation.duplicate(true)
	if history[index].inputs[remote_seat] == normalized:
		history[index].confirmed[remote_seat] = true
		last_reconciliation = {"ok":true,"rolled_back":false,"correction_frame":frame}
		return last_reconciliation.duplicate(true)
	var snap_frame := _nearest_snapshot_at_or_before(frame-1)
	if snap_frame < 0: return _fail("missing_world_snapshot")
	var tip_frame: int = int(trial.frame)
	var rebuilt: Array = history.duplicate(true)
	rebuilt[index].inputs[remote_seat] = normalized; rebuilt[index].confirmed[remote_seat] = true
	var replay_rows: Array = rebuilt.filter(func(row):return row.frame > snap_frame)
	if replay_rows.size() != tip_frame-snap_frame: return _fail("noncontiguous_history")
	for i in range(replay_rows.size()):
		if replay_rows[i].frame != snap_frame+i+1: return _fail("noncontiguous_history")
	var before_events: Array = trial.events.duplicate(true)
	var ticket: RefCounted = trial.begin_replay_transaction()
	if ticket == null: return _fail("world_transaction_unavailable")
	if not trial.restore(snapshots[snap_frame].duplicate(true)):
		_finish_transaction(ticket,false); return _fail("snapshot_rejected")
	var pending: Dictionary = {}
	for key in snapshots:
		if int(key) <= snap_frame: pending[key] = snapshots[key].duplicate(true)
	for row in replay_rows:
		if not trial.advance_owned(_epoch,int(row.frame),row.inputs[0],row.inputs[1]):
			var reason := "replay_unsupported:" + str(trial.failure)
			_finish_transaction(ticket,false); return _fail(reason)
		if int(row.frame) % SNAPSHOT_INTERVAL == 0: pending[row.frame] = trial.capture()
	if trial.frame != tip_frame:
		_finish_transaction(ticket,false); return _fail("unexpected_replay_tip")
	pending[tip_frame] = trial.capture()
	_finish_transaction(ticket,true)
	history = rebuilt; snapshots = pending; rollback_count += 1
	var after_events: Array = trial.events.duplicate(true)
	last_reconciliation = {"ok":true,"rolled_back":true,"correction_frame":frame,"remote_seat":remote_seat,"snapshot_frame":snap_frame,"tip_frame":tip_frame,"resim_tip":trial.frame,"rollback_count":rollback_count,
		"retired_intents":before_events.filter(func(event):return not after_events.has(event)),
		"replacement_intents":after_events.filter(func(event):return not before_events.has(event)),
		"shipping_backend_enabled":false,"human_seats":seats.duplicate(true)}
	return last_reconciliation.duplicate(true)

func capture_world() -> Dictionary:
	return {} if trial == null else trial.capture()

func _advance(inputs: Array, confirmed: Array) -> bool:
	if trial == null or not failure.is_empty() or trial.epoch != _epoch: return false
	for input in inputs:
		if not trial.valid_input(input): return false
	var next_frame: int = int(trial.frame)+1
	var pair: Array = [trial.normalize_input(inputs[0]),trial.normalize_input(inputs[1])]
	var ticket: RefCounted = trial.begin_replay_transaction()
	if ticket == null: return false
	if not trial.advance_owned(_epoch,next_frame,pair[0],pair[1]):
		_finish_transaction(ticket,false); return false
	_finish_transaction(ticket,true)
	history.append({"frame":next_frame,"inputs":pair,"confirmed":confirmed.duplicate()})
	while history.size() > MAX_ROLLBACK_FRAMES+SNAPSHOT_INTERVAL+2: history.pop_front()
	if next_frame % SNAPSHOT_INTERVAL == 0 or next_frame == 1: _store_snapshot(next_frame)
	return true

func _store_snapshot(frame: int) -> void:
	snapshots[frame] = trial.capture()
	var keep_after := maxi(0,int(trial.frame)-MAX_ROLLBACK_FRAMES-SNAPSHOT_INTERVAL)
	for key in snapshots.keys():
		if int(key) < keep_after: snapshots.erase(key)

func _nearest_snapshot_at_or_before(frame: int) -> int:
	var best := -1
	for key in snapshots:
		if int(key) <= frame and int(key) > best: best = int(key)
	return best

func _fail(reason: String) -> Dictionary:
	# A rejected packet cannot poison the original world or future valid input.
	last_reconciliation = {"ok":false,"rolled_back":false,"error":reason,"shipping_backend_enabled":false}
	return last_reconciliation.duplicate(true)

func _finish_transaction(ticket: RefCounted, commit: bool) -> bool:
	# Calls remain active in non-debug builds; never hide state writes in assert.
	var success: bool = trial.end_replay_transaction(ticket,commit)
	assert(success)
	return success
