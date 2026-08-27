extends RefCounted
class_name FighterDefinition

## Wave021 fighter definition wrapper — merges roster JSON + form ladder.

const _FormDefinition = preload("res://scripts/combat/form_definition.gd")
const _ArtDirection = preload("res://scripts/visual/art_direction_contract.gd")


static func build(fighter_id: String, fighter_data: Dictionary = {}) -> Dictionary:
	var data := fighter_data
	if data.is_empty():
		data = _load_fighter_json(fighter_id)
	var forms_doc := _FormDefinition.load_forms(fighter_id)
	var default_form := _FormDefinition.default_form_id(forms_doc)
	if default_form.is_empty() and forms_doc.has("forms"):
		var keys: Array = forms_doc.forms.keys()
		if not keys.is_empty():
			default_form = str(keys[0])
	return {
		"fighter_id": fighter_id,
		"fighter_data": data,
		"forms_doc": forms_doc,
		"default_form_id": default_form,
		"form_ladder": forms_doc.get("form_ladder", _FormDefinition.LADDER),
		"transform_rules": forms_doc.get("transform_rules", {}),
		"ascension_enabled": forms_doc.get("ascension_runtime", false),
		"art_direction": _ArtDirection.roster_art_flags(),
	}


static func ascension_runtime_enabled(def: Dictionary) -> bool:
	return bool(def.get("ascension_enabled", false))


static func _load_fighter_json(fighter_id: String) -> Dictionary:
	var path := "res://data/fighters/%s.json" % fighter_id
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())
