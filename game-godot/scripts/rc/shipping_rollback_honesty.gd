extends RefCounted
class_name ShippingRollbackHonesty
## AA-RTM-007 digital honesty — shipping rollback remains disabled.
## Seeded Trials sims / resim evidence ≠ commercial rollback ship.
## Does not enable netcode. HitResolver ownership untouched.

static func project_flag() -> bool:
	if ProjectSettings.has_setting("anime_aggressors/SHIPPING_ROLLBACK_ENABLED"):
		return bool(ProjectSettings.get_setting("anime_aggressors/SHIPPING_ROLLBACK_ENABLED"))
	return false


static func gamestate_flag(gs: Node = null) -> bool:
	if gs == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			gs = tree.root.get_node_or_null("GameState")
	if gs == null:
		return false
	if gs.get("SHIPPING_ROLLBACK_ENABLED") != null:
		return bool(gs.SHIPPING_ROLLBACK_ENABLED)
	return false


static func trials_seal_never_enables_rollback(sealed: Dictionary) -> bool:
	return not bool(sealed.get("SHIPPING_ROLLBACK_ENABLED", false))


static func validate() -> Dictionary:
	var failures: Array = []
	if project_flag():
		failures.append("project_shipping_rollback_must_stay_false")
	var gs_flag := gamestate_flag()
	if gs_flag:
		failures.append("gamestate_shipping_rollback_must_stay_false")
	## PartyLink / Trials presentation cards must stay false.
	var Seats = load("res://scripts/trials/partylink_seat_enforcement.gd")
	if Seats != null:
		var card: Dictionary = Seats.presentation_honesty_card("prism_weave", 4, -1)
		if bool(card.get("SHIPPING_ROLLBACK_ENABLED", true)):
			failures.append("partylink_card_rollback_true")
	var A11y = load("res://scripts/ui/accessibility_surface.gd")
	if A11y != null:
		var c: Dictionary = A11y.trials_journey_a11y_contract("resonance_trial")
		if bool(c.get("SHIPPING_ROLLBACK_ENABLED", true)):
			failures.append("a11y_contract_rollback_true")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"resim_evidence_is_not_commercial_rollback": true,
		"HitResolver_untouched": true,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"req_id": "AA-RTM-007",
	}
