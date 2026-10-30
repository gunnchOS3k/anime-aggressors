extends SceneTree
## AA-RTM-007 — shipping rollback stays false; resim ≠ commercial ship.

const Honesty = preload("res://scripts/rc/shipping_rollback_honesty.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")

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
	var report: Dictionary = Honesty.validate()
	check(bool(report.get("ok", false)), "validate_ok")
	for f in report.get("failures", []):
		check(false, "fail:" + str(f))
	check(not bool(report.get("SHIPPING_ROLLBACK_ENABLED", true)), "flag_false")
	check(bool(report.get("resim_evidence_is_not_commercial_rollback", false)), "resim_not_ship")
	check(bool(report.get("HitResolver_untouched", false)), "hr_untouched")

	## Live Trials seal honesty.
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs != null:
		var prep: Dictionary = Bridge.prepare_live_battle("resonance_trial", 1)
		check(bool(prep.get("ok", false)), "prep")
		Bridge.notify_live_hit(8.0, 1)
		var snap: Dictionary = gs.trial_sim_snapshot
		snap["phase"] = "results"
		snap["player_owned_events"] = true
		snap["score"] = 80
		gs.trial_sim_snapshot = snap
		var sealed: Dictionary = Bridge.seal_live_resonance_result()
		check(Honesty.trials_seal_never_enables_rollback(sealed), "seal_no_rollback")
		## Missing key must not invent a true rollback claim — treat absent as false.
		check(not bool(sealed.get("SHIPPING_ROLLBACK_ENABLED", false)), "sealed_flag_false")
		check(sealed.has("SHIPPING_ROLLBACK_ENABLED"), "sealed_declares_rollback_flag")

	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "AA-RTM-007 shipping rollback honesty — resim ≠ commercial rollback",
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"req_id": "AA-RTM-007",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("SHIPPING_ROLLBACK_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("SHIPPING_ROLLBACK_HONESTY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
