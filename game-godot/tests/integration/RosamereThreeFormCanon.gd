extends SceneTree
## Validates owner-approved three-form canon: UI shows three manifestations;
## COMPETITIVE_SELF_LIMITED is Familiar Rose's gameplay contract (not a fourth form);
## permitted modes; Everlasting never ranked; art/balance gates stay false.

var output := ""
var checks: Array = []
var failures: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks.append({"check": label, "pass": value})
	if not value:
		failures.append(label)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty():
		output = OS.get_environment("AA_TEST_OUTPUT")

	var Selection = load("res://scripts/combat/rosamere_form_selection.gd")
	check(Selection != null, "rosamere_form_selection_loads")
	var canon: Dictionary = Selection.validate_three_form_canon()
	check(bool(canon.get("ok", false)), "three_form_canon_validate")
	for f in canon.get("failures", []):
		check(false, "canon_fail:" + str(f))
	check(str(canon.get("name", "")) == "Rosamere", "name_rosamere_final")
	check(str(canon.get("title", "")) == "The First Bloom", "title_first_bloom_final")
	check(canon.get("manifestations", []).size() == 3, "exactly_three_manifestations")
	check("COMPETITIVE_SELF_LIMITED" not in canon.get("manifestations", []), "contract_not_ui_manifestation")

	var familiar: Dictionary = Selection.normalize_selection("FAMILIAR_ROSE")
	check(bool(familiar.get("ok", false)) and str(familiar.get("gameplay_contract_id", "")) == "COMPETITIVE_SELF_LIMITED", "familiar_carries_competitive_contract")
	var mapped: Dictionary = Selection.normalize_selection("COMPETITIVE_SELF_LIMITED")
	check(bool(mapped.get("ok", false)) and str(mapped.get("form_id", "")) == "FAMILIAR_ROSE", "competitive_maps_to_familiar")
	check(not bool(mapped.get("fourth_form", true)), "not_fourth_form")

	check(bool(Selection.select_for_mode("FAMILIAR_ROSE", "versus").get("ok", false)), "familiar_versus_ok")
	check(bool(Selection.select_for_mode("FIRST_BLOOM", "versus").get("ok", false)), "first_bloom_versus_ok")
	check(not bool(Selection.select_for_mode("EVERLASTING_ORIGIN", "versus").get("ok", true)), "everlasting_versus_forbidden")
	check(not bool(Selection.select_for_mode("EVERLASTING_ORIGIN", "ranked").get("ok", true)), "everlasting_ranked_forbidden")
	check(bool(Selection.select_for_mode("EVERLASTING_ORIGIN", "story", true).get("ok", false)), "everlasting_story_ok")
	check(bool(Selection.select_for_mode("EVERLASTING_ORIGIN", "mythic_party", true).get("ok", false)), "everlasting_mythic_party_with_consent")
	check(not bool(Selection.select_for_mode("EVERLASTING_ORIGIN", "mythic_party", false).get("ok", true)), "everlasting_mythic_requires_consent")

	var Pink = load("res://scripts/combat/pink_bloom_systems.gd")
	var sys = Pink.new()
	sys.reset(3)
	check(sys.form_id == "FAMILIAR_ROSE", "pink_default_familiar_rose")
	check(sys.gameplay_contract_id == "COMPETITIVE_SELF_LIMITED", "pink_default_competitive_contract")
	check(sys.story_forms().size() == 3, "pink_story_forms_three")
	var via_contract: Dictionary = sys.set_form("COMPETITIVE_SELF_LIMITED", false)
	check(bool(via_contract.get("ok", false)) and str(via_contract.get("form_id", "")) == "FAMILIAR_ROSE", "pink_set_contract_resolves_familiar")
	check(not bool(via_contract.get("fourth_form", true)), "pink_rejects_fourth_form_flag")
	var bloom: Dictionary = sys.set_form("FIRST_BLOOM", false)
	check(bool(bloom.get("ok", false)) and sys.competitive_can_lose(), "first_bloom_can_lose")
	var denied: Dictionary = sys.set_form("EVERLASTING_ORIGIN", false)
	check(not bool(denied.get("ok", true)), "everlasting_needs_consent")
	var ok_e: Dictionary = sys.set_form("EVERLASTING_ORIGIN", true)
	check(bool(ok_e.get("ok", false)) and not sys.competitive_can_lose(), "everlasting_story_mythic")

	var fighter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters/rosamere.json"))
	check(str(fighter.get("displayName", "")) == "Rosamere", "fighter_display_name_final")
	check(str(fighter.get("title", "")) == "The First Bloom", "fighter_title_final")
	check(str(fighter.get("name_status", "")) == "OWNER_FINAL", "name_status_owner_final")
	check(bool(fighter.get("owner_approved", {}).get("three_form_canon", false)), "three_form_owner_approved")
	check(not bool(fighter.get("owner_approved", {}).get("final_art", true)), "final_art_not_approved")
	check(not bool(fighter.get("art_status", {}).get("cel_shaded_glb", true)), "honest_no_fake_glb")
	check(not bool(fighter.get("owner_approved", {}).get("V1_0_0_RELEASE_AUTHORIZED", true)), "v1_gate_false")
	check(not bool(fighter.get("owner_approved", {}).get("RC2_READY", true)), "rc2_gate_false")

	var forms_doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/forms/rosamere.json"))
	check(bool(forms_doc.get("ascension_runtime", false)), "forms_ascension_runtime")
	check(forms_doc.get("form_ladder", []).size() == 2, "competitive_ladder_excludes_everlasting")
	check("EVERLASTING_ORIGIN" in forms_doc.get("story_form_ladder", []), "story_ladder_has_everlasting")
	var hook: Dictionary = Selection.transition_hook("FAMILIAR_ROSE", "FIRST_BLOOM")
	check(not hook.is_empty() and bool(hook.get("deterministic", false)), "transition_hook_familiar_to_bloom")

	var Def = load("res://scripts/combat/fighter_definition.gd")
	var built: Dictionary = Def.build("rosamere", fighter)
	check(str(built.get("default_form_id", "")) == "FAMILIAR_ROSE", "fighter_definition_default_familiar")
	check(bool(built.get("ascension_enabled", false)), "fighter_definition_ascension")

	finish()

func finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Rosamere three-form canon confirmation: name/title/mythology owner-approved; art/balance/V1 gates false. Not V1.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("ROSAMERE_THREE_FORM_CANON.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(result, "\t"))
	quit(0 if failures.is_empty() else 1)
