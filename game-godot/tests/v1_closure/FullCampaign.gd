extends SceneTree

## Staged source-scene automation: real controls, collision/hit receipts and BattleScene KOs.
## Position/KO/contact setup is explicit. This is never a human playthrough or exported proof.
var failures: Array = []
var rows: Array = []
var campaign
var state
var router
var battle
var ground_y := 300.0
var save_path := "/private/tmp/anime-full-campaign-v2.json"

func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func _run() -> void:
	campaign = root.get_node("CampaignRuntime")
	state = root.get_node("GameState")
	router = root.get_node("SceneRouter")
	campaign.save_path = save_path
	state.battle_eval_mode = false
	check(campaign.reset_campaign(), "new_signed_save")
	check(campaign.validate_canon(), "approved_unique_canon")
	check(not campaign.acknowledge_scene(), "menu_cannot_finish_battle")
	check(not campaign.route_available("sevenfold-convergence"), "convergence_starts_locked")
	var order: Array = ["kaia-windrow"]
	for fid in campaign.campaign["spectral_order"]:
		if fid != "kaia-windrow": order.append(fid)
	order.append("sevenfold-convergence")
	for fid in order:
		check(campaign.select_route(fid), "legitimate_route_selection_" + fid)
		for i in range(campaign.route_data(fid)["nodes"].size()):
			var node: Dictionary = campaign.current_node()
			if node.is_empty(): check(false,"premature_route_end"); break
			print("EXERCISE ",node["id"])
			if node["kind"] == "INTERACTIVE_DIALOGUE":
				check(campaign.acknowledge_scene(), "scene_" + node["id"])
				rows.append({"node":node["id"], "kind":"scene", "shipping_ui_acknowledgment":true})
			else:
				check(campaign.begin_encounter(), "begin_" + node["id"])
				# Starting another encounter must not erase stored receipt dictionaries.
				for completed_id in campaign.progress["routes"][fid]["receipts"]:
					check(not campaign.progress["routes"][fid]["receipts"][completed_id].is_empty(), "receipt_survives_next_encounter_"+completed_id)
				check(not campaign.record_battle_result(1,str(campaign.active_encounter["token"]),{"stock_win":true}), "token_alone_cannot_mint_receipt")
				router.go("battle")
				await frames(5)
				root.get_node("StoryDialogue").skip_all() # public subtitle skip, staged regression
				await frames(230)
				battle = current_scene
				if battle == null or not battle.has_method("_check_match_end"):
					check(false,"shipping_scene_missing"); _output(); quit(1); return
				ground_y = float(state.load_stage(state.stage_id)["mainPlatform"]["y"])
				var p = battle.fighter1
				p.is_cpu = false
				p.dummy_mode = "idle"
				p.cpu.clear_simulated_inputs()
				p.invincible = true # Explicit staged protection of the automated test player.
				var x: float = p.position.x
				Input.action_press("p1_right")
				await frames(10)
				Input.action_release("p1_right")
				check(p.position.x != x,"actual_control_" + node["id"])
				if battle._story_objective != null:
					for actor in battle._story_objective.actors:
						if actor != p:
							actor.controls_enabled = false
							actor.is_cpu = false
							actor.dummy_mode = "idle"
							actor.cpu.clear_simulated_inputs()
							actor.set_physics_process(false)
							actor.position = Vector2(-300, ground_y-2)
				else:
					battle.fighter2.controls_enabled = false
				await _exercise(node)
				if is_instance_valid(battle) and battle._story_objective != null: print("OBJECTIVE_EVIDENCE ",battle._story_objective.evidence()," state=",battle.fighter1.state_machine.current_state," shielding=",battle.fighter1.shielding)
				await frames(40)
				check(campaign.last_result.get("advanced",false), "authenticated_result_" + node["id"])
				check(current_scene.scene_file_path.ends_with("ResultsScene.tscn"), "results_scene_" + node["id"])
				rows.append({"node":node["id"], "kind":"battle", "receipt":campaign.last_result.duplicate(true), "real_player_control":true, "staged_automation":true,"human_playthrough":false})
				if current_scene.has_method("_on_rematch_pressed"): current_scene._on_rematch_pressed()
				await frames(5)
				campaign.last_result.clear()
				check(campaign.save_progress(), "save_after_results_clear_"+node["id"])
			campaign.load_progress()
			check(node["id"] in campaign.progress["routes"][fid]["completed"],"signed_resume_" + node["id"])
			if not failures.is_empty(): _output(); quit(1); return
		check(campaign.progress["routes"][fid]["complete"],"route_complete_"+fid)
		if fid != "sevenfold-convergence": check(fid in campaign.progress["gray_routes"],"earned_gray_"+fid)
	check(campaign.progress["gray_routes"].size()==7,"seven_gray_completions")
	check(campaign.progress["yin_unlocked"] and campaign.progress["yang_unlocked"],"legitimate_cosmic_unlocks")
	check(rows.size()==145,"all_145_nodes_exercised")
	await _negative_and_replay()
	_output()
	quit(0 if failures.is_empty() else 1)

