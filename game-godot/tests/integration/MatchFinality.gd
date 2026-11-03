extends SceneTree
## Actual BattleScene actors with an injected match-end boundary. Technical
## lifecycle regression only: no earned KO, ordinary-play or visual acceptance.
var output := ""
var checks: Array = []
var failures: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks.append({"check":label,"pass":value})
	if not value: failures.append(label)

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.trim_prefix("--ordinary-output=")
	if not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile");quit(2);return
	var gs = root.get_node("GameState")
	var telemetry = root.get_node("MatchTelemetry")
	gs.mode="versus";gs.stage_id="training-grid"
	gs.p1_fighter_id="kaia-windrow";gs.p2_fighter_id="juno-spark"
	gs.p1_is_cpu=false;gs.p2_is_cpu=true;gs.cpu_level=3
	root.get_node("SceneRouter").go("battle")
	for i in range(360):
		await physics_frame
		if current_scene != null and "fighter1" in current_scene and current_scene._active: break
	var battle = current_scene
	check(battle != null and "fighter1" in battle and battle._active,"actual_battle_activated")
	if not checks[-1].pass: finish();return
	var p=battle.fighter1;var d=battle.fighter2
	# Deliberate boundary fixtures: live projectile, buffered attack and held CPU
	# input. These exercise teardown, never simulate an earned combat result.
	var move: Dictionary=p.move_manifest.moves.filter(func(m):return m.has("projectile"))[0].duplicate(true)
	var shot=p.projectile_spawner.spawn_from_move(move,0)
	p.move_runner.start_move(p.move_manifest.moves[0],p)
	d.queue_attack_command("attack_forward")
	Input.action_press("p2_right");Input.action_press("p2_shield")
	var matches_before: int=gs.career_matches
	battle._finish_match(1)
	check(not battle._active,"coordinator_stopped")
	check(not p.controls_enabled and not d.controls_enabled,"both_controls_closed")
	check(battle._battle_sim.paused,"simulation_stopped")
	check(not p.move_runner.active and not d.move_runner.active,"moves_cancelled")
	check(p.state_machine.current_state=="victory" and d.state_machine.current_state=="defeat","terminal_acting_selected")
	check(d._pending_attack_cmd.is_empty(),"buffered_attack_cleared")
	check(not Input.is_action_pressed("p2_right") and not Input.is_action_pressed("p2_shield"),"cpu_inputs_released")
	check(not shot.active and p.projectile_spawner.count()==0,"projectile_authority_retired")
	d.queue_attack_command("attack_forward")
	check(d._pending_attack_cmd.is_empty(),"late_attack_queue_rejected")
	var prior: float=d.damage_percent
	var late: Dictionary=move.duplicate(true);late["_from_projectile"]=true
	check(p.hit_resolver.resolve(p,d,late,p.damage_percent).is_empty(),"late_contact_rejected")
	d.receive_hit(p,{"damage":5.0,"launch":Vector2.ZERO,"move_id":"jab_1"})
	check(d.damage_percent==prior,"late_damage_rejected")
	battle._finish_match(2)
	check(gs.last_winner_slot==1,"first_result_retained")
	check(telemetry.count_of("match_end")==1,"one_match_end_event")
	check(gs.career_matches==matches_before+1,"one_career_result")
	check(battle.countdown_label.visible and battle.countdown_label.text.contains("Kaia"),"immediate_winner_banner")
	for i in range(60):
		await physics_frame
		if current_scene != null and current_scene.scene_file_path.ends_with("ResultsScene.tscn"): break
	check(current_scene != null and current_scene.scene_file_path.ends_with("ResultsScene.tscn"),"results_route_loaded")
	if current_scene != null and current_scene.scene_file_path.ends_with("ResultsScene.tscn"):
		var results=current_scene
		check(results.title_label.text.contains("Kaia"),"results_show_original_winner")
		# Signal-driven UI lifecycle check; native public-input acceptance is separate.
		results.rematch_btn.pressed.emit()
		for i in range(360):
			await physics_frame
			if current_scene != null and "fighter1" in current_scene and current_scene._active: break
		var rematch=current_scene
		check(rematch != null and "fighter1" in rematch and rematch._active,"rematch_activated")
		if rematch != null and "fighter1" in rematch:
			check(rematch.fighter1.controls_enabled and rematch.fighter2.controls_enabled,"rematch_controls_restored")
			check(rematch.fighter1.damage_percent==0 and rematch.fighter2.damage_percent==0,"rematch_damage_reset")
			check(gs.last_winner_slot==-1,"rematch_result_reset")
			rematch._on_pause_return_menu()
			for i in range(3):await process_frame
			check(current_scene != null and current_scene.scene_file_path.ends_with("MainMenuScene.tscn"),"return_to_menu")
	finish()

func finish() -> void:
	for suffix in ["left","right","shield","attack"]:Input.action_release("p2_"+suffix)
	var result={"scope":"Injected match-end boundary with actual actors and UI signals; not earned KO, native gameplay or visual acceptance","checks":checks,"failures":failures,"PASS":failures.is_empty()}
	if not output.is_empty():
		var f=FileAccess.open(output.path_join("MATCH_FINALITY.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify(result,"  "));f.close()
	print("MATCH_FINALITY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
