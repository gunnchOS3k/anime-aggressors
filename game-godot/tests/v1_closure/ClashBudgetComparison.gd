extends SceneTree
## Identical native resolver stress for legacy/current script count comparison.
## No pixel, device-loudness or ordinary-player acceptance claim.
var output := ""
var rows: Array = []
func _init() -> void: call_deferred("run")
func one_shots() -> int:
	var count := 0
	for node in root.find_children("*", "AudioStreamPlayer", true, false):
		if node.playing and not node.is_queued_for_deletion() and node.get_meta("audio_category", "sfx") != "music":
			if node.get_parent().name == "ProceduralAudioPlayers" or node.get_parent().name == "SpectralFeedback": count += 1
	return count
func run() -> void:
	create_timer(45).timeout.connect(func(): quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	var gs = root.get_node("GameState"); gs.mode = "versus"; gs.stage_id = "training-grid"; gs.p1_fighter_id = "kaia-windrow"; gs.p2_fighter_id = "juno-spark"; gs.p2_is_cpu = false; gs.stocks = 9
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	var p = current_scene.fighter1; var d = current_scene.fighter2
	p.controls_enabled = false; d.controls_enabled = false
	var renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(p)
	for mode in ["Full", "Balanced", "Reduced"]:
		root.get_node("StoryDialogue").set_option("vfx_intensity", mode)
		p.projectile_spawner.clear_all(); d.projectile_spawner.clear_all(); renderer._process(1.0)
		for i in range(45): await physics_frame
		var sim = preload("res://scripts/combat/projectile_interactions.gd").new()
		var before := one_shots()
		for i in range(12):
			for actor in [p, d]:
				var shot = actor.projectile_spawner.spawn_from_move(preload("res://scripts/data/data_loader.gd").find_move(actor.move_manifest, "neutral_special_projectile"), 0)
				shot.global_position = Vector2((i % 4 - 1.5) * 26, 250 + (i / 4) * 12); shot.spawn_bounds = shot.world_bounds()
			sim.begin_frame([p, d]); sim.resolve_frame([p, d])
		rows.append({"mode": mode, "confirmed_events": sim.history.size(), "active_meshes": renderer.active_count(), "new_same_frame_one_shot_players": one_shots() - before, "authoritative_results": sim.history, "scope": "12 real native resolver contacts at explicit stress positions; legacy script overlay uses current shader for count-only comparison, not a historical movie"})
	p.projectile_spawner.clear_all(); d.projectile_spawner.clear_all()
	var f = FileAccess.open(output.path_join("clash_budget_comparison.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows": rows, "scope": "mesh/one-shot node counts, not acoustic loudness or sustained performance"}, "  ")); f.close()
	print("CLASH_BUDGET_COMPARISON_COMPLETE rows=", rows.size()); quit()
