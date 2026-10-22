extends "res://tests/v1_closure/GrabForms8A.gd"
## Reuse existing public form/grab fixtures; require real saved acting imports.
## No earned Story form, boss-asset or form-specific artistic acceptance.
var inspected := 0

func write(done: bool) -> void:
	if rows.size() > inspected:
		inspected = rows.size()
		var actor = current_scene.fighter2
		var controller = actor.model_3d.get_animation_controller()
		var report: Dictionary = controller.get_grab_acting_report()
		var clip: String = controller.get_active_clip()
		var label: String = str(rows[-1].fighter) + ":" + str(rows[-1].domain)
		check(report.get("overlay_status") == "verified_source_export", label + ":saved_source_survives_form")
		check(clip.begins_with("throw_"), label + ":real_saved_throw_after_form")
		check(controller._grab_acting_sources.has(clip), label + ":source_action_selected")
		rows[-1]["acting_source"] = report
		rows[-1]["actual_saved_clip"] = clip
		rows[-1]["actual_body"] = actor.data.body_variant
	var f = FileAccess.open(output.path_join("grab_acting_forms_8b.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(), "complete":done, "rows":rows, "failures":failures,
		"scope":"54 existing form/Party public-grab fixtures with real 8B saved-action routing; rotating bodies/facings. No earned Story forms, full form/body/facing product, cosmic boss art, native visuals or human approval."}, "\t"));f.close()
