extends "res://tests/integration/OrdinaryMatchCompletion.gd"
## One bounded one-stock battle. Public position-aware edge pressure/grab/throw
## inputs only; no seeded damage, actor motion, winner or stock mutation.
var expired_launch_samples: Array = []
var last_body_contacts: Dictionary = {}
var finish_proof: Dictionary = {}
var elapsed := 0
var acquisitions: Array = []
var late_contacts := 0
var terminal_changes: Array = []

func grab_event(info: Dictionary, actor) -> void:
	if info.get("result","")!="success":return
	var target=actor.grabbed_target
	acquisitions.append({"frame":Engine.get_physics_frames(),"attacker_slot":actor.slot,
		"defender_slot":target.slot,"attacker_position":[actor.position.x,actor.position.y],
		"target_position":[target.position.x,target.position.y],
		"authored_height_overlap":actor._grab_overlaps_target_height(target)})

func record_contact(a,d,info: Dictionary) -> void:
	if is_instance_valid(battle) and battle._match_finished:late_contacts+=1
	super.record_contact(a,d,info)
	var velocity: Vector2=info.get("actual_launch",Vector2.ZERO)
	contacts[-1].merge({"attacker_slot":a.slot,"defender_slot":d.slot,
		"contact_owner":info.get("contact_owner",""),"activation_id":info.get("attack_activation_id",-1),
		"position":[d.position.x,d.position.y],"launch":[velocity.x,velocity.y],
		"damage_after":d.damage_percent,"state":d.state_machine.current_state,
		"hitstun_seconds":d.hitstun_remaining,"attacker_x":a.position.x})
	if str(info.get("contact_result",""))=="hit" and float(info.get("damage",0))>0:
		last_body_contacts[d.slot]=contacts[-1].duplicate(true)

func stock_lost(actor) -> void:
	super.stock_lost(actor)
	var last: Dictionary=last_body_contacts.get(actor.slot,{})
	if last.is_empty():return
	var point=Vector2(last.position[0],last.position[1])
	var inside=point.x>=float(battle.blast.left) and point.x<=float(battle.blast.right) and point.y>=float(battle.blast.top) and point.y<=float(battle.blast.bottom)
	finish_proof={"stock_loss":losses[-1].duplicate(true),"last_confirmed_body_contact":last,
		"frames_from_contact":Engine.get_physics_frames()-int(last.frame),
		"contact_was_inside_blast":inside,"distinct_opponent":int(last.attacker_slot)!=actor.slot,
		"damage_applied":float(last.damage)>0,"result_injected":false,
		"stock_or_position_written_by_driver":false,"damage_seeded":false}

func observe() -> void:
	super.observe()
	if not is_instance_valid(battle):return
	if battle._match_finished and not terminal.is_empty():
		if not terminal.has("HUD"):
			terminal["HUD"]=[]
			for panel in [battle._p1_panel,battle._p2_panel]:
				terminal.HUD.append({"percent_text":panel._pct_label.text,"remaining_stock_pips":panel._stock_pips.filter(func(pip):return pip.modulate.a>.5).size()})
		for i in range(2):
			var actor=[battle.fighter1,battle.fighter2][i]
			if actor.damage_percent!=terminal.actors[i].damage or actor.stocks!=terminal.actors[i].stocks or not actor.combat_closed:
				terminal_changes.append({"frame":Engine.get_physics_frames(),"slot":actor.slot})
	if not battle._active:return
	for actor in [battle.fighter1,battle.fighter2]:
		if actor.state_machine.current_state=="launched" and not actor.is_on_floor() and actor.state_machine.state_time>actor.hitstun_remaining+1.0/60.0:
			expired_launch_samples.append({"frame":Engine.get_physics_frames(),"slot":actor.slot,
				"state_time":actor.state_machine.state_time,"hitstun_seconds":actor.hitstun_remaining,
				"can_move":actor.state_machine.can_move(),"can_attack":actor.state_machine.can_attack(),
				"position":[actor.position.x,actor.position.y]})

