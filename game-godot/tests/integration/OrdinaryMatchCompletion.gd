extends SceneTree
## Bounded public-input match lifecycle. Real CPU and blast rules, no position,
## damage, stock-loss, result or AI override. Walking offstage is a declared
## self-destruct test, NOT attack-earned KO or finishing-hit acceptance.
var output := ""
var held: Array = []
var inputs: Array = []
var contacts: Array = []
var losses: Array = []
var trace: Array = []
var checks: Array = []
var failures: Array = []
var images: Array = []
var phase := "setup"
var battle
var terminal: Dictionary = {}
var ui_observations: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks.append({"check":label,"pass":value})
	if not value:failures.append(label)

func keys(actions: Array) -> void:
	if actions==held:return
	for key in held:
		if key not in actions:Input.action_release("p1_"+key)
	for key in actions:
		if key not in held:Input.action_press("p1_"+key)
	held=actions.duplicate()
	inputs.append({"frame":Engine.get_physics_frames(),"phase":phase,"p1_actions":held.duplicate()})

func frames(n: int) -> void:
	for i in range(n):await physics_frame

func route_is(suffix: String) -> bool:
	return current_scene != null and current_scene.scene_file_path.ends_with(suffix)

func active_battle() -> bool:
	return current_scene != null and "fighter1" in current_scene and current_scene._active

func record_contact(a,d,info: Dictionary) -> void:
	contacts.append({"frame":Engine.get_physics_frames(),"attacker":a.fighter_id,"defender":d.fighter_id,"move":info.get("move_id",""),"result":info.get("contact_result",""),"damage":info.get("damage",0),"event_id":info.get("combat_event_id","")})

func stock_lost(actor) -> void:
	losses.append({"frame":Engine.get_physics_frames(),"slot":actor.slot,"fighter":actor.fighter_id,"remaining_stocks":actor.stocks,"position":[actor.position.x,actor.position.y],"damage":actor.damage_percent,"phase":phase})

func observe() -> void:
	if not is_instance_valid(battle):return
	var actors: Array=[]
	for actor in [battle.fighter1,battle.fighter2]:
		actors.append({"slot":actor.slot,"fighter":actor.fighter_id,"model":actor.model_3d.get_current_model_source(),"body":actor.model_3d.get_body_variant(),"position":[actor.position.x,actor.position.y],"state":actor.state_machine.current_state,"stocks":actor.stocks,"damage":actor.damage_percent,"controls":actor.controls_enabled,"closed":actor.combat_closed,"CPU":actor.is_cpu,"move":actor.move_runner.current_move_id(),"clip":actor.model_3d.get_animation_controller().get_active_clip()})
	if not battle._active and battle._match_finished and terminal.is_empty():
		terminal={"frame":Engine.get_physics_frames(),"actors":actors.duplicate(true),"banner":battle.countdown_label.text,"paused_sim":battle._battle_sim.paused,"winner":root.get_node("GameState").last_winner_slot}
	if Engine.get_physics_frames()%3==0:trace.append({"frame":Engine.get_physics_frames(),"phase":phase,"actors":actors,"active":battle._active})

