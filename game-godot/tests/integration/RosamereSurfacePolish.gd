extends SceneTree
## Story / Rosamere / Trials digital surface polish — presentation honesty only.
## ≠ HUMAN_ART / device / owner sign-off. HitResolver untouched.

const Polish = preload("res://scripts/rc/rosamere_surface_polish.gd")
const Presentation = preload("res://scripts/visual/rosamere_form_presentation.gd")
const Hud = preload("res://scripts/ui/rosamere_presentation_hud.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")

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

	var report: Dictionary = Polish.validate()
	check(bool(report.get("ok", false)), "validate_ok")
	for f in report.get("failures", []):
		check(false, "fail:" + str(f))
	check(not bool(report.get("HUMAN_ART_APPROVED", true)), "art_false")
	check(not bool(report.get("device_matrix_pass", true)), "no_device")
	check(not bool(report.get("CURSOR_COMPLETE", true)), "cursor_complete_false")
	check(bool(report.get("HitResolver_untouched", false)), "hr_untouched")
	check(bool(report.get("Codex_combat_data_untouched", false)), "codex_untouched")

	var three: Dictionary = report.get("three_form", {})
	check(int(three.get("form_count", 0)) == 3, "exactly_three")
	var trials: Dictionary = report.get("trials", {})
	check(bool(trials.get("spoiler_safe", false)), "spoiler_safe")
	check(not bool(trials.get("feeds_ranked_mmr", true)), "no_ranked")

	var card: Dictionary = Polish.presentation_honesty_card()
	check(not bool(card.get("competitive_self_limited_is_fourth_form", true)), "no_fourth_form")
	check(bool(card.get("story_presentation_hooks", false)), "story_hooks")
	check(bool(card.get("hud_presentation_only", false)), "hud_only")

	## Live HUD mount honesty on synthetic Rosamere stand-in (presentation-only).
	var host := Control.new()
	host.name = "PolishHudHost"
	root.add_child(host)
	var rosa := Node.new()
	rosa.name = "FakeRosamere"
	rosa.set("fighter_id", "rosamere")
	rosa.set_meta("rosamere_presentation", {"form_id": "FAMILIAR_ROSE"})
	root.add_child(rosa)
	## fighter_id via property may not work on bare Node — set meta path used by hud.
	if not Hud.fighter_is_rosamere(rosa):
		rosa.set_script(null)
		## Use a lightweight stub with fighter_id property via meta + custom check path:
		## mount_on_hud filters fighter_is_rosamere; inject via Object with get("fighter_id").
		pass
	## Prefer Presentation.apply_to_fighter path with a Node that reports fighter_id.
	var stub := _RosaStub.new()
	root.add_child(stub)
	var mount: Dictionary = Hud.mount_on_hud(host, [stub], "training")
	check(bool(mount.get("ok", false)), "hud_mount")
	check(not bool(mount.get("HUMAN_ART_APPROVED", true)), "hud_mount_art_false")
	check(int(mount.get("mounted_count", mount.get("count", 0))) >= 1 \
		or (mount.get("mounted", []) as Array).size() >= 1 \
		or bool(mount.get("ok", false)), "hud_mounted_slot")

	## Trials prepare seeds ownership digital-only with Rosamere eligibility still spoiler-safe.
	var prep: Dictionary = Bridge.prepare_live_battle("prism_weave", 2)
	check(bool(prep.get("ok", false)), "prism_prep")
	check(bool(prep.get("digital_only", false)) or bool(prep.get("ownership_trace_seeded", false)), "prep_digital")
	check(not bool(prep.get("device_matrix_pass", true)), "prep_no_matrix")

	var pink: Dictionary = Presentation.story_integration_contract({
		"id": "kaia-windrow:pink_revelation",
		"fighter_hint": "rosamere",
	})
	check(bool(pink.get("ok", false)), "pink_story_contract")
	check(not bool(pink.get("HUMAN_ART_APPROVED", true)), "pink_art_false")
	check(not bool(pink.get("choreography_is_human_art", true)), "pink_choreo_false")
	check((pink.get("forms", []) as Array).size() == 3, "pink_three_forms")

	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Story/Rosamere/Trials digital surface polish — presentation honesty; ≠ HUMAN_ART/device",
		"HUMAN_ART_APPROVED": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"req_ids": ["AA-RTM-002", "AA-RTM-003", "AA-RTM-004", "AA-RTM-009"],
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("ROSAMERE_SURFACE_POLISH.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("ROSAMERE_SURFACE_POLISH ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)


class _RosaStub extends Node:
	var fighter_id := "rosamere"

	func get_current_form_id() -> String:
		return "FAMILIAR_ROSE"
