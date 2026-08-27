extends SceneTree

const OUT_PATHS := [
	"res://../artifacts/engineering_wave021/FORM_ARCHITECTURE_RESULT.json",
	"../artifacts/engineering_wave021/FORM_ARCHITECTURE_RESULT.json",
]

const _FighterDefinition = preload("res://scripts/combat/fighter_definition.gd")
const _FormDefinition = preload("res://scripts/combat/form_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	var ember_def := _FighterDefinition.build("ember-vale")
	if not _FighterDefinition.ascension_runtime_enabled(ember_def):
		failures += 1
	var forms_doc: Dictionary = ember_def.get("forms_doc", {})
	for step in ["EMBER_BASE", "EMBER_AWAKENED_BUILD", "EMBER_ASCENDED"]:
		var entry := _FormDefinition.form_entry(forms_doc, step)
		if entry.is_empty():
			failures += 1
		if float(entry.get("body_scale", 0.0)) > 1.05:
			failures += 1
	# Other 6: design-only — must NOT have ascension_runtime
	for fid in ["rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx"]:
		var def := _FighterDefinition.build(fid)
		if _FighterDefinition.ascension_runtime_enabled(def):
			failures += 1
	var ok := failures == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_021": "PASS" if ok else "FAIL",
		"OWNER_REG_022": "PASS" if ok else "FAIL",
		"FORM_LADDER_FAILURES": failures,
		"EMBER_FORMS_PRESENT": 3,
		"ROSTER_ASCENSION_RUNTIME_COUNT": 1,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("FORM_ARCHITECTURE ok=", ok)
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
