extends SceneTree
## AA-RTM-011 — CURSOR_COMPLETE stays false; open blockers declared. Not a ship claim.

const Honesty = preload("res://scripts/rc/cursor_complete_honesty.gd")

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
	check(not bool(report.get("CURSOR_COMPLETE", true)), "cursor_complete_false")
	check(not bool(report.get("RC2_READY", true)), "rc2_false")
	check(not bool(report.get("V1_0_0_RELEASE_AUTHORIZED", true)), "v1_false")
	check(not bool(report.get("HUMAN_ART_APPROVED", true)), "art_false")
	check(not bool(report.get("SHIPPING_ROLLBACK_ENABLED", true)), "rollback_false")
	check(not bool(report.get("device_matrix_pass", true)), "no_device_matrix")
	var blockers: Array = Honesty.open_cursor_rtm_blockers()
	check(blockers.size() >= 5, "blockers_declared")
	var card: Dictionary = Honesty.presentation_honesty_card()
	check(str(card.get("req_id", "")) == "AA-RTM-011", "card_req")
	check(bool(card.get("HitResolver_untouched", false)), "hr_untouched")

	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "AA-RTM-011 Cursor-Complete gate honesty — CURSOR_COMPLETE remains false",
		"CURSOR_COMPLETE": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"device_matrix_pass": false,
		"open_blockers": blockers,
		"req_id": "AA-RTM-011",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("CURSOR_COMPLETE_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("CURSOR_COMPLETE_HONESTY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
