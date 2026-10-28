extends RefCounted
## Rosamere three-form selection / presentation hooks for training, versus, story.
## UI/story show THREE manifestations. COMPETITIVE_SELF_LIMITED is the gameplay
## contract on Familiar Rose — never a fourth story form.
## Art/balance/cinematics/V1 remain not approved.

const FORM_DOC_PATH := "res://data/forms/rosamere.json"
const FORM_FAMILIAR := "FAMILIAR_ROSE"
const FORM_FIRST_BLOOM := "FIRST_BLOOM"
const FORM_EVERLASTING := "EVERLASTING_ORIGIN"
const CONTRACT_COMPETITIVE := "COMPETITIVE_SELF_LIMITED"

const MANIFESTATIONS := [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]


static func load_doc() -> Dictionary:
	if not FileAccess.file_exists(FORM_DOC_PATH):
		return {}
	var f := FileAccess.open(FORM_DOC_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func story_manifestations(doc: Dictionary = {}) -> Array:
	if doc.is_empty():
		doc = load_doc()
	var ui: Array = doc.get("ui_manifestations", MANIFESTATIONS)
	return ui.duplicate()


static func is_story_form(form_id: String) -> bool:
	return form_id in MANIFESTATIONS


static func is_gameplay_contract(id: String) -> bool:
	return id == CONTRACT_COMPETITIVE


static func normalize_selection(raw_id: String) -> Dictionary:
	## Maps technical IDs so COMPETITIVE_SELF_LIMITED selects Familiar Rose + contract.
	var id := raw_id.strip_edges()
	if id.is_empty() or id == CONTRACT_COMPETITIVE:
		return {
			"ok": true,
			"form_id": FORM_FAMILIAR,
			"gameplay_contract_id": CONTRACT_COMPETITIVE,
			"story_form": true,
			"fourth_form": false,
		}
	if id in MANIFESTATIONS:
		var entry: Dictionary = load_doc().get("forms", {}).get(id, {})
		return {
			"ok": true,
			"form_id": id,
			"gameplay_contract_id": str(entry.get("gameplay_contract_id", CONTRACT_COMPETITIVE if id == FORM_FAMILIAR else "")),
			"story_form": true,
			"fourth_form": false,
		}
	return {"ok": false, "reason": "unknown_form_or_contract", "form_id": id}


static func permitted_in_mode(form_id: String, mode: String, mythic_consent: bool = false) -> Dictionary:
	var norm: Dictionary = normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return norm
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	var doc := load_doc()
	var entry: Dictionary = doc.get("forms", {}).get(resolved, {})
	if entry.is_empty():
		return {"ok": false, "reason": "missing_form_entry"}
	var mode_key := mode.strip_edges().to_lower()
	if mode_key == "ranked":
		mode_key = "versus"
	var forbid: Array = entry.get("forbid_modes", [])
	if mode_key in forbid or (mode == "ranked" and resolved == FORM_EVERLASTING):
		return {"ok": false, "reason": "forbidden_in_mode", "form_id": resolved, "mode": mode}
	var permitted: Array = entry.get("permitted_modes", [])
	if not permitted.is_empty() and mode_key not in permitted and mode not in permitted:
		return {"ok": false, "reason": "not_permitted_in_mode", "form_id": resolved, "mode": mode}
	if resolved == FORM_EVERLASTING and not mythic_consent and mode_key in ["mythic_party"]:
		return {"ok": false, "reason": "everlasting_requires_mythic_consent"}
	if resolved == FORM_EVERLASTING and mode_key in ["versus", "ranked"]:
		return {"ok": false, "reason": "everlasting_never_invincible_ranked"}
	return {
		"ok": true,
		"form_id": resolved,
		"gameplay_contract_id": str(norm.get("gameplay_contract_id", "")),
		"presentation": entry.get("presentation", {}),
		"transition_ready": true,
		"mode": mode,
	}


static func select_for_mode(form_id: String, mode: String, mythic_consent: bool = false) -> Dictionary:
	return permitted_in_mode(form_id, mode, mythic_consent)


static func apply_to_fighter(fighter: Node, form_id: String, mode: String, mythic_consent: bool = false) -> Dictionary:
	var gate: Dictionary = select_for_mode(form_id, mode, mythic_consent)
	if not bool(gate.get("ok", false)):
		return gate
	var resolved := str(gate.get("form_id", FORM_FAMILIAR))
	if fighter == null or not is_instance_valid(fighter):
		return {"ok": false, "reason": "invalid_fighter"}
	if fighter.has_method("apply_form"):
		fighter.apply_form(resolved)
	if fighter.has_method("set_meta"):
		fighter.set_meta("rosamere_gameplay_contract", str(gate.get("gameplay_contract_id", "")))
		fighter.set_meta("rosamere_presentation", gate.get("presentation", {}))
		fighter.set_meta("rosamere_mode", mode)
	return gate


static func presentation_contract(form_id: String) -> Dictionary:
	var norm: Dictionary = normalize_selection(form_id)
	if not bool(norm.get("ok", false)):
		return {}
	var entry: Dictionary = load_doc().get("forms", {}).get(str(norm.get("form_id", "")), {})
	return entry.get("presentation", {}).duplicate(true)


static func transition_hook(from_id: String, to_id: String) -> Dictionary:
	var doc := load_doc()
	var key := "%s->%s" % [from_id, to_id]
	var hooks: Dictionary = doc.get("transition_hooks", {})
	if hooks.has(key):
		return hooks[key].duplicate(true)
	return {}


static func validate_three_form_canon() -> Dictionary:
	var doc := load_doc()
	var ui: Array = story_manifestations(doc)
	var ladder: Array = doc.get("form_ladder", [])
	var contracts: Dictionary = doc.get("gameplay_contracts", {})
	var failures: Array = []
	if ui.size() != 3:
		failures.append("ui_manifestations_not_three")
	if FORM_FAMILIAR not in ui or FORM_FIRST_BLOOM not in ui or FORM_EVERLASTING not in ui:
		failures.append("missing_manifestation_id")
	if CONTRACT_COMPETITIVE in ui:
		failures.append("competitive_contract_listed_as_ui_form")
	if FORM_EVERLASTING in ladder:
		failures.append("everlasting_on_competitive_ladder")
	if not contracts.has(CONTRACT_COMPETITIVE):
		failures.append("missing_competitive_contract")
	elif str(contracts[CONTRACT_COMPETITIVE].get("attaches_to_form", "")) != FORM_FAMILIAR:
		failures.append("competitive_contract_not_on_familiar_rose")
	var familiar: Dictionary = doc.get("forms", {}).get(FORM_FAMILIAR, {})
	if str(familiar.get("gameplay_contract_id", "")) != CONTRACT_COMPETITIVE:
		failures.append("familiar_missing_competitive_contract_id")
	if bool(doc.get("art_status", {}).get("HUMAN_ART_APPROVED", true)):
		failures.append("human_art_gate_must_stay_false")
	if str(doc.get("tuning_status", "")) != "BALANCE_NOT_APPROVED":
		failures.append("balance_must_remain_not_approved")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"manifestations": ui,
		"competitive_ladder": ladder,
		"name": str(doc.get("display_name", "")),
		"title": str(doc.get("title", "")),
	}
