extends SceneTree
## Rosamere spoiler-safe eligibility across Trials modes.

const Eligibility = preload("res://scripts/trials/rosamere_trials_eligibility.gd")

var failures: Array = []
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	## Pre-reveal: only Familiar Rose.
	var offered := Eligibility.offered_forms("resonance_trial", false, false)
	check(offered == ["FAMILIAR_ROSE"], "spoiler_safe_pre_reveal")
	var denied := Eligibility.evaluate("EVERLASTING_ORIGIN", "resonance_trial", true, true)
	check(not bool(denied.get("ok", true)), "everlasting_forbidden_in_derby")
	var unbound_denied := Eligibility.evaluate("EVERLASTING_ORIGIN", "convergence_unbound", false, true)
	check(not bool(unbound_denied.get("ok", true)), "unbound_needs_consent")
	var unbound_ok := Eligibility.evaluate("EVERLASTING_ORIGIN", "convergence_unbound", true, true)
	check(bool(unbound_ok.get("ok", false)), "unbound_with_consent")
	check(not bool(unbound_ok.get("avatar_ko_is_true_defeat", true)), "avatar_ko_not_true")
	var bloom := Eligibility.evaluate("FIRST_BLOOM", "fractured_accord", false, true)
	check(bool(bloom.get("ok", false)), "first_bloom_post_reveal")
	print("TRIALS_ROSAMERE_ELIGIBILITY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
