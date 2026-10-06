extends SceneTree

var failures: Array[String] = []
var rows: Array = []


func _init() -> void:
	call_deferred("_run")


func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		push_error(label)


func _run() -> void:
	var campaign = root.get_node("CampaignRuntime")
	var state = root.get_node("GameState")
	campaign.save_path = "/private/tmp/anime-v1-campaign-test.json"
	check(campaign.reset_campaign(), "new_campaign_save")
	check(not campaign.acknowledge_scene(), "menu_cannot_complete_battle")
	check(not campaign.route_available("sevenfold-convergence"), "convergence_locked")
	state.battle_eval_mode = true  # Skip countdown; preserve BattleScene combat/KO/results code.
	state.battle_eval_max_frames = 100000
	for route_id in campaign.campaign["spectral_order"]:
		check(campaign.select_route(str(route_id)), "select_route_" + str(route_id))
		for chapter in range(7):
			var node: Dictionary = campaign.current_node()
			check(campaign.begin_encounter(), "begin_" + str(node["id"]))
			check(not campaign.record_battle_result(1, "wrong_token"), "reject_stale_result")
			root.get_node("SceneRouter").go("battle")
			for _frame in range(10):
				await physics_frame
			var battle = current_scene
			check(battle != null and battle.has_method("_check_match_end"), "shipping_battlescene")
			if battle == null or not battle.has_method("_check_match_end"):
				quit(1)
				return
			check(battle.fighter1.fighter_id == route_id, "anchor_identity")
			check(battle.fighter2.fighter_id == node["opponent"], "opponent_identity")
			var x: float = battle.fighter1.position.x
			Input.action_press("p1_right")
			for _frame in range(12):
				await physics_frame
			Input.action_release("p1_right")
			check(battle.fighter1.position.x != x, "actual_movement_" + str(node["id"]))
			# Scripted blast-zone setup exercises actual stock loss and the shipping result transition.
			# This proves plumbing; it is NOT a human campaign playthrough or taste approval.
			battle.fighter2.controls_enabled = false
			battle.fighter2.stocks = 1
			battle.fighter2.position.x = float(battle.blast.get("right", 2000)) + 100
			for _frame in range(90):
				await physics_frame
			check(campaign.last_result.get("advanced", false), "recorded_win_" + str(node["id"]))
			check(current_scene != null and current_scene.scene_file_path.ends_with("ResultsScene.tscn"), "shipping_results")
			check(not campaign.record_battle_result(1, str(campaign.last_result.get("token", ""))), "idempotent_result")
			if current_scene != null and current_scene.has_method("_on_rematch_pressed"):
				current_scene._on_rematch_pressed()
				for _frame in range(4):
					await process_frame
			check(current_scene != null and current_scene.scene_file_path.ends_with("StoryCampaignScene.tscn"), "story_return")
			campaign.load_progress()
			check(str(node["id"]) in campaign.progress["routes"][route_id]["completed"], "save_resume_" + str(node["id"]))
			rows.append({"route": route_id, "node": node["id"], "opponent": node["opponent"],
				"shipping_scene": true, "scripted_movement": true, "scripted_blast_KO": true,
				"save_resume": true, "human_playthrough": false})
		check(campaign.acknowledge_scene(), "accord_scene")
		check(not campaign.begin_encounter(), "technical_block_is_not_completion")
		check(not campaign.progress["routes"][route_id]["complete"], "incomplete_route_truth")
		var completed: Array = campaign.progress["routes"][route_id]["completed"].duplicate()
		check(campaign.begin_encounter(str(completed[0])), "chapter_replay")
		var token := str(campaign.active_encounter["token"])
		check(campaign.record_battle_result(2, token), "loss_receipt")
		check(campaign.progress["routes"][route_id]["completed"] == completed, "loss_does_not_advance")
		check(campaign.begin_encounter(str(completed[0])), "replay_retry")
		check(campaign.record_battle_result(1, str(campaign.active_encounter["token"])), "replay_win")
		check(campaign.progress["routes"][route_id]["completed"] == completed, "replay_does_not_advance")
		campaign.abandon_encounter()
	check(not campaign.progress["yin_unlocked"] and not campaign.progress["yang_unlocked"], "cosmic_unlocks_remain_locked")
	# Malformed save and forged future completion cannot grant Gray or cosmic unlocks.
	var file := FileAccess.open(campaign.save_path, FileAccess.WRITE)
	file.store_string('{"schema":"anime_v1.progress.v1","routes":[],"gray_routes":["fake"],"yin_unlocked":true}')
	file.close()
	campaign.load_progress()
	check(campaign.progress["gray_routes"].is_empty() and not campaign.progress["yin_unlocked"], "reject_forged_save")
	var out := FileAccess.open("res://../artifacts/v1_closure/campaign_runtime_evidence.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"ok": failures.is_empty(), "failures": failures, "encounters": rows,
		"scope": "Shipping BattleScene movement + scripted blast-zone KO + Results/Story save flow; later story objectives remain unimplemented.",
		"automated_ready": false, "STORY_HUMAN_PASS": false}, "\t"))
	out.close()
	print("CAMPAIGN_CHECKPOINT ", "PASS" if failures.is_empty() else "FAIL", " encounters=", rows.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
