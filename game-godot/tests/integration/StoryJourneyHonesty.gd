extends SceneTree
## AA-RTM-002 digital deepen — Story journey honesty across spectral catalog,
## interrupt save/recovery, and out-of-order dialogue rejection.
## Staged digital authority ≠ owner playthrough / device / V1 / HUMAN_ART.

const Honesty = preload("res://scripts/story/story_journey_honesty.gd")

var output := ""
var checks: Array = []
var failures: Array = []


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	checks.append({"check": label, "pass": value})
	if not value:
		failures.append(label)


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated Story profile required")
		quit(2)
		return

	var campaign = root.get_node("CampaignRuntime")
	campaign.save_path = "user://story_journey_honesty.json"
	check(campaign.reset_campaign(), "reset_campaign")
	check(str(campaign.progress.schema) == Honesty.SCHEMA, "schema_v2")

	var report: Dictionary = Honesty.validate(campaign)
	check(bool(report.get("ok", false)), "validate_ok")
	for f in report.get("failures", []):
		check(false, "val:" + str(f))
	check(not bool(report.get("owner_sign_off", true)), "no_owner_sign_off")
	check(not bool(report.get("human_playthrough", true)), "no_human_playthrough")
	check(not bool(report.get("device_matrix_pass", true)), "no_device_matrix")
	check(not bool(report.get("V1_0_0_RELEASE_AUTHORIZED", true)), "no_v1")
	check(bool(report.get("HitResolver_untouched", false)), "hr_untouched")

	var catalog: Dictionary = Honesty.route_catalog_summary(campaign)
	check(bool(catalog.get("ok", false)), "catalog_ok")
	check(int(catalog.get("route_count", 0)) >= 7, "seven_spectral_routes")
	for row in catalog.get("routes", []):
		check(bool(row.get("prologue_implemented", false)), "prologue:" + str(row.get("route_id")))
		check(int(row.get("story_battles", 0)) >= 1, "battles:" + str(row.get("route_id")))

	var route_id := "kaia-windrow"
	check(str(campaign.progress.selected_route) == route_id, "default_kaia")
	var interrupt: Dictionary = Honesty.interrupt_checkpoint_roundtrip(campaign, route_id, 2, 22.5)
	check(bool(interrupt.get("ok", false)), "interrupt_roundtrip")
	check(not bool(interrupt.get("owner_sign_off", true)), "interrupt_no_owner")
	check(bool(interrupt.get("active_encounter_cleared", false)), "interrupt_clears_encounter")

	var ooo: Dictionary = Honesty.out_of_order_dialogue_not_durable(campaign, route_id, "kaia-windrow:accord")
	check(bool(ooo.get("ok", false)), "ooo_not_durable")
	check(not bool(ooo.get("durable_after_reload", true)), "ooo_dropped")
	check(bool(ooo.get("earned_prefix_required", false)), "earned_prefix_required")

	var card: Dictionary = Honesty.presentation_honesty_card(route_id)
	check(str(card.get("req_id", "")) == "AA-RTM-002", "card_req")
	check(bool(card.get("save_recovery_authority", false)), "card_save_recovery")
	check(bool(card.get("earned_prefix_required_for_durable_dialogue", false)), "card_earned_prefix")
	check(not bool(card.get("CURSOR_COMPLETE", true)), "card_cursor_complete_false")
	check(not bool(card.get("HUMAN_ART_APPROVED", true)), "card_art_false")
	check(not bool(card.get("SHIPPING_ROLLBACK_ENABLED", true)), "card_rollback_false")

	## Restore clean Kaia journey after OOO fixture.
	check(campaign.reset_campaign(), "reset_clean")
	check(str(campaign.current_node().get("kind", "")) == "STORY_BATTLE", "opens_story_battle")

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "AA-RTM-002 Story journey honesty — spectral catalog + interrupt recovery + OOO dialogue; ≠ owner/device/V1",
		"owner_sign_off": false,
		"human_playthrough": false,
		"device_matrix_pass": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"req_id": "AA-RTM-002",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("STORY_JOURNEY_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("STORY_JOURNEY_HONESTY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
