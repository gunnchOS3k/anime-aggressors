extends SceneTree

## Wave022 battle scale — all 7 fighters BASE vs ASCENDED body_scale ≈ 1.0.

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _FormDefinition = preload("res://scripts/combat/form_definition.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave022/BATTLE_SCALE_RESULT.json",
	"../artifacts/engineering_wave022/BATTLE_SCALE_RESULT.json",
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


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var scale_leaks := 0
	var per_fighter: Dictionary = {}

	for fighter_id in ROSTER:
		var forms_doc := _FormDefinition.load_forms(fighter_id)
		var ladder: Array = forms_doc.get("form_ladder", [])
		if ladder.is_empty():
			scale_leaks += 1
			continue
		var base_key: String = str(ladder[0])
		var asc_key: String = str(ladder[ladder.size() - 1])
		var base_scale := 0.0
		var asc_scale := 0.0
		for form_key in [base_key, asc_key]:
			var entry := _FormDefinition.form_entry(forms_doc, form_key)
			var model: Node2D = MODEL_SCRIPT.new()
			host.add_child(model)
			model.set_presentation_context("BATTLE")
			model.configure({"id": fighter_id})
			model.set_form_id(form_key, entry)
			await process_frame
			if model.has_method("get_body_scale_contract"):
				var sc: Dictionary = model.get_body_scale_contract()
				var s := float(sc.get("body_scale", 1.0))
				if s > 1.05:
					scale_leaks += 1
				if form_key == base_key:
					base_scale = s
				if form_key == asc_key:
					asc_scale = s
			model.queue_free()
			await process_frame
		var approx := absf(asc_scale - base_scale) <= 0.05
		if not approx:
			scale_leaks += 1
		per_fighter[fighter_id] = {
			"base_scale": base_scale,
			"ascended_scale": asc_scale,
			"approx_base": approx,
		}

	var ok := scale_leaks == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_025_PRESERVED": "PASS" if ok else "FAIL",
		"SCALE_LEAKS": scale_leaks,
		"per_fighter": per_fighter,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("WAVE022_BATTLE_SCALE ok=", ok)
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
