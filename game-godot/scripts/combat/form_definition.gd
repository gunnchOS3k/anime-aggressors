extends RefCounted
class_name FormDefinition

## Data-driven form ladder: BASE → AWAKENED_BUILD → ASCENDED.

const FORM_BASE := "BASE"
const FORM_AWAKENED_BUILD := "AWAKENED_BUILD"
const FORM_ASCENDED := "ASCENDED"

const LADDER := [FORM_BASE, FORM_AWAKENED_BUILD, FORM_ASCENDED]


static func load_forms(fighter_id: String) -> Dictionary:
	var path := "res://data/forms/%s.json" % fighter_id
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func default_form_id(forms_doc: Dictionary) -> String:
	return str(forms_doc.get("default_form", ""))


static func form_entry(forms_doc: Dictionary, form_id: String) -> Dictionary:
	var forms: Dictionary = forms_doc.get("forms", {})
	if forms.has(form_id):
		return forms[form_id]
	return {}


static func next_form_id(forms_doc: Dictionary, current: String) -> String:
	var ladder: Array = forms_doc.get("form_ladder", LADDER)
	var idx := ladder.find(current)
	if idx < 0 or idx >= ladder.size() - 1:
		return current
	return str(ladder[idx + 1])


static func body_scale(form: Dictionary) -> float:
	return float(form.get("body_scale", 1.0))


static func move_overrides(form: Dictionary) -> Dictionary:
	return form.get("move_overrides", {})


static func apply_move_override(base_move: Dictionary, form: Dictionary, move_id: String) -> Dictionary:
	var overrides: Dictionary = move_overrides(form)
	if not overrides.has(move_id):
		return base_move
	var patch: Dictionary = overrides[move_id]
	var out := base_move.duplicate(true)
	for k in patch:
		out[k] = patch[k]
	out["form_override_applied"] = true
	out["form_id"] = str(form.get("form_id", ""))
	return out