func image(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var path=output.path_join(label+".png")
	var err=root.get_texture().get_image().save_png(path)
	check(err==OK,"screenshot:"+label)
	images.append({"path":path,"physics_frame":Engine.get_physics_frames()})

func click(button: Button) -> void:
	# GUI input is viewport-local. A retained battle camera can give a menu
	# canvas a nonidentity transform; its unprojected global rect is not the
	# position actually drawn or hit-tested by the viewport.
	var pos=button.get_global_transform_with_canvas() * (button.size * 0.5)
	var motion=InputEventMouseMotion.new();motion.position=pos;motion.global_position=pos
	# Headless Window is 64px, while canvas_items has a larger logical viewport.
	# These observed button rectangles are VIEWPORT-local, not physical pixels.
	root.push_input(motion,true)
	await process_frame
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=pos;event.global_position=pos;event.pressed=true
	root.push_input(event,true)
	await process_frame
	event=event.duplicate();event.pressed=false;root.push_input(event,true)
	inputs.append({"frame":Engine.get_physics_frames(),"phase":phase,"UI_click":button.text,"position":[pos.x,pos.y]})
	await process_frame

func accept_focused() -> void:
	var focus=root.gui_get_focus_owner()
	ui_observations.append({"phase":phase,"viewport":str(root.get_visible_rect()),"window_size":str(root.size),"focus":str(focus.get_path()) if focus != null else "NONE"})
	var event=InputEventAction.new();event.action="ui_accept";event.pressed=true;Input.parse_input_event(event)
	await process_frame
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
	inputs.append({"frame":Engine.get_physics_frames(),"phase":phase,"UI_action":"ui_accept"})
	await process_frame

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing non-isolated profile");quit(2);return
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="kaia-windrow";gs.p2_fighter_id="juno-spark"
	gs.p1_is_cpu=false;gs.p2_is_cpu=true;gs.cpu_level=3
	# Existing legal pre-match one-stock rules, no in-match tuning or manipulation.
	gs.ruleset_id="stock-1";gs.stocks=1;gs.match_type="stock";gs.match_timer_seconds=180
	gs.reset_match()
	var career_before: int=gs.career_matches
	root.get_node("SceneRouter").go("battle")
	for i in range(360):
		await physics_frame
		if active_battle():break
	check(active_battle(),"ordinary_match_started")
	if not active_battle():finish();return
	battle=current_scene
	check(battle.fighter2.is_cpu and battle.fighter2.controls_enabled,"active_CPU")
	for actor in [battle.fighter1,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(record_contact)
		actor.koed.connect(stock_lost.bind(actor))
	physics_frame.connect(observe)
	phase="ordinary_combat"
	await image("01_match_ready")
	for i in range(360):
		if not is_instance_valid(battle) or not battle._active:break
		var p=battle.fighter1;var d=battle.fighter2
		if i<40:keys(["shield"] if i<25 else [])
		elif absf(p.position.x-d.position.x)>74:keys(["right" if d.position.x>p.position.x else "left"])
		elif i%55==0:keys(["attack","special"])
		elif i%25==0:keys(["attack"])
		else:keys([])
		await physics_frame
	keys([])
	await image("02_after_combat")
	phase="ordinary_left_input_self_destruct_attempt"
	for i in range(600):
		if not is_instance_valid(battle) or not battle._active:break
		keys(["left"])
		await physics_frame
	keys([])
	if is_instance_valid(battle) and battle._match_finished:await image("03_actual_match_end")
	for i in range(90):
		await physics_frame
		if route_is("ResultsScene.tscn"):break
	check(not losses.is_empty(),"ordinary_blast_stock_loss_observed")
	check(route_is("ResultsScene.tscn"),"actual_results_transition")
	check(gs.career_matches==career_before+1,"one_career_result")
	var saved=ConfigFile.new()
	check(saved.load("user://aa_save.cfg")==OK and int(saved.get_value("career","matches",-1))==career_before+1,"career_result_persisted")
	check(root.get_node("MatchTelemetry").count_of("match_end")==1,"one_match_end_event")
	if not route_is("ResultsScene.tscn"):finish();return
	await frames(30)
	var results=current_scene
	check(results.title_label.text.contains("Juno") if gs.last_winner_slot==2 else results.title_label.text.contains("Kaia"),"winner_title_matches_result")
	ui_observations.append({"phase":phase,"portrait_texture_present":results.victory_portrait.texture!=null,"controls":results.find_children("*","Control",true,false).map(func(c):return {"name":str(c.name),"rect":str(c.get_global_rect()),"visible":c.is_visible_in_tree()})})
	if DisplayServer.get_name()!="headless":check(results.victory_portrait.texture!=null,"winner_portrait_texture_loaded")
	check(not terminal.is_empty() and terminal.paused_sim,"terminal_simulation_closed")
	if not terminal.is_empty():
		check(terminal.actors.all(func(a):return a.closed and not a.controls),"terminal_actor_authority_closed")
	await image("04_results")
	phase="public_UI_rematch"
	await accept_focused()
	for i in range(360):
		await physics_frame
		if active_battle():break
	check(active_battle(),"public_UI_rematch_started")
	if active_battle():
		battle=current_scene
		check(gs.last_winner_slot==-1 and not battle.fighter1.combat_closed and not battle.fighter2.combat_closed,"fresh_match_ownership")
		check(battle.fighter1.stocks==1 and battle.fighter2.stocks==1 and battle.fighter1.damage_percent==0 and battle.fighter2.damage_percent==0,"fresh_match_stocks_and_damage")
		await image("05_rematch_ready")
		phase="public_UI_pause_and_return"
		var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true;Input.parse_input_event(cancel)
		await process_frame
		cancel=cancel.duplicate();cancel.pressed=false;Input.parse_input_event(cancel)
		await frames(2)
		check(battle._paused and paused,"public_pause_opened")
		for button in battle._pause_panel.find_children("*","Button",true,false):
			if button.text=="Return to Menu":await click(button);break
		for i in range(10):
			await process_frame
			if route_is("MainMenuScene.tscn"):break
		check(route_is("MainMenuScene.tscn") and not paused,"public_UI_return_to_menu")
		await image("06_menu")
	finish()

func finish() -> void:
	keys([])
	var record={"PASS":failures.is_empty(),"scope":"Actual BattleScene ordinary public combat/left input and UI events; active CPU; no forced result. Declared self-destruct tests stock/result/rematch, NOT an attack-earned finishing KO.","headless":DisplayServer.get_name()=="headless","captured_gameplay_movie":false,"checks":checks,"failures":failures,"contacts":contacts,"stock_losses":losses,"terminal":terminal,"trace":trace,"inputs":inputs,"screenshots":images,"UI_observations":ui_observations,"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false}
	var file=FileAccess.open(output.path_join("ORDINARY_MATCH_COMPLETION.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  "));file.close()
	print("ORDINARY_MATCH_COMPLETION ","PASS" if failures.is_empty() else "FAIL"," checks=",checks.size()," contacts=",contacts.size()," stock_losses=",losses.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