func _position(pos: Vector2) -> void:
	battle.fighter1.position = pos
	battle.fighter1.velocity = Vector2.ZERO
func _hold_at(pos: Vector2, n: int, shield: bool = true) -> void:
	if shield: Input.action_press("p1_shield")
	_position(Vector2(pos.x, float(state.load_stage(state.stage_id)["mainPlatform"]["y"]) - 1) if shield else pos)
	for i in range(n):
		if not is_instance_valid(battle) or not battle._active: break
		battle.fighter1.position.x = pos.x
		battle.fighter1.velocity.x = 0
		await physics_frame
	if shield: Input.action_release("p1_shield")
func _pulse(action: String, pos: Vector2) -> void:
	_position(pos)
	# Teleporting the staged fixture does not immediately update floor/action
	# state. Wait for genuine landing before issuing the short input pulse.
	for i in range(45):
		if battle.fighter1.is_on_floor() and battle.fighter1.state_machine.can_attack(): break
		await physics_frame
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(3)
func _stage_ko(actor) -> void:
	actor.stocks = 1
	actor.position = Vector2(float(battle.blast.get("right",2000))+100,180)
	await frames(55)
func _contact(actor) -> void:
	# Staged geometry; contact still passes through active move frames, overlap and HitResolver.
	actor.position = Vector2(20,ground_y-2)
	actor.invincible = false
	actor.damage_percent = 0
	actor.armor_frames_remaining = 0
	actor.shielding = false
	actor.move_runner.cancel()
	actor.state_machine.enter("idle")
	actor.aura = 0
	battle.fighter1.shielding = false
	battle.fighter1.state_machine.enter("idle")
	for attempt in range(12):
		if battle._story_objective.player_damage.get(actor.fighter_id,0) >= 40: break
		battle.fighter1.move_runner.cancel()
		battle.fighter1.training_play_move("heavy_attack",0.0,1)
		await _hold_at(Vector2(-25,ground_y-2),50,false)
	check(battle._story_objective.player_damage.get(actor.fighter_id,0)>=40,"real_contact_damage_"+actor.fighter_id)

