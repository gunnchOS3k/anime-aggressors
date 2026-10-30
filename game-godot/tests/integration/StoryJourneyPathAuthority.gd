extends SceneTree
## AA-RTM-002 Story journey path deepen —
## A) prologue STORY_BATTLE begin → interrupt checkpoint → reload
## B) authored INTERACTIVE_DIALOGUE cursor fixture → acknowledge → reload
## Not owner playthrough / V1. Does not rewrite combat/rollback.

var output := ""
var checks: Array = []
var failures: Array = []
var path_trace: Array = []


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
	var gs = root.get_node("GameState")
	campaign.save_path = "user://story_journey_path_authority.json"
	check(campaign.reset_campaign(), "reset_campaign")
	var route_id := "kaia-windrow"
	check(str(campaign.progress.selected_route) == route_id, "kaia_route")

	## A) Opening journey is STORY_BATTLE for all spectral routes — deepen that path.
	var battle_node: Dictionary = campaign.current_node()
	var battle_id := str(battle_node.get("id", ""))
	check(str(battle_node.get("kind", "")) == "STORY_BATTLE", "opens_on_story_battle")
	check(bool(battle_node.get("implemented", false)), "prologue_implemented")
	path_trace.append({"path": "A", "id": battle_id, "kind": "STORY_BATTLE", "objective": str(battle_node.get("objective", ""))})

	gs.battle_eval_mode = false
	check(campaign.begin_encounter(), "begin_prologue_encounter")
	check(str(campaign.active_encounter.get("node_id", "")) == battle_id, "encounter_node")
	check(str(gs.mode) == "story", "gamestate_story_mode")
	check(str(gs.stage_id) != "", "stage_bound")
	check(str(gs.p1_fighter_id) != "" and str(gs.p2_fighter_id) != "", "fighters_bound")

	campaign._stamp_combat(route_id, 2, 18.5)
	check(campaign.save_progress(), "interrupt_save")
	campaign.load_progress()
	check(campaign.last_error.is_empty(), "reload_auth_ok")
	check(str(campaign.current_node().get("id", "")) == battle_id, "resume_same_prologue")
	check(int(campaign.progress.checkpoint.get("combat", {}).get("stocks", -1)) == 2, "resume_stocks")
	check(is_equal_approx(float(campaign.progress.checkpoint.get("combat", {}).get("damage_percent", -1.0)), 18.5), "resume_damage")
	check(campaign.active_encounter.is_empty(), "reload_clears_encounter")
	check(battle_id not in campaign.progress.routes[route_id].completed, "prologue_not_auto_won")

	## B) Authored dialogue journey content — fixture cursor onto INTERACTIVE_DIALOGUE
	## (same honesty pattern as StorySceneOwnership; does not invent battle receipts).
	var dialogue_id := "kaia-windrow:accord"
	var dialogue_node: Dictionary = {}
	for node in campaign.route_data(route_id).get("nodes", []):
		if str(node.get("id", "")) == dialogue_id:
			dialogue_node = node
			break
	check(not dialogue_node.is_empty(), "dialogue_node_present")
	check(str(dialogue_node.get("kind", "")) == "INTERACTIVE_DIALOGUE", "dialogue_kind")
	check(bool(dialogue_node.get("implemented", false)), "dialogue_implemented")
	campaign.progress = campaign.new_progress()
	campaign.progress.selected_route = route_id
	campaign.progress.routes[route_id].cursor = dialogue_id
	check(campaign.save_progress(), "dialogue_fixture_save")
	check(str(campaign.current_node().get("id", "")) == dialogue_id, "cursor_on_dialogue")
	path_trace.append({"path": "B", "id": dialogue_id, "kind": "INTERACTIVE_DIALOGUE"})

	check(campaign.acknowledge_scene(dialogue_id, route_id), "acknowledge_dialogue")
	check(dialogue_id in campaign.progress.routes[route_id].completed, "dialogue_completed_in_memory")
	var after: Dictionary = campaign.current_node()
	var after_id := str(after.get("id", ""))
	path_trace.append({"path": "B", "advanced_to": after_id, "kind": str(after.get("kind", ""))})
	check(campaign.save_progress(), "post_dialogue_save")
	## Out-of-order dialogue (no earned battle prefix) must NOT mint durable progression on reload.
	campaign.load_progress()
	check(dialogue_id not in campaign.progress.routes[route_id].completed, "out_of_order_dialogue_not_durable")
	check(str(campaign.current_node().get("id", "")) == battle_id, "reload_returns_sequential_cursor")
	path_trace.append({"path": "B", "honesty": "out_of_order_dialogue_dropped_on_authenticated_restore"})

	## Wrong-route acknowledge cannot steal journey while on prologue cursor.
	var mem := JSON.stringify(campaign.progress)
	check(not campaign.acknowledge_scene(dialogue_id, "ember-vale"), "wrong_route_rejected")
	check(JSON.stringify(campaign.progress) == mem, "wrong_route_no_mutate")

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"path_trace": path_trace,
		"scope": "Kaia Story journey paths: prologue battle interrupt/resume + authored dialogue acknowledge/reload. Not owner sign-off / V1.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"req_id": "AA-RTM-002",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("STORY_JOURNEY_PATH_AUTHORITY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("STORY_JOURNEY_PATH_AUTHORITY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " path=", path_trace.size())
	quit(0 if failures.is_empty() else 1)
