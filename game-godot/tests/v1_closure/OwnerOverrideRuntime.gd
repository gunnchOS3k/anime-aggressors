extends SceneTree
var failures: Array[String] = []
var encounters: Array = []
var watch_rows: Array = []
func _init() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func _run() -> void:
	var campaign = root.get_node("CampaignRuntime")
	var state = root.get_node("GameState")
	var router = root.get_node("SceneRouter")
	campaign.save_path = "/private/tmp/anime-override-runtime-test.json"
	check(campaign.reset_campaign(), "isolated_new_save")
	state.battle_eval_mode = true
	state.battle_eval_max_frames = 100000000
	for fid in campaign.campaign["spectral_order"]:
		check(campaign.select_route(fid), "review_route_" + fid)
		# Opening runtime paths were proved at the preceding checkpoint. Seed their receipts,
		# do not claim this setup as a new playthrough of those seven fights.
		for opening in range(7):
			check(campaign.begin_encounter(), "seed_existing_opening")
			check(campaign.record_battle_result(1, str(campaign.active_encounter["token"])), "seed_receipt")
		check(campaign.acknowledge_scene(), "accord_" + fid)
		check(campaign.acknowledge_scene(), "catastrophe_" + fid)
		check(campaign.begin_encounter(), "survival_begin_" + fid)
		check(not campaign.record_battle_result(1, str(campaign.active_encounter["token"])), "stock_win_cannot_forge_survival")
		router.go("battle")
		await frames(12)
		var battle = current_scene
		check(battle._story_cosmic_actor.fighter_id == "yang" and battle.fighter2.fighter_id == "yin", "both_cosmic_actors")
		check(battle._battle_sim.fighters.size() == 3, "three_combat_actors")
		var p = battle.fighter1
		p.cpu.clear_simulated_inputs()
		p.is_cpu = false
		p.dummy_mode = "idle"
		Input.action_press("p1_right")
		var x: float = p.position.x
		await frames(10)
		Input.action_release("p1_right")
		check(p.position.x != x, "survival_human_movement_" + fid)
		var boss = battle.fighter2
		var before: float = boss.damage_percent
		p.training_play_move("heavy_attack", 0.0, 1)
		await frames(15)
		p.hit_resolver.resolve(p, boss, p._current_move, 0.0)
		check(boss.damage_percent == before, "story_manifestation_rejects_damage")
		p.position = boss.position + Vector2(-10, 0)
		p._try_grab_connect()
		check(p.grabbed_target == null, "cosmic_contract_rejects_grab")
		# Staged survival plumbing proof: invulnerability keeps the scripted actor alive.
		# Normal gameplay damage/stock-loss remains enabled outside this test.
		p.invincible = true
		p.controls_enabled = false
		p.set_physics_process(false)
		p.position = Vector2(0, 160)
		await frames(1450)
		check(campaign.last_result.get("advanced", false), "survival_receipt_" + fid)
		check(campaign.last_result.get("objective_evidence", {}).get("survived", false), "elapsed_evidence_" + fid)
		check(current_scene.scene_file_path.ends_with("ResultsScene.tscn"), "survival_shipping_results")
		campaign.load_progress()
		check(campaign.current_node().get("id", "").ends_with("first_loss"), "resume_at_first_loss")
		if fid == "kaia-windrow":
			check(campaign.acknowledge_scene(), "canonical_rook_loss_scene")
			check(campaign.progress["routes"][fid]["essence"] == 1, "first_essence_saved")
			campaign.load_progress()
			check(campaign.progress["routes"][fid]["essence"] == 1, "first_essence_resumed")
		else:
			check(not campaign.acknowledge_scene(), "open_loss_blocks_progress_" + fid)
			check(campaign.current_node().get("first_loss") == null, "no_canon_choice_" + fid)
		encounters.append({"route":fid, "both_bosses":true, "real_elapsed_seconds":24, "save_resume":true, "staged_invulnerable_physics_frozen_test_actor":true, "human_playthrough":false})
		campaign.abandon_encounter()
	check(campaign.progress["gray_routes"].is_empty() and not campaign.progress["yin_unlocked"] and not campaign.progress["yang_unlocked"], "no_premature_unlock")
	var saved := JSON.stringify(campaign.progress)
	for fid in campaign.campaign["spectral_order"]:
		campaign.watch_route_id = fid
		campaign.watch_presentation = "female"
		var mode_before: String = state.mode
		router.go("ova")
		await frames(20)
		var watch = current_scene
		check(watch.route["anchor"] == fid, "watch_anchor_" + fid)
		check(watch.route["watch_role"] == ("PRIMARY_OVA" if fid == "kaia-windrow" else "CAMPAIGN_VARIATION"), "watch_naming_" + fid)
		check(watch._battle.fighter1.fighter_id == fid, "shared_runtime_actor")
		watch._toggle_pause()
		var elapsed: float = watch.elapsed
		await frames(8)
		check(watch.elapsed == elapsed, "pause_watch_clock")
		await watch.seek(8)
		await frames(10)
		check(watch._battle.fighter1.model_3d.get("_expression_controller").expression == "shock", "cinematic_facial_state")
		await watch.seek(19)
		check(not watch.playing and watch._battle == null, "watch_stops_at_first_block")
		check(watch.node_index == (11 if fid == "kaia-windrow" else 10), "watch_cannot_skip_block")
		router.go("story")
		await frames(8)
		check(JSON.stringify(campaign.progress) == saved, "watch_does_not_write_story")
		check(state.mode == mode_before, "watch_restores_game_mode")
		watch_rows.append({"route":fid, "shared_graph_and_runtime":true, "pause_seek_return":true, "stops_at_unimplemented_or_open_canon":true, "progress_untouched":true, "full_ova_complete":false})
	var output := FileAccess.open("res://../artifacts/v1_closure/owner_override_runtime_evidence.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"ok":failures.is_empty(), "failures":failures, "encounters":encounters, "watch_modes":watch_rows, "scope":"Seven real BattleScene 24-second two-boss survival paths with staged invulnerable, physics-frozen player; Kaia canonical First Loss/Essence save; six open canon stops; seven shared-graph watch previews. Not human playthrough/full campaign/finished OVA.", "owner_approved":false}, "  ")+"\n")
	output.close()
	print("OWNER_OVERRIDE_RUNTIME ", failures.is_empty(), " encounters=", encounters.size(), " watch=", watch_rows.size())
	quit(0 if failures.is_empty() else 1)
