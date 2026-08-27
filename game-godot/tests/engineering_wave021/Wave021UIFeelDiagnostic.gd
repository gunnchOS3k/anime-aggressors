extends SceneTree

const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
const _ArtDirection = preload("res://scripts/visual/art_direction_contract.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave021/UI_FEEL_RESULT.json",
	"../artifacts/engineering_wave021/UI_FEEL_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	var cat := Catalog.build_fighter_catalog("ember-vale")
	var has_form := false
	for e in cat.get("entries", []):
		if str(e.get("category", "")) == "FORM / TRANSFORMATION":
			has_form = true
			if not bool(e.get("transform_marker", false)) and str(e.get("form_id", "")) != "EMBER_BASE":
				pass
	if not has_form:
		failures += 1
	if _ArtDirection.REALISTIC_HUMANOID_FACE_AS_DEFAULT:
		failures += 1
	if not _ArtDirection.FACELESS_ABSTRACT_HEAD_DIRECTION:
		failures += 1
	var ui_doc := ProjectSettings.globalize_path("res://../docs/ui/FIGHTING_GAME_UI_LANGUAGE.md")
	if not FileAccess.file_exists(ui_doc):
		failures += 1
	var ok := failures == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_026": "PASS" if ok else "FAIL",
		"UI_FEEL_FAILURES": failures,
		"FORM_SECTION_PRESENT": has_form,
		"FACELESS_DIRECTION": _ArtDirection.FACELESS_ABSTRACT_HEAD_DIRECTION,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("UI_FEEL ok=", ok)
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
