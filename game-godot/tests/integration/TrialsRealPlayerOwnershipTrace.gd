extends SceneTree
## Digital REAL_PLAYER ownership traces for Trials journeys.
## Does not invent physical devices. SIMULATION ≠ REAL_PLAYER.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Ownership = preload("res://scripts/trials/trial_real_player_ownership.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")

var failures: Array = []
var checks := 0
var held: Array = []
var output := ""


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func keys(actions: Array) -> void:
	if actions == held:
		return
	for key in held:
		if key not in actions:
			Input.action_release("p1_" + key)
	for key in actions:
		if key not in held:
			if not InputMap.has_action("p1_" + key):
				InputMap.add_action("p1_" + key)
			Input.action_press("p1_" + key)
	held = actions.duplicate()


func frames(n: int) -> void:
	for _i in range(n):
		await physics_frame


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs == null:
		_finish()
		return

	## Empty digital trace honesty.
	var empty: Dictionary = Ownership.empty_trace("resonance_trial")
	check(bool(empty.get("digital_only", false)), "empty_digital")
	check(not bool(empty.get("physical_device", true)), "empty_no_physical")
	check(not bool(empty.get("invented_hardware", true)), "empty_no_invented")

	## Resonance — notify_live_hit appends ownership events; seal REAL_PLAYER.
	var prep_r: Dictionary = Bridge.prepare_live_battle("resonance_trial", 1)
	check(bool(prep_r.get("ok", false)), "resonance_prep")
	keys(["attack"])
	await frames(6)
	keys([])
	Bridge.notify_live_hit(14.0, 1)
	var snap_r: Dictionary = gs.trial_sim_snapshot
	check(bool(snap_r.get("player_owned_events", false)), "resonance_owned")
	var trace_r: Dictionary = snap_r.get("ownership_trace", {})
	check(not trace_r.is_empty(), "resonance_trace_present")
	check(int((trace_r.get("events", []) as Array).size()) >= 1, "resonance_trace_events")
	check(not bool(trace_r.get("physical_device", true)), "resonance_digital_only")
	snap_r["phase"] = "results"
	snap_r["score"] = 140
	gs.trial_sim_snapshot = snap_r
	var sealed_r: Dictionary = Bridge.seal_live_resonance_result()
	check(str(sealed_r.get("result_kind", "")) == "REAL_PLAYER", "resonance_real")
	var val_r: Dictionary = Ownership.validate_real_player_trace(sealed_r)
	check(bool(val_r.get("ok", false)), "resonance_trace_valid")
	for f in val_r.get("failures", []):
		check(false, "resonance_val:" + str(f))

	## SIMULATION seal must not mint ownership receipt.
	var sim_only: Dictionary = Derby.seal_real_player(Derby.create(3, "ember-vale"), false)
	sim_only = Ownership.seal_trace(sim_only, str(sim_only.get("result_kind", "SIMULATION")))
	var val_sim: Dictionary = Ownership.validate_real_player_trace(sim_only)
	check(bool(val_sim.get("ok", false)), "sim_trace_valid")
	check(str(sim_only.get("result_kind", "")) != "REAL_PLAYER" or not bool(sim_only.get("ownership_trace", {}).get("ownership_receipt", true)), "sim_no_receipt")

	## Flagline REAL_PLAYER gets digital ownership without inventing hardware.
	var prep_f: Dictionary = Bridge.prepare_live_battle("fractured_accord", 2)
	check(bool(prep_f.get("ok", false)), "flagline_prep")
	var journey := Flagline.run_capture_journey(53, 2)
	journey["actual_combat_bodies"] = true
	journey["live_actor_sync"] = true
	var sealed_f: Dictionary = Bridge._seal_flagline_results(gs, journey)
	check(str(sealed_f.get("result_kind", "")) == "REAL_PLAYER", "flagline_real")
	var val_f: Dictionary = Ownership.validate_real_player_trace(sealed_f)
	check(bool(val_f.get("ok", false)), "flagline_trace_valid")
	check(not bool(sealed_f.get("ownership_trace", {}).get("invented_hardware", true)), "flagline_no_hardware")

	## Journey summary from GameState.
	var summary: Dictionary = Ownership.journey_trace_summary(gs)
	check(bool(summary.get("ok", false)), "summary_ok")
	check(bool(summary.get("digital_only", false)), "summary_digital")
	check(not bool(summary.get("physical_device", true)), "summary_no_physical")
	check(int(summary.get("ledger_real_player", 0)) >= 1, "summary_has_real_ledger")

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Digital REAL_PLAYER ownership traces for Trials; no physical device invention",
		"digital_only": true,
		"physical_device": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("TRIALS_REAL_PLAYER_OWNERSHIP_TRACE.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("TRIALS_REAL_PLAYER_OWNERSHIP_TRACE ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
