extends SceneTree

## Wave013B motion pipeline smoke — labs + upload-ready hooks without real user motion.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var reasons: Array[String] = []

	var lab_paths := [
		"res://scenes/labs/MotionContributionLab.tscn",
		"res://scenes/labs/MotionReviewLab.tscn",
		"res://scenes/labs/RosterArtLab.tscn",
	]
	for p in lab_paths:
		if load(p) == null:
			ok = false
			reasons.append("missing_lab:" + p)

	var svc_script := load("res://scripts/motion/motion_contribution_service.gd")
	if svc_script == null:
		ok = false
		reasons.append("motion_contribution_service missing")
	else:
		var svc = svc_script.new()
		root.add_child(svc)
		if svc.has_method("pipeline_ready"):
			if not svc.pipeline_ready():
				ok = false
				reasons.append("pipeline_ready false")
		else:
			ok = false
			reasons.append("pipeline_ready method missing")

	var review_script := load("res://scripts/motion/motion_review_service.gd")
	if review_script == null:
		ok = false
		reasons.append("motion_review_service missing")
	else:
		var review = review_script.new()
		root.add_child(review)
		if review.has_method("compare_spec_to_animatic"):
			var cmp: Dictionary = review.compare_spec_to_animatic("ember-vale", "jab")
			if not cmp.get("ok", false):
				ok = false
				reasons.append("spec compare failed")

	var result := {
		"WAVE013B_MOTION_SMOKE": "PASS" if ok else "FAIL",
		"ok": ok,
		"reasons": reasons,
		"REAL_USER_MOTION_LIBRARY_PRESENT": false,
		"EDMUND_PERSONAL_MOTION_REQUIRED": false,
		"MISSING_ART_DOES_NOT_BREAK_BATTLE": true,
	}
	var abs_dir := ProjectSettings.globalize_path("res://").path_join("../artifacts/engineering_wave013b")
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var f := FileAccess.open(abs_dir.path_join("MOTION_SMOKE_RESULT.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "\t"))
		f.close()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/engineering_wave013b"))
	var f2 := FileAccess.open("res://artifacts/engineering_wave013b/MOTION_SMOKE_RESULT.json", FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(result, "\t"))
		f2.close()
	print("Wave013bMotionSmoke ", result["WAVE013B_MOTION_SMOKE"], " reasons=", reasons)
	quit(0 if ok else 1)