func drive() -> void:
	var p=battle.fighter1;var d=battle.fighter2
	var edge_x: float=p.platform_center_x-p.platform_half_width+16.0
	if p.grabbed_by != null:
		phase="ordinary_mash_escape";keys(["attack"] if elapsed%4<2 else ["jump"]);return
	if p.grabbed_target != null:
		phase="ordinary_outward_throw";keys(["left","attack"]);return
	if not p.is_on_floor() and (p.position.x<p.platform_center_x-p.platform_half_width+25 or p.position.y>p.platform_surface_y):
		phase="ordinary_self_recovery"
		var actions: Array=["right"]
		if elapsed%40<2:actions.append("jump")
		if p.position.y>p.platform_surface_y and elapsed%45<2:actions.append("up");actions.append("special")
		keys(actions);return
	if p.position.x>edge_x+5:
		phase="ordinary_edge_positioning";keys(["left"]);return
	if p.position.x<edge_x-5:
		phase="ordinary_spacing_correction";keys(["right"]);return
	if absf(d.position.x-p.position.x)<65 and absf(d.position.y-p.position.y)<60:
		if p.facing!=1:
			phase="ordinary_face_opponent";keys(["right"]);return
		phase="ordinary_grab_attempt"
		keys(["grab"] if elapsed%12<2 else []);return
	phase="ordinary_edge_guard"
	keys(["shield"] if elapsed%90<18 else [])

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile");quit(2);return
	var gs=root.get_node("GameState")
	if gs.battle_eval_mode:push_error("Privileged evaluation prohibited");quit(2);return
	gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="kaia-windrow";gs.p2_fighter_id="juno-spark"
	gs.p1_is_cpu=false;gs.p2_is_cpu=true;gs.cpu_level=3
	gs.ruleset_id="stock-1";gs.stocks=1;gs.match_type="stock";gs.match_timer_seconds=180
	gs.reset_match()
	var career_before: int=gs.career_matches
	var campaign=root.get_node("CampaignRuntime")
	var progress_before=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle")
	for i in range(360):
		await physics_frame
		if active_battle():break
	check(active_battle(),"ordinary_match_started")
	if not active_battle():finish();return
	battle=current_scene
	check(battle.fighter2.is_cpu and battle.fighter2.controls_enabled,"active_CPU")
	check(battle.fighter1.damage_percent==0 and battle.fighter2.damage_percent==0,"zero_starting_damage")
	for actor in [battle.fighter1,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(record_contact)
		actor.koed.connect(stock_lost.bind(actor))
		actor.grab_event.connect(grab_event.bind(actor))
	physics_frame.connect(observe)
	await image("01_match_ready")
	for i in range(2400):
		if not is_instance_valid(battle) or not battle._active:break
		elapsed=i;drive()
		await physics_frame
	keys([])
	if is_instance_valid(battle) and battle._match_finished:await image("02_match_end")
	for i in range(90):
		await physics_frame
		if route_is("ResultsScene.tscn"):break
	check(not finish_proof.is_empty(),"confirmed_attack_precedes_stock_loss")
	if not finish_proof.is_empty():
		check(finish_proof.contact_was_inside_blast and finish_proof.distinct_opponent and finish_proof.damage_applied and finish_proof.frames_from_contact<=120,"attack_to_blast_causality")
	check(expired_launch_samples.is_empty(),"no_expired_air_recovery_lock")
	check(acquisitions.all(func(a):return a.authored_height_overlap),"all_acquisitions_overlap_authored_height")
	check(route_is("ResultsScene.tscn"),"actual_results_transition")
	if not route_is("ResultsScene.tscn"):finish();return
	await frames(30)
	var results=current_scene
	check(not finish_proof.is_empty() and gs.last_winner_slot==int(finish_proof.last_confirmed_body_contact.attacker_slot),"winner_matches_finishing_attacker")
	check(not terminal.is_empty() and terminal.paused_sim and terminal.actors.all(func(a):return a.closed and not a.controls),"terminal_authority_closed")
	var winner_name="Kaia" if gs.last_winner_slot==1 else "Juno"
	check(results.title_label.text.contains(winner_name) and terminal.banner.contains(winner_name),"winner_title_and_banner_agree")
	check(late_contacts==0 and terminal_changes.is_empty(),"no_late_contact_or_terminal_mutation")
	if terminal.has("HUD"):
		for i in range(2):
			check(terminal.HUD[i].remaining_stock_pips==terminal.actors[i].stocks and terminal.HUD[i].percent_text=="%.1f%%"%terminal.actors[i].damage,"terminal_HUD_agrees:"+str(i+1))
	else:check(false,"terminal_HUD_missing")
	check(root.get_node("MatchTelemetry").count_of("match_end")==1 and gs.career_matches==career_before+1,"single_recorded_result")
	var saved=ConfigFile.new()
	check(saved.load("user://aa_save.cfg")==OK and int(saved.get_value("career","matches",-1))==career_before+1,"career_result_persisted")
	if DisplayServer.get_name()!="headless":check(results.victory_portrait.texture!=null,"winner_portrait_texture_loaded")
	await image("03_results")
	phase="public_UI_rematch";await accept_focused()
	for i in range(360):
		await physics_frame
		if active_battle():break
	check(active_battle(),"public_UI_rematch_started")
	if active_battle():
		battle=current_scene
		check(gs.last_winner_slot==-1 and not battle.fighter1.combat_closed and not battle.fighter2.combat_closed,"fresh_match_ownership")
		check(battle.fighter1.stocks==1 and battle.fighter2.stocks==1 and battle.fighter1.damage_percent==0 and battle.fighter2.damage_percent==0,"fresh_match_stocks_and_damage")
		await image("04_rematch")
		phase="public_UI_return"
		var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true;Input.parse_input_event(cancel)
		await process_frame
		cancel=cancel.duplicate();cancel.pressed=false;Input.parse_input_event(cancel);await frames(2)
		for button in battle._pause_panel.find_children("*","Button",true,false):
			if button.text=="Return to Menu":await click(button);break
		for i in range(10):
			await process_frame
			if route_is("MainMenuScene.tscn"):break
		check(route_is("MainMenuScene.tscn") and not paused,"public_UI_return_to_menu")
	check(JSON.stringify(campaign.progress)==progress_before,"Story_progress_unchanged")
	finish()

func finish() -> void:
	keys([])
	var result={"PASS":failures.is_empty(),"scope":"Actual one-stock BattleScene, active CPU3, ordinary edge-pressure/grab/throw/UI inputs; zero starting damage; no damage, positions, AI, stocks or results written during play.","headless":DisplayServer.get_name()=="headless","captured_gameplay_movie":false,"checks":checks,"failures":failures,"contacts":contacts,"acquisitions":acquisitions,"stock_losses":losses,"finish_proof":finish_proof,"expired_launch_samples":expired_launch_samples,"late_contacts":late_contacts,"terminal_changes":terminal_changes,"terminal":terminal,"trace":trace,"inputs":inputs,"screenshots":images,"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var f=FileAccess.open(output.path_join("ATTACK_EARNED_MATCH.json"),FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	print("ATTACK_EARNED_MATCH ","PASS" if failures.is_empty() else "FAIL"," contacts=",contacts.size()," losses=",losses.size()," expired_launch_samples=",expired_launch_samples.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
