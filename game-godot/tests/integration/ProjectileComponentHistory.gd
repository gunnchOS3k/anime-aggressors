extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## Actual ordinary-input shots, then explicitly isolated production component
## transactions. Fighter/PhysicsServer state is NOT rewound or resimulated.
const Interaction = preload("res://scripts/combat/projectile_interactions.gd")
const ROSTER = ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx", "yin", "yang"]
var rows: Array = []
var lifecycle: Array = []

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated projectile component profile required"); quit(2); return
	var story_before := JSON.stringify(root.get_node("CampaignRuntime").progress)
	var epoch := 0
	for fighter in ROSTER:
		for body in ["male", "female"]:
			epoch += 1
			await probe(fighter, body, epoch)
	check(JSON.stringify(root.get_node("CampaignRuntime").progress) == story_before, "component_testing_never_earns_or_modifies_Story")
	finish()

func probe(fid: String, body: String, epoch: int) -> void:
	keys([])
	var gs = root.get_node("GameState")
	gs.begin_training(); gs.p1_fighter_id = fid; gs.p2_fighter_id = "juno-spark"
	gs.p1_body_variant = body; gs.p2_body_variant = "male"
	gs.training_dummy_mode = "idle"; gs.stage_id = "training-grid"
	var previous = current_scene
	root.get_node("SceneRouter").go("training_battle")
	for i in range(180):
		await process_frame
		if current_scene != previous and route_is("TrainingBattleScene.tscn"): break
	check(current_scene != previous and route_is("TrainingBattleScene.tscn"), fid + body + ":actual_Training_scene")
	if current_scene == previous or not route_is("TrainingBattleScene.tscn"): return
	battle = current_scene
	await frames(120)
	var p = battle.fighter1; var d = battle.fighter2
	check(p.fighter_id == fid and p.model_3d.get_body_variant() == body, fid + body + ":actual_owner_body_identity")
	var spawner = p.projectile_spawner
	check(spawner.begin_network_component_history(epoch, battle._battle_sim), fid + body + ":explicit_history_opt_in")
	# Real normal gameplay input is the source of the first shot. No damage,
	# positions, aura, hitstun, collision or attack definitions are modified.
	keys(["special"]); await frames(2); keys([])
	for i in range(100):
		if spawner.count() > 0: break
		await physics_frame
	check(spawner.count() == 1, fid + body + ":public_Special_spawned_one_real_shot")
	if spawner.count() != 1: spawner.end_network_component_history(); return
	var shot = spawner.active_projectiles[0]
	var first_id: int = shot.get_instance_id()
	# From this point this is explicitly a component fixture: freeze actor
	# clocks and BattleSim, but retain the real nodes/skins/PhysicsServer.
	# Direct shot steps compare component motion, NOT world combat replay.
	battle._battle_sim.set_paused(true)
	p.set_physics_process(false); d.set_physics_process(false)
	await process_frame
	var contact_count := contacts.size()
	var victim_damage: float = d.damage_percent
	lifecycle.clear()
	spawner.projectile_spawned.connect(func(_shot): lifecycle.append("spawn"))
	shot.projectile_expired.connect(func(): lifecycle.append("expired"))
	shot.projectile_hit.connect(func(_target, _info): lifecycle.append("hit"))
	var source: Dictionary = spawner.capture_network_component(epoch, 1)
	check(source.get("shots", []).size() == 1, fid + body + ":actual_resolved_shot_captured")
	if source.is_empty(): spawner.end_network_component_history(); return
	var recorded_move := str(shot.move_id)
	var original_audio_count: int = shot._elemental_audio.events.size()
	var replay: Array = []
	for i in range(6):
		shot.tick_sim_frame()
		replay.append(shot.capture_network_component())
	check(spawner.restore_network_component(source), fid + body + ":retained_shot_silent_component_restore")
	var equal := true
	for i in range(6):
		shot.tick_sim_frame()
		equal = equal and shot.capture_network_component() == replay[i]
	check(equal and shot.get_instance_id() == first_id, fid + body + ":actual_motion_replay_preserves_node_identity")
	check(lifecycle.is_empty() and shot._elemental_audio.events.size() == original_audio_count, fid + body + ":restore_and_short_replay_emit_no_lifecycle_or_launch_audio")
	# Original expiration is real, but rollback restore must not emit another
	# expiration/spawn/impact, or run configure() a second time.
	shot.cancel_immediate()
	check(not shot.active and not shot.is_queued_for_deletion() and spawner.count() == 0, fid + body + ":expired_shot_retained_outside_active_registry")
	var events_before: Array = lifecycle.duplicate()
	check(spawner.restore_network_component(source), fid + body + ":expired_node_revived_without_respawn")
	await process_frame
	check(shot.active and shot.monitoring and shot.get_instance_id() == first_id, fid + body + ":old_deferred_retirement_cannot_disable_revived_Area")
	check(lifecycle == events_before and shot._elemental_audio.events.size() == original_audio_count and not shot._elemental_audio.travel.playing, fid + body + ":silent_restore_does_not_replay_sound_or_events")
	# One staged production spawn is ONLY for transaction atomicity and spawn
	# serial invalidation. It is not presented as another player input/hit.
	var staged = spawner.spawn_from_move(shot.move_data, p.aura)
	var staged_id: int = staged.get_instance_id()
	var two: Dictionary = spawner.capture_network_component(epoch, 2)
	var malformed: Dictionary = two.duplicate(true)
	malformed.shots[1].state.damage = "invalid"
	var before: Dictionary = spawner.capture_network_component(epoch, 2)
	check(not spawner.restore_network_component(malformed) and spawner.capture_network_component(epoch, 2) == before, fid + body + ":invalid_second_shot_rejects_whole_transaction_atomically")
	malformed = two.duplicate(true); malformed.epoch = epoch + 1
	check(not spawner.restore_network_component(malformed) and spawner.capture_network_component(epoch, 2) == before, fid + body + ":foreign_epoch_cannot_restore_or_mutate")
	malformed = two.duplicate(true); malformed.owner = d.get_instance_id()
	check(not spawner.restore_network_component(malformed), fid + body + ":no_cross_fighter_ownership_transfer")
	events_before = lifecycle.duplicate()
	check(spawner.restore_network_component(source) and spawner.count() == 1 and not staged.active and staged.is_queued_for_deletion(), fid + body + ":discarded_future_shot_and_serial_retire_silently")
	check(lifecycle == events_before and not spawner.restore_network_component(two), fid + body + ":discarded_future_snapshot_cannot_be_restored")
	var isolated = Interaction.new()
	var interaction: Dictionary = battle._battle_sim.projectile_interactions.capture_network_component()
	check(not interaction.is_empty() and isolated.restore_network_component(interaction) and isolated.capture_network_component() == interaction, fid + body + ":closed_swept_manager_clock_and_history_restore_without_dispatch")
	isolated.starts[shot.order_id] = shot.world_bounds()
	check(isolated.capture_network_component().is_empty() and not isolated.restore_network_component(interaction), fid + body + ":open_swept_phase_cannot_be_restored")
	check(shot.pending_targets == source.shots[0].state.pending_targets and shot.hit_targets == source.shots[0].state.hit_targets, fid + body + ":target_ledgers_restore_exactly")
	check(contacts.size() == contact_count and d.damage_percent == victim_damage, fid + body + ":component_fixture_never_fabricates_combat_damage")
	shot.cancel_immediate()
	check(spawner.prune_network_component_history(2) and not spawner.restore_network_component(source), fid + body + ":history_floor_retires_old_snapshot")
	await process_frame
	check(not is_instance_id_valid(first_id) and not is_instance_id_valid(staged_id), fid + body + ":expired_and_discarded_nodes_freed_after_history_pruning")
	spawner.end_network_component_history()
	rows.append({"fighter":fid, "body":body, "facing":p.facing, "epoch":epoch, "move":recorded_move,
		"actual_public_shot":true, "staged_extra_shot_for_atomicity":true, "component_motion_steps":6,
		"historical_world_restore":false, "full_combat_rollback":false, "native_visual_acceptance":false})

func finish() -> void:
	keys([])
	var result = {"PASS":failures.is_empty(), "checks":checks, "failures":failures, "rows":rows,
		"scope":"Real ordinary-input nine-fighter/two-body projectile acquisition, then isolated retained-node silent component restore, atomic validation, callback ABA rejection, six-step motion replay and pruning. One explicitly staged extra shot per row tests transaction rejection. No CharacterBody/world restoration, delayed-input combat, damage replay, audiovisual idempotence, visual/art or device acceptance.",
		"HUMAN_ART_APPROVED":false, "RUNTIME_PAIRED_CONTACT_VERIFIED":false, "RC2_READY":false, "V1_0_0_RELEASE_AUTHORIZED":false}
	var file = FileAccess.open(output.path_join("PROJECTILE_COMPONENT_HISTORY.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ")); file.close()
	print("PROJECTILE_COMPONENT_HISTORY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " rows=", rows.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