func _exercise(node: Dictionary) -> void:
	var kind: String = node.get("objective_contract","STOCK_WIN")
	var o = battle._story_objective
	match kind:
		"STOCK_WIN": await _stage_ko(battle.fighter2)
		"COSMIC_SURVIVAL":
			battle.fighter1.set_physics_process(false)
			battle.fighter1.position = Vector2(0,180)
			await frames(1450)
		"FIRST_LOSS":
			match node["consequence"]["interaction"]:
				"LAST_VECTOR_ESCORT":
					await _pulse("p1_attack", Vector2(-140,ground_y-2))
					check(o.decision.is_empty(),"impulsive_attack_does_not_escort")
					check(o.escorts.size()==5,"five_remaining_team_actors")
					await _pulse("p1_shield", Vector2(-140,ground_y-2))
					await _hold_at(Vector2(80,ground_y-2),8,false)
					await _hold_at(Vector2(280,ground_y-2),8,false)
				"RESTRAINED_PROTECTION":
					await _hold_at(Vector2(-80,ground_y-2),155)
					await _hold_at(Vector2(220,ground_y-2),8,false)
				"SHARED_DEFENSE":
					await _hold_at(Vector2(180,ground_y-2),85)
					await _hold_at(Vector2(-180,ground_y-2),8,false)
				"OPEN_BOUNDARY":
					await _pulse("p1_special",Vector2(-220,ground_y-2))
					await _hold_at(Vector2(220,ground_y-2),8,false)
				"PERSONAL_VECTOR":
					await _hold_at(Vector2(100,ground_y-2),110)
					await _hold_at(Vector2(-200,ground_y-2),8,false)
				"HONEST_SIGNAL":
					await _pulse("p1_special",Vector2(0,ground_y-2))
					await _hold_at(Vector2(260,ground_y-2),8,false)
				"DECISIVE_INTERVENTION":
					await _pulse("p1_attack",Vector2(0,ground_y-2))
					await _hold_at(Vector2(240,ground_y-2),8,false)
			await frames(100) # Allow the visible First Loss aftermath beat to finish.
		"PUPPET_IMBALANCE":
			check(o.puppets.size()==5,"five_actual_puppets")
			check(o.evidence()["yin_count"]==3 and o.evidence()["yang_count"]==2,"actual_3v2")
			await _contact(o.puppets[0])
			await _hold_at(Vector2(0,ground_y-2),150)
		"FIRST_RELEASE":
			await _contact(o.puppets[1]) # A player chooses a non-default dominant-side target.
			await _pulse("p1_special",Vector2(20,ground_y-2))
		"PUPPET_EQUILIBRIUM":
			check(o.puppets.size()==4,"four_actual_puppets")
			await _hold_at(Vector2(0,ground_y-2),530)
		"PAIRED_RELEASE":
			var targets := []
			for side in ["yin","yang"]:
				for actor in o.puppets:
					if actor.get_meta("story_team")==side: targets.append(actor); break
			for actor in targets:
				await _contact(actor)
				await _pulse("p1_special",Vector2(20,ground_y-2))
		"PRISMATIC_TRANSFORMATION":
			check(campaign.progress["routes"][campaign.progress["selected_route"]]["essence"]==6,"six_distinct_essences")
			for i in range(6): await _hold_at(Vector2(-250+i*100,ground_y-2),5,false)
			await _hold_at(Vector2(250,ground_y-2),270)
			check(battle.fighter1.get_meta("story_form","")=="PRISMATIC_GRAY","actual_gray_model_selection")
		"GRAY_DEMONSTRATION":
			await _pulse("p1_attack",Vector2(0,ground_y-2))
			await _hold_at(Vector2(250,ground_y-2),1200)
		"SEVENFOLD_REUNION":
			check(o.actors.size()==7,"seven_gray_reunion_actors")
			for i in range(6): await _hold_at(Vector2(-250+i*100,ground_y-2),5,false)
		"SEVENFOLD_TRIAL":
			for i in range(7):
				check(battle.fighter1.fighter_id == campaign.campaign["spectral_order"][i], "trial_distinct_identity_" + str(i))
				var x: float = battle.fighter1.position.x
				Input.action_press("p1_right")
				await frames(8)
				Input.action_release("p1_right")
				check(battle.fighter1.position.x != x, "trial_player_control_" + str(i))
				battle.fighter2.set_physics_process(false)
				await _stage_ko(battle.fighter2)
				if i < 6: await frames(80)
		"SEVENFOLD_EQUILIBRIUM":
			for i in range(12):
				if o.alternations >= 6: break
				await _hold_at(Vector2(-180 if o.alternations%2==0 else 180,ground_y-2),90)
			check(o.alternations>=6,"six_actual_guard_alternations")
			await _hold_at(Vector2(0,ground_y-2),1250,false)

