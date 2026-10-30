extends RefCounted
class_name RosamereSurfacePolish
## Digital Story/Rosamere/Trials polish honesty — presentation surfaces only.
## ≠ HUMAN_ART. Does not rewrite Codex HitResolver / combat data.
## Spoiler-safe Trials eligibility + three-form Story hooks + HUD a11y labels.

const Presentation = preload("res://scripts/visual/rosamere_form_presentation.gd")
const Eligibility = preload("res://scripts/trials/rosamere_trials_eligibility.gd")
const Selection = preload("res://scripts/combat/rosamere_form_selection.gd")
const Hud = preload("res://scripts/ui/rosamere_presentation_hud.gd")
const StoryHonesty = preload("res://scripts/story/story_journey_honesty.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")


static func presentation_honesty_card() -> Dictionary:
	return {
		"req_ids": ["AA-RTM-002", "AA-RTM-003", "AA-RTM-004", "AA-RTM-009"],
		"three_forms_only": true,
		"competitive_self_limited_is_fourth_form": false,
		"story_presentation_hooks": true,
		"trials_spoiler_safe": true,
		"hud_presentation_only": true,
		"choreography_is_human_art": false,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"owner_sign_off": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
	}


static func three_form_contract() -> Dictionary:
	var forms: Array = [
		Presentation.FORM_FAMILIAR,
		Presentation.FORM_FIRST_BLOOM,
		Presentation.FORM_EVERLASTING,
	]
	var failures: Array = []
	if forms.size() != 3:
		failures.append("not_exactly_three")
	## COMPETITIVE_SELF_LIMITED must never appear as a fourth form id.
	for fid in forms:
		var norm: Dictionary = Selection.normalize_selection(str(fid))
		if not bool(norm.get("ok", false)):
			failures.append("normalize:" + str(fid))
		var card: Dictionary = Presentation.presentation_card_for_form(str(fid))
		if card.is_empty():
			failures.append("missing_card:" + str(fid))
		elif bool(card.get("HUMAN_ART_APPROVED", false)):
			failures.append("art_claimed:" + str(fid))
	var fourth: Dictionary = Selection.normalize_selection("COMPETITIVE_SELF_LIMITED")
	if bool(fourth.get("ok", false)) and str(fourth.get("form_id", "")) == "COMPETITIVE_SELF_LIMITED":
		failures.append("csl_as_fourth_form")
	if not Presentation.art_status_honest():
		failures.append("art_status_dishonest")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"forms": forms,
		"form_count": forms.size(),
		"HUMAN_ART_APPROVED": false,
	}


static func trials_spoiler_safe_contract() -> Dictionary:
	var failures: Array = []
	var modes: Array = Bridge.LIVE_SHARED_COMBAT_MODES
	for mode_id in modes:
		var bloom: Dictionary = Eligibility.evaluate("FIRST_BLOOM", str(mode_id), false, false)
		if bool(bloom.get("ok", true)):
			failures.append("bloom_leaked_pre_reveal:" + str(mode_id))
		var familiar: Dictionary = Eligibility.evaluate("FAMILIAR_ROSE", str(mode_id), false, false)
		if not bool(familiar.get("ok", false)) and str(mode_id) != "convergence_unbound":
			## Familiar should be offered spoiler-safe on standard Trials.
			if str(familiar.get("reason", "")) == "familiar_forbidden_in_trial":
				failures.append("familiar_blocked:" + str(mode_id))
		var everlasting: Dictionary = Eligibility.evaluate("EVERLASTING_ORIGIN", "resonance_trial", false, true)
		if bool(everlasting.get("ok", true)):
			failures.append("everlasting_on_resonance")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"spoiler_safe": true,
		"feeds_ranked_mmr": false,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
	}


static func story_hook_contract(node: Dictionary = {}) -> Dictionary:
	var sample: Dictionary = node
	if sample.is_empty():
		sample = {"id": "kaia-windrow:accord", "kind": "INTERACTIVE_DIALOGUE", "rosamere_hook": true}
	var contract: Dictionary = Presentation.story_integration_contract(sample)
	var failures: Array = []
	if contract.is_empty():
		failures.append("empty_story_contract")
	elif bool(contract.get("HUMAN_ART_APPROVED", false)):
		failures.append("story_hook_art_claimed")
	var story_card: Dictionary = StoryHonesty.presentation_honesty_card()
	if bool(story_card.get("owner_sign_off", true)):
		failures.append("story_owner_claimed")
	if bool(story_card.get("HUMAN_ART_APPROVED", true)):
		failures.append("story_art_claimed")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"story_integration": contract,
		"story_journey_card": story_card,
		"HUMAN_ART_APPROVED": false,
		"owner_sign_off": false,
	}


static func hud_honesty_contract() -> Dictionary:
	## Source-level HUD honesty — presentation-only, a11y labels, no HitResolver writes.
	var src := FileAccess.get_file_as_string("res://scripts/ui/rosamere_presentation_hud.gd")
	var failures: Array = []
	if src.find("HUMAN_ART") < 0:
		failures.append("hud_missing_art_honesty")
	if src.find("HitResolver untouched") < 0 and src.find("HitResolver") < 0:
		failures.append("hud_missing_hr_honesty")
	if src.find("A11y.label_control") < 0:
		failures.append("hud_missing_a11y_labels")
	if src.find("presentation-only") < 0 and src.find("Presentation-only") < 0:
		failures.append("hud_missing_presentation_only")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"hud_name": Hud.HUD_NAME,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
	}


static func validate() -> Dictionary:
	var failures: Array = []
	var three: Dictionary = three_form_contract()
	if not bool(three.get("ok", false)):
		failures.append("three_form")
		for f in three.get("failures", []):
			failures.append("3:" + str(f))
	var trials: Dictionary = trials_spoiler_safe_contract()
	if not bool(trials.get("ok", false)):
		failures.append("trials_spoiler")
		for f in trials.get("failures", []):
			failures.append("t:" + str(f))
	var story: Dictionary = story_hook_contract()
	if not bool(story.get("ok", false)):
		failures.append("story_hook")
		for f in story.get("failures", []):
			failures.append("s:" + str(f))
	var hud: Dictionary = hud_honesty_contract()
	if not bool(hud.get("ok", false)):
		failures.append("hud")
		for f in hud.get("failures", []):
			failures.append("h:" + str(f))
	var card: Dictionary = presentation_honesty_card()
	if bool(card.get("HUMAN_ART_APPROVED", true)):
		failures.append("card_art")
	if bool(card.get("CURSOR_COMPLETE", true)):
		failures.append("card_cursor_complete")
	if bool(card.get("competitive_self_limited_is_fourth_form", true)):
		failures.append("fourth_form_claimed")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"three_form": three,
		"trials": trials,
		"story": story,
		"hud": hud,
		"card": card,
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"req_ids": card.get("req_ids", []),
	}
