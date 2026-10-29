extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Expanded stage registry + first playable batch smoke.
## Builds original procedural geometry via StageManager, verifies spawn/collision,
## then runs a short 1v1 training combat on titans-divide. Pending stages stay
## honest REGISTERED_PENDING. Not V1 / human art / RC2.

var result_evidence: Dictionary = {}

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated replay profile required"); quit(2); return

	var StageManager = load("res://scripts/battle/stage_manager.gd")
	check(StageManager != null and StageManager.can_instantiate(), "stage_manager_loads")
	var manager = StageManager.new()
	var summary: Dictionary = manager.load_registry()
	check(bool(summary.get("canonical_launch_preserved", false)), "canonical_launch_preserved")
	check(int(summary.get("expanded_count", 0)) == 30, "expanded_30_registered")
	var playable: Array = summary.get("playable_expanded", [])
	check(playable.size() >= 5, "batch1_at_least_5_playable")
	check(playable.size() >= 10, "batch2_at_least_10_playable_authored_or_procedural")
	for need in ["the-concord-guildhall", "hermits-tide-retreat", "celestial-observatory", "the-infinity-chamber", "the-convergence-tournament-grounds"]:
		check(need in playable, "batch2_playable:" + need)
	check(not bool(summary.get("HUMAN_ART_APPROVED", true)), "human_art_gate_false")
	check(not bool(summary.get("RC2_READY", true)), "rc2_gate_false")
	check(not bool(summary.get("V1_0_0_RELEASE_AUTHORIZED", true)), "v1_gate_false")

	var pending: Array = summary.get("registered_pending", [])
	check(pending.size() == 30 - playable.size(), "pending_count_honest")
	if pending.size() > 0:
		var refused: Dictionary = manager.build_stage(Node2D.new(), str(pending[0]), true, "competitive")
		check(not bool(refused.get("ok", true)), "pending_stage_refuses_playable_build")
		check(str(refused.get("reason", "")) == "registered_pending_not_playable", "pending_reason_honest")

	for stage_id in playable:
		var stage_root := Node2D.new()
		stage_root.name = "StageRoot_%s" % stage_id
		root.add_child(stage_root)
		var built: Dictionary = manager.build_stage(stage_root, str(stage_id), true, "competitive")
		check(bool(built.get("ok", false)), "build_ok:" + str(stage_id))
		var prod_status := str(built.get("productionStatus", ""))
		check(prod_status.begins_with("PLAYABLE"), "status_playable:" + str(stage_id))
		if str(stage_id) in ["the-concord-guildhall", "hermits-tide-retreat", "celestial-observatory", "the-infinity-chamber", "the-convergence-tournament-grounds"]:
			check(prod_status.find("AUTHORED") >= 0 or prod_status.find("BATCH2") >= 0, "batch2_authored_status:" + str(stage_id))
			var main: Dictionary = built.get("main_platform", {})
			check(float(main.get("width", 900)) != 900.0, "batch2_not_uniform_stub_width:" + str(stage_id))
			check(int((built.get("spawn_points", []) as Array).size()) >= 2, "batch2_spawns:" + str(stage_id))
		var spawns: Array = built.get("spawn_points", [])
		check(spawns.size() >= 2, "spawns:" + str(stage_id))
		var bodies := 0
		for child in stage_root.get_children():
			if child is StaticBody2D:
				bodies += 1
		check(bodies >= 1, "collision_platforms:" + str(stage_id))
		check(stage_root.has_meta("yin_yang_presence") or stage_root.get_node_or_null("YinYangPinkPresence") != null, "yin_yang_presence:" + str(stage_id))
		var hazards: Array = built.get("hazard_snapshot", [])
		for hz in hazards:
			check(bool(hz.get("deterministic", false)), "hazard_deterministic:" + str(stage_id))
		# Competitive last-horizon must keep hazards off.
		if str(stage_id) == "the-last-horizon":
			check(hazards.is_empty() and not bool(built.get("hazards_enabled", true)), "last_horizon_competitive_no_hazards")
		stage_root.queue_free()
		await process_frame

	# Live 1v1 training combat smoke on Titans' Divide.
	var gs = root.get_node("GameState")
	gs.begin_training()
	gs.p1_fighter_id = "kaia-windrow"
	gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = "female"
	gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"
	gs.stage_id = "titans-divide"
	root.get_node("SceneRouter").go("training_battle")
	for i in range(180):
		await process_frame
		if route_is("TrainingBattleScene.tscn"):
			break
	check(route_is("TrainingBattleScene.tscn"), "training_loads_titans_divide")
	if not route_is("TrainingBattleScene.tscn"):
		finish(); return
	battle = current_scene
	await frames(90)
	check(is_instance_valid(battle.fighter1) and is_instance_valid(battle.fighter2), "fighters_spawned")
	var p = battle.fighter1
	var d = battle.fighter2
	check(p != null and d != null, "actors_present")
	var spawn_gap := absf(p.global_position.x - d.global_position.x)
	check(spawn_gap > 40.0, "spawn_separation")
	keys(["attack"])
	await frames(4)
	keys([])
	await frames(30)
	check(p.move_runner != null, "move_runner_bound")
	result_evidence = {
		"playable": playable,
		"pending_count": pending.size(),
		"stage_id": "titans-divide",
		"p1": p.fighter_id if p else "",
		"p2": d.fighter_id if d else "",
		"spawn_gap": spawn_gap,
	}
	finish()

func finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"evidence": result_evidence,
		"scope": "Expanded 30-stage registry + batch1 procedural playable build/spawn + titans-divide 1v1 training smoke. Not V1/human art/RC2.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("EXPANDED_STAGE_LOAD_SMOKE.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(result, "\t"))
	quit(0 if failures.is_empty() else 1)
