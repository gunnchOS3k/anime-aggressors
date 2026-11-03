extends SceneTree
## Actual BattleScene, ordinary controls and active CPU. No forced damage/results.
var output := ""
var body := "male"
var automated := false
var cpu_level := 3 # Public setup option: levels1/2 intentionally do not initiate attacks.
var fighter_id := "ember-vale"
var opponent_id := "juno-spark"
var battle
var held: Array = []
var contacts: Array = []
var trace: Array = []
var input_events: Array = []
var move_events: Array = []
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
		if arg.begins_with("--review-fighter="): fighter_id=arg.trim_prefix("--review-fighter=")
		if arg.begins_with("--review-opponent="): opponent_id=arg.trim_prefix("--review-opponent=")
	if output.is_empty(): quit(2); return
	if not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile");quit(2);return
	var gs = root.get_node("GameState")
	gs.mode="versus"; gs.stage_id="training-grid"
	var ids := ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]
	if fighter_id not in ids or opponent_id not in ids: push_error("Unknown review identity");quit(2);return
	gs.p1_fighter_id=fighter_id; gs.p2_fighter_id=opponent_id
	gs.p1_body_variant=body;gs.p2_body_variant=body
	gs.p1_is_cpu=false;gs.p2_is_cpu=true
	gs.cpu_level=cpu_level
	# Select the existing attacking difficulty; no AI strategy, combat values,
	# damage, stocks, timer, hitstun or outcome is overridden.
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
		if not preload("res://scripts/visual/private_battle_art.gd").requested_manifest().is_empty():
			var original: Dictionary = actor.model_3d.get_animation_controller().original_art_report()
			if actor.model_3d.get_current_model_source() != "PRIVATE_ORIGINAL_ART_CANDIDATE" or not original.failures.is_empty() or original.moves.size() != 4:
				push_error("Requested private move set not installed completely");quit(2);return
		actor.hit_resolver.hit_confirmed.connect(contact)
		actor.koed.connect(stock_lost.bind(actor))
		actor.move_runner.move_started.connect(move_event.bind("start",actor))
		actor.move_runner.move_ended.connect(move_event.bind("end",actor))
	var help := Label.new()
	help.text="INTEGRATED SOURCE REVIEW · "+body+" · active "+opponent_id+" CPU\nA/D move · J jab · J+K heavy · L guard · W jump · I dodge · U grab.\nOriginal private art is used only with an explicit verified manifest. Human approval pending."
	help.position=Vector2(24,105);help.add_theme_font_size_override("font_size",16)
	battle.hud.add_child(help)
	physics_frame.connect(observe)
	print("NATIVE_PLAYABLE_READY body=",body," active_CPU=",battle.fighter2.is_cpu," controls=",battle.fighter1.controls_enabled)
	await image("match_ready")

func contact(attacker, defender, info: Dictionary) -> void:
	contacts.append({"frame":Engine.get_physics_frames(),"case":label,"attacker":attacker.fighter_id,"defender":defender.fighter_id,"move":info.get("move_id",""),"event_id":info.get("combat_event_id",""),"result":info.get("contact_result",""),"resolved_damage":info.get("damage",0),"defender_damage":defender.damage_percent,"runtime_move_frame":attacker.move_runner.total_frame,"hitstop":defender._hitstop,"active_clip":attacker.model_3d.get_animation_controller().get_active_clip()})
	contacts[-1].merge({"attack_activation_id":info.get("attack_activation_id",-1),"contact_owner":info.get("contact_owner",""),"attacker_facing":attacker.facing,"attacker_x":attacker.position.x,"defender_x":defender.position.x,"defender_state":defender.state_machine.current_state})
	if not first_contact_image:
		first_contact_image=true;image("first_contact")

func move_event(move_id: String, event: String, actor) -> void:
	move_events.append({"frame":Engine.get_physics_frames(),"fighter":actor.fighter_id,"event":event,"move":move_id,"activation_id":actor.move_runner.activation_id})

func stock_lost(actor) -> void:
	stock_losses.append({"frame":Engine.get_physics_frames(),"fighter":actor.fighter_id,"stocks":actor.stocks,"damage":actor.damage_percent,"ko_text":battle.ko_label.text})
	image("stock_loss_"+str(stock_losses.size()))

func image(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output.path_join(name+".png")
	root.get_texture().get_image().save_png(path)
	screenshots.append({"path":path,"physics_frame":Engine.get_physics_frames()})

func hud_snapshot(panel, fallback: Label) -> Dictionary:
	# BattleHudPanel replaced these legacy labels. Hidden fallback labels keep
	# their setup text and are not evidence that the visible HUD is frozen.
	if is_instance_valid(panel):
		return {"source":"BattleHudPanel", "percent_text":panel._pct_label.text,
			"aura":panel._aura_bar.value,"guard":panel._shield_label.text,
			"visible":panel.is_visible_in_tree()}
	return {"source":"legacy", "text":fallback.text,"visible":fallback.is_visible_in_tree()}

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
			actors.append({"fighter":a.fighter_id,"body":a.model_3d.get_body_variant(),"position":[a.position.x,a.position.y],"facing":a.facing,"state":a.state_machine.current_state,"move":a.move_runner.current_move_id(),"move_frame":a.move_runner.total_frame,"damage":a.damage_percent,"stocks":a.stocks,"hitstop":a._hitstop,"clip":c.get_active_clip(),"private_art":c.original_art_report(),"model":a.model_3d.get_current_model_source(),"CPU":a.is_cpu,"controls":a.controls_enabled})
		trace.append({"frame":Engine.get_physics_frames(),"render_frame":Engine.get_process_frames(),"case":label,"actors":actors,"HUD":[hud_snapshot(battle._p1_panel,battle.p1_hud),hud_snapshot(battle._p2_panel,battle.p2_hud)],"ko_banner":battle.ko_label.text,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0})
	if ticks%60==0: save()

func save() -> void:
	var file := FileAccess.open(output.path_join("PLAYABLE_REVIEW.json"),FileAccess.WRITE)
	if file == null:return
	file.store_string(JSON.stringify({"scope":"Actual native BattleScene; public-input automation if enabled; active CPU; no forced results or earned Story claims","automated":automated,"body":body,"contacts":contacts,"trace":trace,"inputs":input_events,"moves":move_events,"stock_losses":stock_losses,"screenshots":screenshots,"failures":failures,"native_stock_loss_observed":not stock_losses.is_empty(),"full_match_victory_verified":false,"HUMAN_ART_APPROVED":false,"RC2_READY":false,"V1_0_0_RELEASE_AUTHORIZED":false},"  "))
	file.close()

func _finalize() -> void:
	keys([])
	if not output.is_empty():save()