func _negative_and_replay() -> void:
	var pristine := FileAccess.get_file_as_string(save_path)
	check(campaign.select_route("kaia-windrow"),"select_complete_route_for_replay")
	var before := JSON.stringify(campaign.progress["routes"]["kaia-windrow"])
	check(campaign.begin_encounter("kaia-windrow:first_release"),"release_chapter_replay_entry")
	check(campaign.active_encounter["route_state"]["released"].is_empty() and campaign.active_encounter["route_state"]["essence"]==1 and campaign.active_encounter["route_state"]["form"]=="BASE","replay_reconstructs_chapter_past")
	campaign.abandon_encounter()
	check(campaign.begin_encounter("kaia-windrow:prologue"),"replay_entry")
	router.go("battle")
	await frames(5)
	root.get_node("StoryDialogue").skip_all()
	await frames(230)
	battle=current_scene
	await _stage_ko(battle.fighter1)
	await frames(40)
	check(campaign.last_result.get("winner")==2 and not campaign.last_result.get("advanced",true),"real_loss_replay_receipt")
	check(JSON.stringify(campaign.progress["routes"]["kaia-windrow"])==before,"loss_replay_preserves_progress")
	check(not campaign.record_battle_result(1,str(campaign.last_result.get("token",""))),"idempotent_receipt")
	var envelope: Dictionary=JSON.parse_string(pristine)
	envelope["payload"]=str(envelope["payload"]).replace('"essence":6','"essence":99')
	var file:=FileAccess.open(save_path,FileAccess.WRITE);file.store_string(JSON.stringify(envelope));file.close()
	campaign.load_progress()
	check(campaign.progress["gray_routes"].is_empty() and not campaign.progress["yin_unlocked"],"tampered_payload_cannot_unlock")
	file=FileAccess.open(save_path,FileAccess.WRITE);file.store_string('{"schema":"anime_v1.progress.v2","routes":[],"yin_unlocked":true}');file.close()
	campaign.load_progress()
	check(not campaign.progress["yin_unlocked"],"malformed_save_rejected")
	file=FileAccess.open(save_path,FileAccess.WRITE);file.store_string(pristine);file.close()
	campaign.load_progress()
	check(campaign.progress["yin_unlocked"] and campaign.progress["yang_unlocked"],"signed_unlock_resume")
	# A full debug/review completion must not yield ordinary unlocks after restart.
	for route_id in campaign.progress["routes"]:
		for node_id in campaign.progress["routes"][route_id]["receipts"]:
			campaign.progress["routes"][route_id]["receipts"][node_id]["qualifying"] = false
	check(campaign.save_progress(),"signed_review_fixture")
	campaign.load_progress()
	check(campaign.progress["gray_routes"].is_empty() and not campaign.progress["yin_unlocked"] and not campaign.progress["yang_unlocked"],"review_receipts_cannot_unlock")
	file=FileAccess.open(save_path,FileAccess.WRITE);file.store_string(pristine);file.close()
	campaign.load_progress()
	# Even an internally signed sparse prefix or invalid receipt must fail semantic checks.
	campaign.progress["routes"]["kaia-windrow"]["completed"].remove_at(0)
	check(campaign.save_progress(),"signed_sparse_fixture")
	campaign.load_progress()
	check(not campaign.progress["yin_unlocked"],"contiguous_prefix_enforced")
	file=FileAccess.open(save_path,FileAccess.WRITE);file.store_string(pristine);file.close()
	campaign.load_progress()

func _output() -> void:
	var file:=FileAccess.open("res://../artifacts/v1_closure/full_campaign_runtime_evidence.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"nodes":rows,"progress":campaign.progress,"scope":"Source-scene staged automation; real BattleScene controls/contact/result receipts, explicit positioning/invulnerability/KO fixtures. No human/exported acceptance.","human_playthrough":false,"V1_AUTOMATED_READY":false},"  ")+"\n");file.close()
	print("FULL_CAMPAIGN ",failures.is_empty()," nodes=",rows.size()," failures=",failures)
