extends RefCounted
class_name TrialRealPlayerOwnership
## Digital REAL_PLAYER ownership traces for Trials journeys.
## Records player-owned combat events into a digital ledger trace.
## Does NOT invent physical devices, controllers, or USB hardware.
## SIMULATION seals never mint REAL_PLAYER ownership traces.

const TRACE_META := "trial_ownership_trace"


static func empty_trace(mode_id: String) -> Dictionary:
	return {
		"schema": "anime_trials.ownership_trace.v1",
		"mode_id": mode_id,
		"events": [],
		"player_owned_events": false,
		"digital_only": true,
		"physical_device": false,
		"physical_controller": false,
		"invented_hardware": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"feeds_ranked_mmr": false,
	}


static func append_hit_event(snap: Dictionary, damage: float, facing: int = 1, lane: int = -1) -> Dictionary:
	## Mutates/returns snapshot with ownership_trace event from ordinary hit notify.
	var out: Dictionary = snap.duplicate(true)
	var mode_id := str(out.get("mode_id", out.get("trial_mode_id", "")))
	var trace: Dictionary = out.get("ownership_trace", {})
	if trace.is_empty() or not trace is Dictionary:
		trace = empty_trace(mode_id)
	var events: Array = trace.get("events", [])
	events.append({
		"kind": "live_hit",
		"damage": float(damage),
		"facing": int(facing),
		"lane": int(lane),
		"frame": int(out.get("frame", events.size())),
		"source": "digital_notify_live_hit",
		"physical_device": false,
	})
	trace["events"] = events
	trace["player_owned_events"] = true
	trace["digital_only"] = true
	trace["physical_device"] = false
	trace["physical_controller"] = false
	trace["invented_hardware"] = false
	trace["mode_id"] = mode_id if not mode_id.is_empty() else str(trace.get("mode_id", ""))
	out["ownership_trace"] = trace
	out["player_owned_events"] = true
	return out


static func seal_trace(snap: Dictionary, result_kind: String) -> Dictionary:
	## Attach sealed ownership honesty onto a result snapshot. Never upgrades SIM→REAL.
	var out: Dictionary = snap.duplicate(true)
	var owned := bool(out.get("player_owned_events", false))
	var trace: Dictionary = out.get("ownership_trace", {})
	if trace.is_empty():
		trace = empty_trace(str(out.get("mode_id", "")))
	trace = trace.duplicate(true)
	trace["sealed_result_kind"] = result_kind
	trace["player_owned_events"] = owned
	trace["digital_only"] = true
	trace["physical_device"] = false
	trace["physical_controller"] = false
	trace["invented_hardware"] = false
	trace["event_count"] = int((trace.get("events", []) as Array).size())
	## REAL_PLAYER requires owned events; SIMULATION never claims ownership receipt.
	if result_kind == "REAL_PLAYER":
		trace["ownership_receipt"] = owned and int(trace.get("event_count", 0)) >= 1
		trace["honesty"] = "REAL_PLAYER digital ownership trace — not physical device proof"
	else:
		trace["ownership_receipt"] = false
		trace["honesty"] = "SIMULATION — no REAL_PLAYER ownership receipt"
	out["ownership_trace"] = trace
	return out


static func validate_real_player_trace(sealed: Dictionary) -> Dictionary:
	var failures: Array = []
	var kind := str(sealed.get("result_kind", ""))
	var trace: Dictionary = sealed.get("ownership_trace", {})
	if kind == "REAL_PLAYER":
		if not bool(sealed.get("player_owned_events", false)) and not bool(trace.get("player_owned_events", false)):
			failures.append("real_without_owned_flag")
		if trace.is_empty():
			failures.append("missing_ownership_trace")
		elif not bool(trace.get("ownership_receipt", false)):
			failures.append("missing_ownership_receipt")
		elif bool(trace.get("physical_device", true)):
			failures.append("must_not_claim_physical_device")
		elif bool(trace.get("invented_hardware", true)):
			failures.append("must_not_invent_hardware")
		elif not bool(trace.get("digital_only", false)):
			failures.append("must_be_digital_only")
	elif kind == "SIMULATION":
		if bool(trace.get("ownership_receipt", false)):
			failures.append("sim_cannot_own_receipt")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"result_kind": kind,
		"digital_only": true,
		"physical_device": false,
	}


static func journey_trace_summary(gs: Node) -> Dictionary:
	## Summarize digital ownership from GameState trial ledger + live snapshot.
	if gs == null:
		return {"ok": false, "reason": "no_gamestate"}
	var snap: Dictionary = gs.trial_sim_snapshot if gs.get("trial_sim_snapshot") != null else {}
	var records: Array = gs.trial_records if gs.get("trial_records") != null else []
	var real_rows := 0
	var sim_rows := 0
	for rec in records:
		if str(rec.get("result_kind", "")) == "REAL_PLAYER":
			real_rows += 1
		else:
			sim_rows += 1
	var trace: Dictionary = snap.get("ownership_trace", {}) if snap is Dictionary else {}
	return {
		"ok": true,
		"mode_id": str(gs.trial_mode_id) if gs.get("trial_mode_id") != null else "",
		"live_player_owned": bool(snap.get("player_owned_events", false)) if snap is Dictionary else false,
		"trace_events": int((trace.get("events", []) as Array).size()) if not trace.is_empty() else 0,
		"ledger_real_player": real_rows,
		"ledger_simulation": sim_rows,
		"digital_only": true,
		"physical_device": false,
		"invented_hardware": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}
