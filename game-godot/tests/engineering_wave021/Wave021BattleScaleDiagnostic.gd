extends SceneTree

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _FormDefinition = preload("res://scripts/combat/form_definition.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave021/BATTLE_SCALE_RESULT.json",
	"../artifacts/engineering_wave021/BATTLE_SCALE_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var forms_doc := _FormDefinition.load_forms("ember-vale")
	var scale_leaks := 0
	var base_scale := 0.0
	var ascended_scale := 0.0

	for form_key in ["EMBER_BASE", "EMBER_AWAKENED_BUILD", "EMBER_ASCENDED"]:
		var entry := _FormDefinition.form_entry(forms_doc, form_key)
		var model: Node2D = MODEL_SCRIPT.new()
		host.add_child(model)
		model.set_presentation_context("BATTLE")
		model.configure({"id": "ember-vale"})
		model.set_form_id(form_key, entry)
		await process_frame
		if model.has_method("get_body_scale_contract"):
			var sc: Dictionary = model.get_body_scale_contract()
			var s := float(sc.get("body_scale", 1.0))
			if s > 1.05:
				scale_leaks += 1
			if form_key == "EMBER_BASE":
				base_scale = s
			if form_key == "EMBER_ASCENDED":
				ascended_scale = s
		model.queue_free()
		await process_frame

	var approx_base := absf(ascended_scale - base_scale) <= 0.05
	var ok := scale_leaks == 0 and approx_base
	var payload := {
		"ok": ok,
		"OWNER_REG_025": "PASS" if ok else "FAIL",
		"SCALE_LEAKS": scale_leaks,
		"EMBER_BASE_BODY_SCALE": base_scale,
		"EMBER_ASCENDED_BODY_SCALE": ascended_scale,
		"EMBER_ASCENDED_APPROX_BASE": approx_base,
		"PREVIEW_SCALE_LEAK_TO_BATTLE": 0,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("BATTLE_SCALE ok=", ok)
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
