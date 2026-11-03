extends "res://tests/v1_closure/GrabForms8A.gd"
## Reuse existing public form/grab fixtures; require real saved acting imports.
## No earned Story form, boss-asset or form-specific artistic acceptance.
var inspected := 0
var release_snapshot: Dictionary = {}
var watched_owners: Dictionary = {}

func prepare(p, d, fid: String, body: String, face: int) -> void:
	await super.prepare(p, d, fid, body, face)
	release_snapshot.clear()
	if not watched_owners.has(d.get_instance_id()):
		watched_owners[d.get_instance_id()] = true
		d.grab_event.connect(func(info):
			if info.get("result") != "throw":return
			var c = d.model_3d.get_animation_controller()
			var selected: String = c.get_active_clip()
			release_snapshot = {"report":c.get_grab_acting_report(), "clip":selected,
				"source":c._grab_acting_sources.get(selected, {}).duplicate(true), "body":d.data.body_variant})

func write(done: bool) -> void:
	if rows.size() > inspected:
		inspected = rows.size()
		# The parent writes after48recovery frames. Read the real throw callback,
		# not that intentionally returned-to-neutral pose.
		var report: Dictionary = release_snapshot.get("report", {})
		var clip: String = release_snapshot.get("clip", "")
		var label: String = str(rows[-1].fighter) + ":" + str(rows[-1].domain)
		check(report.get("overlay_status") == "verified_source_export", label + ":saved_source_survives_form")
		check(clip.begins_with("throw_"), label + ":real_saved_throw_after_form")
		check(not release_snapshot.get("source", {}).is_empty(), label + ":source_action_selected")
		rows[-1]["acting_source"] = report
		rows[-1]["actual_saved_clip"] = clip
		rows[-1]["actual_body"] = release_snapshot.get("body", "")
		rows[-1]["source_at_real_release"] = release_snapshot.get("source", {})
	var f = FileAccess.open(output.path_join("grab_acting_forms_8b.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(), "complete":done, "rows":rows, "failures":failures,
		"scope":"54 existing form/Party public-grab fixtures with real 8B saved-action routing; rotating bodies/facings. No earned Story forms, full form/body/facing product, cosmic boss art, native visuals or human approval."}, "\t"));f.close()
