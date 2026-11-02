extends SceneTree
## Story / Rosamere art / Trials / stages cross-surface presentation honesty.
## ≠ HUMAN_ART / device / RC2 / V1. HitResolver / Codex combat untouched.

const Honesty = preload("res://scripts/rc/story_art_stages_presentation_honesty.gd")
const StagePresentation = preload("res://scripts/battle/stage_presentation.gd")
const TrialsPresentation = preload("res://scripts/trials/mode_presentation.gd")
const CursorComplete = preload("res://scripts/rc/cursor_complete_honesty.gd")

var failures: Array = []
var checks := 0
var output := ""


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")

	var report: Dictionary = Honesty.validate()
	check(bool(report.get("ok", false)), "validate_ok")
	for f in report.get("failures", []):
		check(false, "fail:" + str(f))
	check(not bool(report.get("HUMAN_ART_APPROVED", true)), "art_false")
	check(not bool(report.get("device_matrix_pass", true)), "no_device")
	check(not bool(report.get("RC2_READY", true)), "rc2_false")
	check(not bool(report.get("V1_0_0_RELEASE_AUTHORIZED", true)), "v1_false")
	check(not bool(report.get("CURSOR_COMPLETE", true)), "cursor_complete_false")
	check(bool(report.get("HitResolver_untouched", false)), "hr_untouched")
	check(bool(report.get("Codex_combat_data_untouched", false)), "codex_untouched")

	var stages: Dictionary = report.get("stages", {})
	check(int(stages.get("playable_count", 0)) == 30, "stages_30")
	check(int(stages.get("pending_count", -1)) == 0, "no_pending")
	check(bool(stages.get("canonical_launch_preserved", false)), "launch_preserved")

	var trials: Dictionary = report.get("trials", {})
	check(int(trials.get("mode_count", 0)) == 6, "six_trials")

	var rosa: Dictionary = report.get("rosamere_art", {})
	check(str(rosa.get("art_status", "")) == "THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS", "rosa_art_status")

	var cross: Dictionary = report.get("cross", {})
	check(int(cross.get("pink_foreshadow_stage_count", 0)) >= 1, "pink_foreshadow")

	## Live stage presentation card via StageManager build path (no combat rewrite).
	var StageManager = load("res://scripts/battle/stage_manager.gd")
	var mgr = StageManager.new()
	mgr.load_registry()
	var root := Node2D.new()
	self.root.add_child(root)
	var built: Dictionary = mgr.build_stage(root, "neon-underworld", true, "competitive")
	check(bool(built.get("ok", false)), "build_neon")
	check(not bool(built.get("HUMAN_ART_APPROVED", true)), "build_art_false")
	var pcard: Dictionary = built.get("presentation_card", {})
	check(not pcard.is_empty(), "build_presentation_card")
	check(not bool(pcard.get("HUMAN_ART_APPROVED", true)), "pcard_art_false")
	check(bool(pcard.get("layout_playable_neq_human_art", false)), "pcard_layout_neq_art")

	## Trials backdrop honesty for one mode.
	var backdrop: Dictionary = TrialsPresentation.stage_backdrop_honesty("prism_weave")
	check(bool(backdrop.get("ok", false)), "prism_backdrop")
	check(str(backdrop.get("stage_id", "")) == "celestial-observatory", "prism_stage_id")

	## Registry contract direct.
	var reg: Dictionary = StagePresentation.registry_presentation_contract()
	check(bool(reg.get("ok", false)), "registry_ok")
	check(int(reg.get("playable_count", 0)) == 30, "registry_30")

	var gate: Dictionary = CursorComplete.validate()
	check(bool(gate.get("ok", false)), "cursor_complete_honesty")
	check(not bool(gate.get("CURSOR_COMPLETE", true)), "still_incomplete")

	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Story/Rosamere/Trials/stages presentation honesty — ≠ HUMAN_ART/device/RC2/V1",
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"stages_playable": int(stages.get("playable_count", 0)),
		"trials_modes": int(trials.get("mode_count", 0)),
		"req_ids": ["AA-RTM-002", "AA-RTM-003", "AA-RTM-004"],
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("STORY_ART_STAGES_PRESENTATION_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print(
		"STORY_ART_STAGES_PRESENTATION_HONESTY ",
		"PASS" if failures.is_empty() else "FAIL",
		" checks=", checks,
		" failures=", failures
	)
	quit(0 if failures.is_empty() else 1)
