extends SceneTree
## AA-RTM-002 deepen: interrupted Story journey + signed save authority.
## Exercises mid-journey combat checkpoint stamp, reload restore, forged combat
## rejection, and dialogue-only advance without battle receipts.
## Does NOT touch HitResolver / rollback / shipping netcode. Not V1 / owner sign-off.

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
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated Story profile required")
		quit(2)
		return

	var campaign = root.get_node("CampaignRuntime")
	campaign.save_path = "user://story_interrupted_journey_authority.json"
	check(campaign.reset_campaign(), "isolated_signed_profile_created")
	check(campaign.progress.schema == "anime_v1.progress.v2", "schema_v2")
	var route_id := "kaia-windrow"
	check(str(campaign.progress.selected_route) == route_id, "default_route_kaia")
	var start_node: String = str(campaign.current_node().get("id", ""))
	check(not start_node.is_empty(), "cursor_has_start_node")

	# Mid-journey interrupt: stamp combat stocks/damage onto signed checkpoint, then reload.
	campaign._stamp_combat(route_id, 1, 37.5)
	check(campaign.save_progress(), "interrupted_combat_checkpoint_saved")
	var stamped: Dictionary = campaign.progress.checkpoint.duplicate(true)
	check(stamped.get("schema", "") == "anime_v1.checkpoint.v1", "checkpoint_schema_v1")
	check(int(stamped.get("combat", {}).get("stocks", -1)) == 1, "stamped_stocks")
	check(is_equal_approx(float(stamped.get("combat", {}).get("damage_percent", -1.0)), 37.5), "stamped_damage")
	check(str(stamped.get("cursor", "")) == start_node, "stamped_cursor_matches_journey")

	# Simulate process restart via load_progress (same authenticated key).
	campaign.load_progress()
	check(campaign.last_error.is_empty(), "authenticated_reload_clears_error")
	check(str(campaign.current_node().get("id", "")) == start_node, "reload_restores_cursor_node")
	var restored: Dictionary = campaign.progress.checkpoint
	check(int(restored.get("combat", {}).get("stocks", -1)) == 1, "reload_restores_interrupted_stocks")
	check(is_equal_approx(float(restored.get("combat", {}).get("damage_percent", -1.0)), 37.5), "reload_restores_interrupted_damage")
	check(campaign.active_encounter.is_empty(), "reload_clears_active_encounter")

	# Forged combat with illegal completed prefix must not survive restore_story_checkpoint.
	var forged: Dictionary = campaign.story_checkpoint(route_id, campaign._node_ids(route_id), ["not-a-real-node"], 2, 0.0)
	var forged_combat: Variant = forged.get("combat", {})
	var forged_combat_empty := (not forged.has("combat")) or (forged_combat is Dictionary and (forged_combat as Dictionary).is_empty())
	check(forged_combat_empty or (forged.get("completed", []) as Array).is_empty(), "forged_prefix_drops_or_empties_combat")
	var illegal_restore: Dictionary = campaign.restore_story_checkpoint({
		"schema": "anime_v1.checkpoint.v1",
		"route_id": route_id,
		"completed": ["kaia-windrow:does-not-exist"],
		"cursor": "kaia-windrow:does-not-exist",
		"combat": {"stocks": 99, "damage_percent": 999.0},
	}, campaign._node_ids(route_id))
	check((illegal_restore.get("completed", []) as Array).is_empty(), "illegal_completed_prefix_rejected")
	var illegal_combat: Variant = illegal_restore.get("combat", {})
	check((not illegal_restore.has("combat")) or (illegal_combat is Dictionary and (illegal_combat as Dictionary).is_empty()), "illegal_combat_not_trusted")

	# Dialogue-only advance (no battle receipt): acknowledge current INTERACTIVE_DIALOGUE if present,
	# otherwise stamp that non-battle kinds are not silently completed via acknowledge with wrong id.
	var node: Dictionary = campaign.current_node()
	var kind := str(node.get("kind", ""))
	if kind == "INTERACTIVE_DIALOGUE" or kind == "CINEMATIC" or kind == "SCENE":
		var node_id := str(node.get("id", ""))
		check(campaign.acknowledge_scene(node_id, route_id), "owned_scene_acknowledge_advances")
		check(node_id in campaign.progress.routes[route_id].completed, "dialogue_node_recorded_complete")
		check(campaign.save_progress(), "post_dialogue_save")
		var after_cursor := str(campaign.current_node().get("id", ""))
		check(after_cursor != node_id or campaign.progress.routes[route_id].get("complete", false), "cursor_advances_or_route_complete")
		campaign.load_progress()
		check(node_id in campaign.progress.routes[route_id].completed, "dialogue_completion_survives_reload")
	else:
		# Opening node is a battle: wrong-route acknowledge must not mutate signed progress.
		var before := JSON.stringify(campaign.progress)
		var disk_before := FileAccess.get_file_as_bytes(campaign.save_path)
		check(not campaign.acknowledge_scene(start_node, "ember-vale"), "wrong_route_acknowledge_rejected")
		check(JSON.stringify(campaign.progress) == before, "wrong_route_leaves_memory_unchanged")
		check(FileAccess.get_file_as_bytes(campaign.save_path) == disk_before, "wrong_route_leaves_disk_unchanged")

	# Unverified envelope warning path: overwrite save with unsigned JSON and reload.
	var unsigned := {"schema": "anime_v1.progress.v2", "canon_decision": campaign.campaign.get("canon_decision", ""), "selected_route": route_id, "presentation": "male", "routes": {}}
	var f := FileAccess.open(campaign.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(unsigned))
	f.close()
	campaign.load_progress()
	check(campaign.last_error.find("Unverified") >= 0 or campaign.last_error.find("legacy") >= 0, "unsigned_envelope_warns")
	check(campaign.progress.presentation == "female", "unsigned_does_not_apply_presentation")

	_finish()

func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Interrupted Story journey signed checkpoint + forged combat rejection + dialogue/wrong-route authority. Not owner playthrough / V1.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"req_id": "AA-RTM-002",
	}
	if not output.is_empty():
		var out := FileAccess.open(output.path_join("STORY_INTERRUPTED_JOURNEY_AUTHORITY.json"), FileAccess.WRITE)
		out.store_string(JSON.stringify(result, "\t"))
	print("STORY_INTERRUPTED_JOURNEY_AUTHORITY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size())
	quit(0 if failures.is_empty() else 1)
