extends SceneTree
## PartyLink six-mode seats + ten-fighter roster presentation + native-build prep honesty.
## Digital only — ≠ HUMAN_ART / device / export-green claim. Codex untouched.

const Honesty = preload("res://scripts/rc/partylink_roster_native_honesty.gd")
const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")

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
	check(not bool(report.get("HUMAN_ART_APPROVED", true)), "art_false")
	check(not bool(report.get("device_matrix_pass", true)), "no_device")
	check(not bool(report.get("CURSOR_COMPLETE", true)), "cursor_complete_false")
	check(not bool(report.get("invented_seats", true)), "no_invented")
	check(bool(report.get("HitResolver_untouched", false)), "hr_untouched")

	var pl: Dictionary = report.get("partylink", {})
	check(int(pl.get("mode_count", 0)) == 6, "six_modes")
	check(int(pl.get("battle_scene_fighter_slots", 0)) == 2, "battle_slots_2")

	var roster: Dictionary = report.get("roster", {})
	check(int(roster.get("count", 0)) == 10, "ten_fighters")
	check(bool(roster.get("presentation_completeness_digital", false)), "roster_digital_complete")
	check(not bool(roster.get("owner_frame_audit", true)), "no_frame_audit_claim")

	var native: Dictionary = report.get("native", {})
	check(not bool(native.get("native_export_claimed_green", true)), "no_export_green")
	var checklist: Dictionary = native.get("checklist", {})
	check(str(checklist.get("primary_feel_target", "")) == "godot_native_desktop_editor", "editor_primary")
	check(not bool(checklist.get("console_platforms_supported", true)), "no_console")

	var matrix: Dictionary = Seats.six_mode_honesty_matrix()
	check(bool(matrix.get("ok", false)), "matrix_direct_ok")
	for row in matrix.get("rows", []):
		check(int(row.get("seated", 99)) <= int(row.get("live_max", 0)), "row_clamp:" + str(row.get("mode_id", "")))

	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "PartyLink seats + ten-fighter roster presentation + native-build prep honesty — digital",
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"native_export_claimed_green": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"invented_seats": false,
		"req_ids": ["AA-RTM-001", "AA-RTM-008", "AA-RTM-010"],
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("PARTYLINK_ROSTER_NATIVE_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("PARTYLINK_ROSTER_NATIVE_HONESTY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
