extends RefCounted
class_name CursorCompleteHonesty
## AA-RTM-011 digital honesty — CURSOR_COMPLETE remains false while owner/device/
## HUMAN_ART / shipping-rollback / RC2 / V1 gates stay open. Does not claim ship.

static func open_cursor_rtm_blockers() -> Array:
	return [
		{"req_id": "AA-RTM-002", "blocker": "owner_story_playthrough_sign_off"},
		{"req_id": "AA-RTM-004", "blocker": "device_playtest_and_HUMAN_ART_territory_meshes"},
		{"req_id": "AA-RTM-006", "blocker": "HUMAN_ART_hitbox_and_roster_frame_audit"},
		{"req_id": "AA-RTM-007", "blocker": "shipping_rollback_disabled_by_design"},
		{"req_id": "AA-RTM-009", "blocker": "owner_a11y_device_matrix_WCAG"},
		{"req_id": "AA-RTM-011", "blocker": "aggregate_gate_unmet"},
	]


static func presentation_honesty_card() -> Dictionary:
	return {
		"req_id": "AA-RTM-011",
		"CURSOR_COMPLETE": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"device_matrix_pass": false,
		"owner_playable_review": false,
		"open_blockers": open_cursor_rtm_blockers(),
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}


static func validate() -> Dictionary:
	var card: Dictionary = presentation_honesty_card()
	var failures: Array = []
	if bool(card.get("CURSOR_COMPLETE", true)):
		failures.append("cursor_complete_must_stay_false")
	if bool(card.get("RC2_READY", true)):
		failures.append("rc2_must_stay_false")
	if bool(card.get("V1_0_0_RELEASE_AUTHORIZED", true)):
		failures.append("v1_must_stay_false")
	if bool(card.get("HUMAN_ART_APPROVED", true)):
		failures.append("human_art_must_stay_false")
	if bool(card.get("SHIPPING_ROLLBACK_ENABLED", true)):
		failures.append("shipping_rollback_must_stay_false")
	if bool(card.get("device_matrix_pass", true)):
		failures.append("device_matrix_must_stay_false")
	if (card.get("open_blockers", []) as Array).is_empty():
		failures.append("blockers_must_be_declared")
	## Cross-check sibling honesty modules when present.
	var Rollback = load("res://scripts/rc/shipping_rollback_honesty.gd")
	if Rollback != null:
		var rb: Dictionary = Rollback.validate()
		if bool(rb.get("SHIPPING_ROLLBACK_ENABLED", true)):
			failures.append("rollback_module_enabled")
	var Hitbox = load("res://scripts/rc/hitbox_integrity_honesty.gd")
	if Hitbox != null:
		var hb: Dictionary = Hitbox.presentation_honesty_card()
		if bool(hb.get("HUMAN_ART_APPROVED", true)):
			failures.append("hitbox_human_art_claimed")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"card": card,
		"CURSOR_COMPLETE": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"device_matrix_pass": false,
		"req_id": "AA-RTM-011",
	}
