extends SceneTree

## Rosamere (secret tenth) unlocks from earned Story progress: the Kaia route's
## pink_revelation scene after qualifying receipts for every prior battle.
## Receipts here are in-memory fixtures; the signed-save cases prove forged
## state cannot mint the unlock. Not a human playthrough; HUMAN/RC2/V1 false.

const ROUTE := "kaia-windrow"
const REVEAL := "kaia-windrow:pink_revelation"

var failures: Array = []
var checks := 0
var campaign
var state


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _complete_through(node_id: String, qualifying := true, skip_qualify_id := "") -> void:
	var entry: Dictionary = campaign.progress["routes"][ROUTE]
	entry["completed"] = []
	entry["receipts"] = {}
	for node in campaign.route_data(ROUTE)["nodes"]:
		var nid := str(node["id"])
		entry["completed"].append(nid)
		if node["kind"] == "STORY_BATTLE":
			entry["receipts"][nid] = {"node_id": nid, "winner": 1, "token": "fixture-" + nid, "qualifying": qualifying and nid != skip_qualify_id}
		if nid == node_id:
			break
	campaign._rebuild_cursor(ROUTE)


func _run() -> void:
	campaign = root.get_node("CampaignRuntime")
	state = root.get_node("GameState")
	campaign.save_path = "/private/tmp/anime-rosamere-story-unlock.json"
	check(OS.get_environment("AA_ROSAMERE_DEV_OVERRIDE") != "1", "dev_override_absent")
	check(campaign.reset_campaign(), "reset")
	check(campaign.progress.has("rosamere_unlocked") and not campaign.progress["rosamere_unlocked"], "fresh_locked")
	check("rosamere" not in state.selectable_roster_ids(false), "fresh_roster_hides_rosamere")
	check(not state.is_secret_tenth_unlocked(), "fresh_secret_tenth_locked")

	_complete_through("kaia-windrow:prismatic_gray")
	check(not campaign.progress["rosamere_unlocked"], "breakthrough_without_revelation_locked")

	_complete_through(REVEAL)
	check(campaign.progress["rosamere_unlocked"], "revelation_after_earned_prefix_unlocks")
	check(state.is_secret_tenth_unlocked(), "secret_tenth_reports_unlocked")
	check("rosamere" in state.selectable_roster_ids(false), "roster_shows_rosamere")
	check(not campaign.progress["yin_unlocked"] and not campaign.progress["yang_unlocked"], "cosmic_pair_still_locked")
	check(not campaign.progress["routes"][ROUTE]["complete"], "route_not_falsely_complete")

	_complete_through(REVEAL, true, "kaia-windrow:first_loss")
	check(not campaign.progress["rosamere_unlocked"], "non_qualifying_battle_blocks_unlock")
	check("rosamere" not in state.selectable_roster_ids(false), "roster_hides_after_unqualified")

	# Signed save holding a forged flag + fixture receipts: reload recomputes from
	# validated receipts only, so the unlock must not survive.
	_complete_through(REVEAL)
	campaign.progress["rosamere_unlocked"] = true
	check(campaign.save_progress(), "signed_save_written")
	campaign.load_progress()
	check(not campaign.progress["rosamere_unlocked"], "forged_receipts_cannot_unlock_on_reload")
	check("rosamere" not in state.selectable_roster_ids(false), "reload_roster_hides_rosamere")

	check(campaign.reset_campaign(), "cleanup_reset")
	var ok := failures.is_empty()
	var payload := {
		"schema": "anime.rosamere_story_unlock.v1",
		"ok": ok,
		"checks": checks,
		"failures": failures,
		"reveal_node": REVEAL,
		"receipts_are_fixtures": true,
		"HUMAN_PLAYTHROUGH": false,
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	var abs := ProjectSettings.globalize_path("res://").path_join("../artifacts/cursor_continuation/ROSAMERE_STORY_UNLOCK_EVIDENCE.json")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print("RosamereStoryUnlock ", "PASS" if ok else "FAIL", " (", checks, ") ", failures)
	quit(0 if ok else 1)
