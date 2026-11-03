extends SceneTree
## AA-RTM-002 deepen — earn sequential Kaia STOCK_WIN receipts via bound BattleScene
## producer (closed countdown boundary), then INTERACTIVE_DIALOGUE acknowledge that
## survives authenticated reload. Staged producer fixture ≠ owner playthrough / V1.
## Does not rewrite HitResolver / shipping rollback.

const Prefix = preload("res://scripts/story/story_earned_prefix.gd")

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
	var router = root.get_node("SceneRouter")
	campaign.save_path = "user://story_earned_prefix_dialogue_authority.json"
	check(campaign.reset_campaign(), "reset_campaign")
	var route_id := "kaia-windrow"
	check(str(campaign.progress.selected_route) == route_id, "kaia_route")
	gs.battle_eval_mode = false

	## Out-of-order dialogue still cannot mint durable progression (regression).
	var dialogue_id := "kaia-windrow:accord"
	campaign.progress = campaign.new_progress()
	campaign.progress.selected_route = route_id
	campaign.progress.routes[route_id].cursor = dialogue_id
	check(campaign.save_progress(), "ooo_fixture_save")
	check(campaign.acknowledge_scene(dialogue_id, route_id), "ooo_ack_in_memory")
	check(campaign.save_progress(), "ooo_ack_save")
	campaign.load_progress()
	check(dialogue_id not in campaign.progress.routes[route_id].completed, "ooo_not_durable")
	check(str(campaign.current_node().get("id", "")) == "kaia-windrow:prologue", "ooo_reverts_prologue")
	path_trace.append({"honesty": "out_of_order_dialogue_dropped_without_earned_prefix"})

	## Earn real sequential STOCK_WIN receipts through bound BattleScene producer.
	check(campaign.reset_campaign(), "reset_for_earned_prefix")
	gs.battle_eval_mode = false
	var advance: Dictionary = await Prefix.advance_to_dialogue(self, campaign, router, route_id, 12)
	check(bool(advance.get("ok", false)), "advance_to_dialogue")
	check(str(advance.get("dialogue_id", "")) == dialogue_id, "landed_on_accord")
	var earned: Array = advance.get("earned", [])
	check(earned.size() == 7, "seven_stock_wins_before_accord")
	path_trace.append({"path": "earned_prefix", "earned": earned, "staged_producer_fixture": true})
	if not bool(advance.get("ok", false)):
		path_trace.append({"advance_detail": advance})
		_finish()
		return

	check(str(campaign.current_node().get("kind", "")) == "INTERACTIVE_DIALOGUE", "cursor_is_dialogue")
	check(str(campaign.current_node().get("id", "")) == dialogue_id, "cursor_accord")

	## Battle receipts must be authentic for durable restore.
	for nid in earned:
		var receipt: Dictionary = campaign.progress.routes[route_id].receipts.get(nid, {})
		check(int(receipt.get("winner", 0)) == 1, "receipt_win:" + str(nid))
		check(bool(receipt.get("objective_evidence", {}).get("stock_win", false)), "receipt_stock_win:" + str(nid))
		check(str(receipt.get("token", "")) != "", "receipt_token:" + str(nid))

	var ack: Dictionary = Prefix.acknowledge_and_reload(campaign, dialogue_id, route_id)
	check(bool(ack.get("ok", false)), "dialogue_durable_after_earned_prefix")
	check(bool(ack.get("durable_after_reload", false)), "reload_keeps_accord")
	check(dialogue_id in campaign.progress.routes[route_id].completed, "accord_in_completed")
	check(str(campaign.current_node().get("id", "")) == "kaia-windrow:catastrophe", "advanced_past_accord")
	path_trace.append({
		"path": "dialogue_after_earned_prefix",
		"dialogue_id": dialogue_id,
		"durable": true,
		"owner_sign_off": false,
		"human_playthrough": false,
	})

	## Closed-boundary forge rejection on next STOCK_WIN-capable battle would require
	## cosmic setup assets; instead re-bind a prologue-style encounter via replay of
	## an earned battle and prove _active=true cannot mint a stock_win.
	var replay_id := "kaia-windrow:prologue"
	check(campaign.begin_encounter(replay_id), "begin_replay_prologue_for_forge")
	if not campaign.active_encounter.is_empty():
		router.go("battle")
		check(await Prefix.wait_route(self, "BattleScene.tscn"), "battle_for_forge_check")
		var battle = current_scene
		for _i in range(120):
			await process_frame
			if campaign._battle_producer == battle:
				break
		check(campaign._battle_producer == battle, "forge_battle_bound")
		if campaign._battle_producer == battle:
			battle.set("_active", true)
			var tok := str(campaign.active_encounter.get("token", ""))
			check(not campaign.record_battle_result(1, tok, {"stock_win": true}, battle), "active_forge_rejected")
			battle.set("_active", false)
			## Replay wins never advance; closed inactive boundary still accepts owner result.
			check(campaign.record_battle_result(1, tok, {"stock_win": true}, battle), "inactive_replay_result_accepted")
			check(not bool(campaign.last_result.get("advanced", true)), "replay_does_not_advance")
			path_trace.append({"honesty": "active_battle_cannot_forge_stock_win; replay inactive accepted without advance"})

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"path_trace": path_trace,
		"scope": "Kaia earned STOCK_WIN prefix via bound BattleScene producer, then durable accord dialogue. Staged fixture ≠ owner sign-off / V1.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"owner_sign_off": false,
		"req_id": "AA-RTM-002",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("STORY_EARNED_PREFIX_DIALOGUE_AUTHORITY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("STORY_EARNED_PREFIX_DIALOGUE_AUTHORITY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " path=", path_trace.size())
	quit(0 if failures.is_empty() else 1)
