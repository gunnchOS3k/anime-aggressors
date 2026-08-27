extends SceneTree

## Wave022 UI feel — all 7 fighters must expose FORM / TRANSFORMATION section in Move List catalog.

const Catalog = preload("res://scripts/ui/move_list_catalog.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave022/UI_FEEL_RESULT.json",
	"../artifacts/engineering_wave022/UI_FEEL_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	var per_fighter: Dictionary = {}

	for fid in Catalog.roster_ids():
		var cat := Catalog.build_fighter_catalog(fid)
		var has_form := false
		var form_count := 0
		for e in cat.get("entries", []):
			if str(e.get("category", "")) == "FORM / TRANSFORMATION":
				has_form = true
				form_count += 1
		if not has_form or form_count < 3:
			failures += 1
		per_fighter[fid] = {
			"form_section_present": has_form,
			"form_entry_count": form_count,
		}

	var ok := failures == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_026_PRESERVED": "PASS" if ok else "FAIL",
		"UI_FEEL_FAILURES": failures,
		"per_fighter": per_fighter,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("WAVE022_UI_FEEL ok=", ok)
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
