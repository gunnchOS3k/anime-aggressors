extends RefCounted
class_name RosamereTrialsEligibility
## Spoiler-safe Rosamere form gates across Trials modes.
## Everlasting Origin only Story + opted-in Mythic / Convergence Unbound.
## COMPETITIVE_SELF_LIMITED is a contract on Familiar Rose — never a fourth form.

const Selection = preload("res://scripts/combat/rosamere_form_selection.gd")
const Authority = preload("res://scripts/trials/mode_authority.gd")

const FORM_FAMILIAR := "FAMILIAR_ROSE"
const FORM_FIRST_BLOOM := "FIRST_BLOOM"
const FORM_EVERLASTING := "EVERLASTING_ORIGIN"


static func trial_mode_key(mode_id: String) -> String:
	## Map trial ids onto selection permitted_modes keys.
	match mode_id:
		"convergence_unbound":
			return "mythic_party"
		"resonance_trial", "fractured_accord", "prism_weave", "riftline_defense", "echoes_gauntlet":
			return "trials"
		_:
			return mode_id


static func evaluate(form_id: String, mode_id: String, mythic_consent: bool = false, story_reveal: bool = false) -> Dictionary:
	var norm: Dictionary = Selection.normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return norm
	var resolved: String = str(norm.get("form_id", FORM_FAMILIAR))
	var entry: Dictionary = Authority.mode_entry(mode_id)
	var rosa: Dictionary = entry.get("rosamere", {})

	## Spoiler-safe: without story reveal, only Familiar Rose is offered in Trials UI.
	if not story_reveal and resolved != FORM_FAMILIAR:
		return {
			"ok": false,
			"reason": "spoiler_safe_pre_reveal",
			"form_id": resolved,
			"offered_form": FORM_FAMILIAR,
		}

	if resolved == FORM_EVERLASTING:
		var everlasting_rule: Variant = rosa.get("everlasting", false)
		## Catalog may store bool false or string "mythic_consent_required".
		if typeof(everlasting_rule) == TYPE_BOOL and everlasting_rule == false:
			return {"ok": false, "reason": "everlasting_forbidden_in_trial", "form_id": resolved, "mode": mode_id}
		if typeof(everlasting_rule) == TYPE_STRING and str(everlasting_rule) == "mythic_consent_required" and not mythic_consent:
			return {"ok": false, "reason": "everlasting_requires_mythic_consent", "form_id": resolved, "mode": mode_id}
		if typeof(everlasting_rule) == TYPE_STRING and str(everlasting_rule) == "false":
			return {"ok": false, "reason": "everlasting_forbidden_in_trial", "form_id": resolved, "mode": mode_id}
		## Never invincible ranked — Trials never feed ranked, but still block versus/ranked keys.
		var gate: Dictionary = Selection.permitted_in_mode(resolved, trial_mode_key(mode_id), mythic_consent)
		if not bool(gate.get("ok", false)) and mode_id != "convergence_unbound":
			return gate
		return {
			"ok": true,
			"form_id": resolved,
			"gameplay_contract_id": "STORY_MYTHIC_UNLIMITED",
			"mode": mode_id,
			"feeds_ranked_mmr": false,
			"avatar_ko_is_true_defeat": false,
			"note": "KO of Everlasting Origin avatar in Unbound ≠ true Rosamere defeat",
		}

	if resolved == FORM_FIRST_BLOOM and not bool(rosa.get("first_bloom", true)):
		return {"ok": false, "reason": "first_bloom_forbidden_in_trial", "form_id": resolved}

	if resolved == FORM_FAMILIAR and not bool(rosa.get("familiar", true)):
		return {"ok": false, "reason": "familiar_forbidden_in_trial", "form_id": resolved}

	return {
		"ok": true,
		"form_id": resolved,
		"gameplay_contract_id": str(norm.get("gameplay_contract_id", "COMPETITIVE_SELF_LIMITED")),
		"mode": mode_id,
		"feeds_ranked_mmr": false,
		"spoiler_safe": not story_reveal,
	}


static func offered_forms(mode_id: String, mythic_consent: bool = false, story_reveal: bool = false) -> Array:
	var out: Array = []
	for fid in [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]:
		var gate: Dictionary = evaluate(fid, mode_id, mythic_consent, story_reveal)
		if bool(gate.get("ok", false)):
			out.append(fid)
	if out.is_empty():
		out.append(FORM_FAMILIAR)
	return out
