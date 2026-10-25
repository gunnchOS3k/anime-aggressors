extends SceneTree
## Actual BattleScene, ordinary controls and active CPU. No forced damage/results.
var output := ""
var body := "male"
var automated := false
var battle
var held: Array = []
var contacts: Array = []
var trace: Array = []
var input_events: Array = []
var stock_losses: Array = []
var screenshots: Array = []
var failures: Array = []
var ticks := 0
var label := "neutral"
var first_contact_image := false

func _initialize() -> void:
	call_deferred("run")

func keys(actions: Array) -> void:
	if actions == held: return
	for key in held:
		if key not in actions: Input.action_release("p1_"+key)
	for key in actions:
		if key not in held: Input.action_press("p1_"+key)
	held = actions.duplicate()
	input_events.append({"frame":Engine.get_physics_frames(), "actions":held.duplicate(), "case":label})

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output=arg.trim_prefix("--review-output=")
		if arg == "--review-female": body="female"
		if arg == "--review-automate": automated=true
	if output.is_empty(): quit(2); return
	if not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile");quit(2);return
	var gs = root.get_node("GameState")
	gs.mode="versus"; gs.stage_id="training-grid"
	gs.p1_fighter_id="ember-vale"; gs.p2_fighter_id="juno-spark"
	gs.p1_body_variant=body;gs.p2_body_variant=body
	gs.p1_is_cpu=false;gs.p2_is_cpu=true
	# Keep saved defaults/rules; no changes to damage, stocks, timers or CPU tuning.
	if gs.battle_eval_mode: failures.append("privileged_mode");quit(2);return
	root.get_node("SceneRouter").go("battle")
	for i in range(360):
		await physics_frame
		if current_scene != null and "fighter1" in current_scene:
			battle=current_scene
			if battle._active: break
	if battle == null or not battle._active:
		push_error("Battle did not activate");quit(2);return
	for actor in [battle.fighter1,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(contact)
		actor.koed.connect(stock_lost.bind(actor))
	var help := Label.new()
	help.text="INTEGRATED SOURCE REVIEW · "+body+" · active Juno CPU\nA/D move · J jab · J+K heavy · L guard · W jump · I dodge · U grab.\nOriginal private art is used only with an explicit verified manifest. Human approval pending."
	help.position=Vector2(24,105);help.add_theme_font_size_override("font_size",16)
	battle.hud.add_child(help)
	physics_frame.connect(observe)
	print("NATIVE_PLAYABLE_READY body=",body," active_CPU=",battle.fighter2.is_cpu," controls=",battle.fighter1.controls_enabled)
	await image("match_ready")

func contact(attacker, defender, info: Dictionary) -> void:
	contacts.append({"frame":Engine.get_physics_frames(),"case":label,"attacker":attacker.fighter_id,"defender":defender.fighter_id,"move":info.get("move_id",""),"event_id":info.get("combat_event_id",""),"result":info.get("contact_result",""),"resolved_damage":info.get("damage",0),"defender_damage":defender.damage_percent,"runtime_move_frame":attacker.move_runner.total_frame,"hitstop":defender._hitstop,"active_clip":attacker.model_3d.get_animation_controller().get_active_clip()})
	if not first_contact_image:
		first_contact_image=true;image("first_contact")

func stock_lost(actor) -> void:
	stock_losses.append({"frame":Engine.get_physics_frames(),"fighter":actor.fighter_id,"stocks":actor.stocks,"damage":actor.damage_percent,"ko_text":battle.ko_label.text})
	image("stock_loss_"+str(stock_losses.size()))

func image(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output.path_join(name+".png")
	root.get_texture().get_image().save_png(path)
	screenshots.append({"path":path,"physics_frame":Engine.get_physics_frames()})

func observe() -> void:
	if not is_instance_valid(battle): return
	ticks+=1
	var p=battle.fighter1;var d=battle.fighter2
	if automated and p.controls_enabled and battle._active:
		var cycle := ticks % 360
		if cycle < 55:
			label="guard / fresh press"; keys(["shield"] if cycle < 35 else [])
		elif cycle < 95:
			label="aerial / recovery";keys(["jump"] if cycle%40==15 else [])
		elif absf(p.position.x-d.position.x)>74:
			label="ordinary approach";keys(["right" if d.position.x>p.position.x else "left"])
		elif cycle%55==0:
			label="heavy attempt";keys(["attack","special"])
		elif cycle%25==0:
			label="light attempt";keys(["attack"])
		else: keys([])
	if ticks%3==0:
		var actors: Array=[]
		for a in [p,d]:
			var c=a.model_3d.get_animation_controller()
			actors.append({"fighter":a.fighter_id,"body":a.body_variant,"position":[a.position.x,a.position.y],"facing":a.facing,"state":a.state_machine.current_state,"move":a.move_runner.current_move_id(),"move_frame":a.move_runner.total_frame,"damage":a.damage_percent,"stocks":a.stocks,"hitstop":a._hitstop,"clip":c.get_active_clip(),"private_art":c.original_art_report(),"model":a.model_3d.get_current_model_source(),"CPU":a.is_cpu,"controls":a.controls_enabled})
		trace.append({"frame":Engine.get_physics_frames(),"case":label,"actors":actors,"HUD":[battle.p1_hud.text,battle.p2_hud.text],"ko_banner":battle.ko_label.text,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0})
	if ticks%60==0: save()

func save() -> void:
	var file := FileAccess.open(output.path_join("PLAYABLE_REVIEW.json"),FileAccess.WRITE)
	if file == null:return
	file.store_string(JSON.stringify({"scope":"Actual native BattleScene; public-input automation if enabled; active CPU; no forced results or earned Story claims","automated":automated,"body":body,"contacts":contacts,"trace":trace,"inputs":input_events,"stock_losses":stock_losses,"screenshots":screenshots,"failures":failures,"native_stock_loss_observed":not stock_losses.is_empty(),"full_match_victory_verified":false,"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false},"  "))
	file.close()

func _finalize() -> void:
	keys([])
	if not output.is_empty():save()
