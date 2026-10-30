extends SceneTree
## AA-RTM-004 digital deepen — ownership traces across all six Trials modes.
## Does not invent physical devices or HUMAN_ART territory meshes.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Ownership = preload("res://scripts/trials/trial_real_player_ownership.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")

var failures: Array = []
var checks := 0
var output := ""


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


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

	var contract: Dictionary = Ownership.six_mode_digital_contract()
	check(bool(contract.get("ok", false)), "six_mode_contract")
	check(int(contract.get("mode_count", 0)) == 6, "six_modes")
	check(not bool(contract.get("device_matrix_pass", true)), "no_device_matrix")
	check(not bool(contract.get("HUMAN_ART_APPROVED", true)), "no_human_art")
	check(not bool(contract.get("territory_mesh_human_art", true)), "no_territory_art")
	for f in contract.get("failures", []):
		check(false, "contract:" + str(f))

	for mode_id in Bridge.LIVE_SHARED_COMBAT_MODES:
		var seats := 2
		var unbound := Unbound.PRESET_TOTAL
		if mode_id == "resonance_trial" or mode_id == "riftline_defense" or mode_id == "echoes_gauntlet":
			seats = 1
		if mode_id == "convergence_unbound":
			unbound = Unbound.PRESET_COLOSSUS
		var prep: Dictionary = Bridge.prepare_live_battle(mode_id, seats, unbound, -1)
		check(bool(prep.get("ok", false)), "prep:" + mode_id)
		check(bool(prep.get("ownership_trace_seeded", false)) or bool(prep.get("digital_only", false)), "seeded:" + mode_id)
		check(not bool(prep.get("device_matrix_pass", true)), "prep_no_matrix:" + mode_id)
		var snap: Dictionary = gs.trial_sim_snapshot
		var trace0: Dictionary = snap.get("ownership_trace", {})
		check(not trace0.is_empty(), "empty_trace:" + mode_id)
		check(bool(trace0.get("digital_only", false)), "trace_digital:" + mode_id)
		check(not bool(trace0.get("physical_device", true)), "trace_no_physical:" + mode_id)

		if mode_id == "fractured_accord":
			var journey := Flagline.run_capture_journey(61, 2)
			journey["actual_combat_bodies"] = true
			journey["live_actor_sync"] = true
			var sealed_f: Dictionary = Bridge._seal_flagline_results(gs, journey)
			check(str(sealed_f.get("result_kind", "")) == "REAL_PLAYER", "seal_real:" + mode_id)
			var val_f: Dictionary = Ownership.validate_real_player_trace(sealed_f)
			check(bool(val_f.get("ok", false)), "val:" + mode_id)
			check(not bool(sealed_f.get("ownership_trace", {}).get("invented_hardware", true)), "no_hw:" + mode_id)
			continue

		Bridge.notify_live_hit(11.0, 1)
		snap = gs.trial_sim_snapshot
		check(bool(snap.get("player_owned_events", false)), "owned:" + mode_id)
		check(int((snap.get("ownership_trace", {}).get("events", []) as Array).size()) >= 1, "events:" + mode_id)
		## Resonance seal_real_player requires results phase (digital fixture, not device play).
		if mode_id == "resonance_trial":
			snap["phase"] = "results"
			snap["score"] = 110
			gs.trial_sim_snapshot = snap
		var sealed: Dictionary = Bridge.seal_live_owned_result(mode_id)
		check(str(sealed.get("result_kind", "")) == "REAL_PLAYER", "seal_real:" + mode_id)
		var val: Dictionary = Ownership.validate_real_player_trace(sealed)
		check(bool(val.get("ok", false)), "val:" + mode_id)
		for vf in val.get("failures", []):
			check(false, mode_id + "_val:" + str(vf))
		check(not bool(sealed.get("physical_device", false)), "seal_no_physical:" + mode_id)
		check(not bool(sealed.get("device_matrix_pass", false)), "seal_no_matrix:" + mode_id)
		check(not bool(sealed.get("SHIPPING_ROLLBACK_ENABLED", false)), "seal_no_rollback:" + mode_id)
		gs.clear_trial_modifiers()

	var summary: Dictionary = Ownership.journey_trace_summary(gs)
	check(bool(summary.get("ok", false)), "summary_ok")
	check(int(summary.get("ledger_real_player", 0)) >= 1, "ledger_has_real")
	check(bool(summary.get("digital_only", false)), "summary_digital")

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "AA-RTM-004 six-mode digital ownership — no physical device / HUMAN_ART territory claim",
		"digital_only": true,
		"physical_device": false,
		"invented_hardware": false,
		"device_matrix_pass": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"req_id": "AA-RTM-004",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("TRIALS_SIX_MODE_OWNERSHIP_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("TRIALS_SIX_MODE_OWNERSHIP_HONESTY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
