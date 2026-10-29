extends SceneTree
## Deterministic First Bloom systems: IDs, frame expiry/retirement, snapshot
## restore, competitive self-limit, Everlasting Origin mythic consent gate.
## Does not enable shipping LAN rollback. Not V1 / human art acceptance.

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
	var Pink = load("res://scripts/combat/pink_bloom_systems.gd")
	check(Pink != null and Pink.can_instantiate(), "pink_bloom_systems_loads")
	if Pink == null or not Pink.can_instantiate():
		finish(); return
	var sys = Pink.new()
	sys.reset(7)
	check(sys.form_id == "FAMILIAR_ROSE", "default_story_form_familiar_rose")
	check(sys.gameplay_contract_id == "COMPETITIVE_SELF_LIMITED", "default_contract_competitive")
	check(sys.competitive_can_lose(), "competitive_form_can_lose")
	var bloom: Dictionary = sys.activate("BloomSeed", 1, {"duration_frames": 5})
	check(bool(bloom.get("ok", false)), "bloom_seed_activates")
	var event_id := str(bloom.get("effect", {}).get("event_id", ""))
	check(event_id.begins_with("pink:7:"), "bloom_event_id_deterministic_prefix")
	check(sys.has_active("BloomSeed"), "bloom_active")
	var snap: Dictionary = sys.capture()
	check(str(snap.get("schema", "")) == "pink_bloom_systems/v2", "capture_schema_v2")
	check(int(snap.get("manifestation_count", 0)) == 3, "capture_three_manifestations")
	check(not bool(snap.get("ranked_invincible", true)), "capture_rejects_ranked_invincible_flag_default_false")
	for i in range(5):
		sys.advance_frame()
	check(not sys.has_active("BloomSeed"), "bloom_retired_after_expiry")
	check(event_id in sys.retired_event_ids, "retired_event_id_recorded")
	check(sys.restore(snap), "restore_pre_expiry_snapshot")
	check(sys.has_active("BloomSeed"), "bloom_restored_active")
	check(sys.active_event_ids() == [event_id], "restored_event_id_stable")
	var omnipotent: Dictionary = sys.activate("FirstPermission", 1, {"omnipotent": true})
	check(not bool(omnipotent.get("ok", true)), "competitive_rejects_omnipotence")
	var everlasting_denied: Dictionary = sys.set_form("EVERLASTING_ORIGIN", false)
	check(not bool(everlasting_denied.get("ok", true)), "everlasting_requires_consent")
	var everlasting_ok: Dictionary = sys.set_form("EVERLASTING_ORIGIN", true)
	check(bool(everlasting_ok.get("ok", false)), "everlasting_with_consent")
	check(not sys.competitive_can_lose(), "everlasting_story_mythic_not_competitive_loss_contract")
	var mythic: Dictionary = sys.activate("mythic_everything_again", 1, {})
	check(bool(mythic.get("ok", false)), "mythic_everything_again_in_everlasting")
	check(str(mythic.get("effect", {}).get("system_id", "")) == "mythic_everything_again", "mythic_clearly_labeled_system_id")
	var back: Dictionary = sys.set_form("COMPETITIVE_SELF_LIMITED", false)
	check(bool(back.get("ok", false)) and str(back.get("form_id", "")) == "FAMILIAR_ROSE", "contract_id_maps_to_familiar_rose")
	check(sys.competitive_can_lose(), "return_to_familiar_self_limited_can_lose")
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters/roster.json"))
	check("rosamere" in roster.get("fighters", []), "secret_tenth_in_roster")
	check("rosamere" in roster.get("secret", []), "rosamere_marked_secret")
	var moves: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/rosamere.json"))
	var move_ids: Array = []
	for m in moves.get("moves", []):
		move_ids.append(str(m.get("move_id", "")))
	for need in ["bloom_seed", "petal_constellation", "first_dawn", "gentle_reversal", "quiet_embrace", "a_world_in_bloom", "before_there_was_time", "the_first_permission", "mythic_everything_again", "aura_charge", "aura_burst", "grab"]:
		check(need in move_ids, "move_present:" + need)
	check("origination_script" not in move_ids, "aura_charge_id_restored_not_origination_script")
	check("first_permission" not in move_ids, "aura_burst_id_restored_not_first_permission_move_id")
	var by_id: Dictionary = {}
	for m in moves.get("moves", []):
		by_id[str(m.get("move_id", ""))] = m
	check(str(by_id.get("aura_charge", {}).get("input_command", "")) == "aura_charge", "aura_charge_ordinary_input")
	check(str(by_id.get("aura_burst", {}).get("input_command", "")) == "aura_burst", "aura_burst_ordinary_input")
	check(str(by_id.get("bloom_seed", {}).get("input_command", "")) == "special_neutral", "bloom_seed_special_neutral")
	check(str(by_id.get("grab", {}).get("input_command", "")) == "grab", "grab_ordinary_input")
	check(str(by_id.get("quiet_embrace", {}).get("input_command", "")) == "", "quiet_embrace_does_not_steal_grab")
	var fighter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters/rosamere.json"))
	var art_status := str(fighter.get("art_status", {}).get("status", ""))
	check(art_status in ["NOT_AUTHORED_THIS_PASS", "THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS"], "honest_art_status")
	check(not bool(fighter.get("art_status", {}).get("cel_shaded_glb", true)), "no_fake_finished_glb")
	check(not bool(fighter.get("art_status", {}).get("HUMAN_ART_APPROVED", true)), "human_art_still_false")
	check(bool(fighter.get("owner_approved", {}).get("name", false)), "name_owner_approved")
	check(not bool(fighter.get("owner_approved", {}).get("WORKING_CANDIDATE", true)), "canon_not_working_candidate")
	check(not bool(fighter.get("owner_approved", {}).get("final_art", true)), "final_art_still_not_approved")
	finish()

func finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Pink/Rosamere deterministic combat systems + secret registry honesty. Not V1, not human art, shipping rollback remains off.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("PINK_BLOOM_SYSTEMS_DETERMINISM.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(result, "\t"))
	quit(0 if failures.is_empty() else 1)
