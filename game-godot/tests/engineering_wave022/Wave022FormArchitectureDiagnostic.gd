extends SceneTree

## Wave022 form architecture — all 7 fighters must have ascension_runtime + 3-form ladder.

const OUT_PATHS := [
	"res://../artifacts/engineering_wave022/FORM_ARCHITECTURE_RESULT.json",
	"../artifacts/engineering_wave022/FORM_ARCHITECTURE_RESULT.json",
]

const ROSTER := [
	"ember-vale",
	"rook-ironside",
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
]

const _FighterDefinition = preload("res://scripts/combat/fighter_definition.gd")
const _FormDefinition = preload("res://scripts/combat/form_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	var ascension_count := 0
	var per_fighter: Dictionary = {}

	for fid in ROSTER:
		var def := _FighterDefinition.build(fid)
		var forms_doc: Dictionary = def.get("forms_doc", {})
		var fighter_failures := 0
		if not _FighterDefinition.ascension_runtime_enabled(def):
			fighter_failures += 1
		else:
			ascension_count += 1
		var ladder: Array = forms_doc.get("form_ladder", [])
		if ladder.size() != 3:
			fighter_failures += 1
		for form_key in ladder:
			var entry := _FormDefinition.form_entry(forms_doc, str(form_key))
			if entry.is_empty():
				fighter_failures += 1
			if float(entry.get("body_scale", 0.0)) > 1.05:
				fighter_failures += 1
			if str(entry.get("head_presentation", "")) != "faceless_abstract_cap":
				fighter_failures += 1
		var ascended_key: String = str(ladder[ladder.size() - 1]) if ladder.size() > 0 else ""
		var ascended := _FormDefinition.form_entry(forms_doc, ascended_key)
		var overrides: Dictionary = ascended.get("move_overrides", {})
		var required := ["jab_1", "forward_tilt", "neutral_special_projectile"]
		for req in required:
			if not overrides.has(req):
				fighter_failures += 1
		if not overrides.has("aura_burst") and not overrides.has("signature_lane_burst"):
			fighter_failures += 1
		per_fighter[fid] = {
			"ok": fighter_failures == 0,
			"failures": fighter_failures,
			"ascension_runtime": _FighterDefinition.ascension_runtime_enabled(def),
			"form_count": ladder.size(),
		}
		failures += fighter_failures

	var ok := failures == 0 and ascension_count == 7
	var payload := {
		"ok": ok,
		"OWNER_REG_027": "PASS" if ok else "FAIL",
		"OWNER_REG_028": "PASS" if ok else "FAIL",
		"FORM_LADDER_FAILURES": failures,
		"ROSTER_ASCENSION_RUNTIME_COUNT": ascension_count,
		"EXPECTED_ASCENSION_COUNT": 7,
		"per_fighter": per_fighter,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("WAVE022_FORM_ARCHITECTURE ok=", ok, " ascension_count=", ascension_count)
	quit(0 if ok else 1)


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in OUT_PATHS:
		var abs_path := ProjectSettings.globalize_path(p) if str(p).begins_with("res://") else str(p)
		if not abs_path.is_absolute_path():
			abs_path = ProjectSettings.globalize_path("res://../") + abs_path.trim_prefix("../")
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
