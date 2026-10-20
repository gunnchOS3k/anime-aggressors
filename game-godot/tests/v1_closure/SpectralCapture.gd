extends SceneTree
## Public-input versus fixtures. Active CPU for combo evidence; idle fixture only for uninterrupted charge.
var held: Array=[]
var events: Array=[]
var contacts: Array=[]
var visual_contacts: Array=[]
var samples: Array=[]
var ko_events: Array=[]
var output := ""
var fid := "ember-vale"
var source_sha := ""
var idle_opponent := false
var band := "low"
var max_frames := 1800
var battle: Node
var started_frame := 0
var final_written := false
var transitions: Array=[]
var phases: Array=[]
var input_events: Array=[]
var exact_trace := false
var probe := ""
var same_fighter_comparison := false
var opponent_id := ""
var turn_latch := 0
var retreating := false
var empowerment_observations: Array=[]
var frame_bars:Array=[]
var frame_stamps:Array=[]
var stamp_frames:=false
func _init() -> void: call_deferred("_run")
func inputs(actions: Array) -> void:
	if actions != held:input_events.append({"movie_frame":Engine.get_process_frames()-1,"actions":actions.duplicate(),"axis_strength":.55 if not probe.is_empty() else 1.0})
	for action in held:
		if action not in actions:Input.action_release("p1_"+action)
	for action in actions:
		if action not in held:Input.action_press("p1_"+action,.55 if not probe.is_empty() and action in ["left","right"] else 1.0)
	held=actions
func observe_contact(attacker: Node, defender: Node, info: Dictionary) -> void:
	var point: Vector2=info.get("contact_world",Vector2.ZERO)
	var launch: Vector2=info.get("launch",Vector2.ZERO)
	var screen: Vector2=defender.get_canvas_transform()*point
	contacts.append({"event_id":info.get("combat_event_id",""),"attacker":attacker.fighter_id,"attacker_slot":attacker.slot,"defender_slot":defender.slot,"defender":defender.fighter_id,"move":info.move_id,
		"frame":Engine.get_physics_frames(),"movie_frame":Engine.get_process_frames()-1,"result":info.get("contact_result","legacy"),"damage":info.damage,"damage_before":info.get("defender_damage_before",defender.damage_percent-info.damage),
		"contact_world":[point.x,point.y],"contact_screen":[screen.x,screen.y],"launch":[launch.x,launch.y],"actual_velocity":[defender.velocity.x,defender.velocity.y],"hitstop_frames":info.hitstop_frames,
		"hitstun_seconds":defender.hitstun_remaining,"defender_state_before":info.get("defender_state_before","unknown"),"follow_up_before_control":info.get("defender_in_hitstun_before",false),
		"audio_path":info.get("played_audio",{}).get("path",""),"elemental_audio_path":info.get("played_audio",{}).get("elemental_layer",{}).get("path",""),"attacker_move_frame":info.get("move_frame",-1),"contact_owner":info.get("contact_owner","legacy_unrecorded"),"attack_activation_id":info.get("attack_activation_id",-1),"projectile_instance_id":info.get("projectile_instance_id",-1)})
	observe_visual_contact(attacker,defender,info.duplicate(true),Engine.get_process_frames()-1)
func observe_visual_contact(attacker: Node,defender: Node,info: Dictionary,frame: int) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(defender): return
	var model=attacker.model_3d
	var controller=model.get_animation_controller()
	if controller==null or model._camera==null or model._display==null:return
	var sk=controller.get_skeleton()
	sk.force_update_all_bone_transforms()
	var points: Dictionary={}
	for name in ["Hand_L","Hand_R","Foot_L","Foot_R"]:
		var bone: int=sk.find_bone(name)
		if bone<0: continue
		var pixel: Vector2=model._camera.unproject_position(sk.to_global(sk.get_bone_global_pose(bone).origin))
		var size: Vector2=Vector2(model._viewport.size)
		if model._display.flip_h:pixel.x=size.x-pixel.x
		if model._display.flip_v:pixel.y=size.y-pixel.y
		var world: Vector2=model._display.to_global(pixel-size*.5+model._display.offset)
		points[name]=[world.x,world.y]
	var target: Vector2=info.get("contact_world",Vector2.ZERO)
	var minimum:=INF
	for name in ["Hand_L","Hand_R"]:
		if points.has(name):minimum=minf(minimum,Vector2(points[name][0],points[name][1]).distance_to(target))
	visual_contacts.append({"event_id":info.combat_event_id,"movie_frame":frame,"attacker":attacker.fighter_id,"move":info.move_id,"result":info.get("contact_result",""),"animation":controller.get_animation_player().current_animation,"animation_time_s":controller.get_animation_player().current_animation_position,"move_frame":attacker.move_runner.total_frame,"move_phase":attacker.move_runner.phase,"phase_frame":attacker.move_runner.frame_in_phase,"runtime_timing":{"startup":attacker.move_runner.move_data.get("startup_frames",-1),"active":attacker.move_runner.move_data.get("active_frames",-1),"recovery":attacker.move_runner.move_data.get("recovery_frames",-1)},"authored_timing":controller._choreography_timing.get(str(info.move_id),{}).get("contact_frame",-1),"limbs_world":points,"contact_world":[target.x,target.y],"nearest_hand_to_contact_px":minimum,"scope":"synchronous contact projected live rig joints; geometry diagnostic, projectile/throw contact need not equal hand"})
func write_evidence() -> void:
	if output.is_empty() or battle == null or not is_instance_valid(battle):return
	var renderer=battle.get_node_or_null("SpectralFeedback")
	var file=FileAccess.open(output.path_join("combat_capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":source_sha,"movie_fps":60,"stage":"training-grid","match_seed":431017,"fixture":"versus on existing flat Training Grid stage; seeded public-input driver; explicit starting damage band "+band,
		"starting_opponent_damage":50 if band=="medium" else 110 if band=="high" else 0,"body_presentations":[battle.fighter1.data.body_variant,battle.fighter2.data.body_variant],"same_fighter_comparison":same_fighter_comparison,"opponent_cpu":battle.fighter2.is_cpu,"controls_enabled":battle.fighter2.controls_enabled,
		"forced_moves":false,"forced_ko":false,"frozen_opponent":false,"story_receipts":false,"human_playthrough":false,
		"idle_fixture_not_combo_evidence":idle_opponent,"probe":probe,"exact_trace":exact_trace,"state_transitions":transitions,"move_phases":phases,"public_inputs":input_events,"moves":events,"contacts":contacts,"visual_contacts":visual_contacts,"samples":samples,"ko_events":ko_events,
		"frame_stamps":frame_stamps,"authored_cancels":battle.fighter1.authored_cancel_history,"presentation_events":renderer.history if renderer != null else [],"empowerment_observations":empowerment_observations,"expression":battle.fighter1.get_node("CombatExpressionDirector").action_lines.evidence(),"pool":renderer.stats() if renderer != null else {},"player_damage":battle.fighter1.damage_percent,"opponent_damage":battle.fighter2.damage_percent},"  ")+"\n");file.close()
func _run() -> void:
	await process_frame
	seed(431017)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--performance-fighter="):fid=arg.get_slice("=",1)
		if arg.begins_with("--source-sha="):source_sha=arg.get_slice("=",1)
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--performance-opponent=idle":idle_opponent=true
		elif arg.begins_with("--performance-opponent="):opponent_id=arg.get_slice("=",1)
		if arg.begins_with("--damage-band="):band=arg.get_slice("=",1)
		if arg=="--exact-trace":exact_trace=true
		if arg=="--frame-barcode":stamp_frames=true
		if arg=="--same-fighter-comparison":same_fighter_comparison=true
		if arg.begins_with("--combo-probe="):probe=arg.get_slice("=",1)
		if arg.begins_with("--capture-frames="):max_frames=int(arg.get_slice("=",1))
	var state=root.get_node("GameState")
	state.stage_id="training-grid";state.match_seed=431017
	state.mode="versus";state.p1_is_cpu=false;state.cpu_level=3;state.battle_eval_mode=false;state.p1_fighter_id=fid;state.p2_fighter_id="ember-vale" if fid=="juno-spark" else "juno-spark"
	if opponent_id in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:state.p2_fighter_id=opponent_id
	if same_fighter_comparison:state.p2_fighter_id=fid
	state.p1_body_variant="female";state.p2_body_variant="male" if same_fighter_comparison else "female";state.p2_is_cpu=not idle_opponent;state.stocks=9;state.match_timer_seconds=180
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	battle=current_scene
	battle.fighter2.damage_percent=50 if band=="medium" else 110 if band=="high" else 0
	var p=battle.fighter1
	for actor in [p,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(observe_contact)
		actor.move_runner.move_started.connect(func(mid):events.append({"fighter":actor.fighter_id,"slot":actor.slot,"move":mid,"frame":Engine.get_physics_frames(),"movie_frame":Engine.get_process_frames()-1}))
		actor.state_machine.state_changed.connect(func(from_state,to_state):transitions.append({"fighter":actor.fighter_id,"movie_frame":Engine.get_process_frames()-1,"from":from_state,"to":to_state,"velocity":[actor.velocity.x,actor.velocity.y],"position":[actor.position.x,actor.position.y],"hitstun_duration":actor.hitstun_remaining,"landing_lag":actor.state_machine.landing_lag}))
		actor.move_runner.phase_changed.connect(func(move_phase):phases.append({"fighter":actor.fighter_id,"movie_frame":Engine.get_process_frames()-1,"move":actor.move_runner.current_move_id(),"phase":move_phase,"move_frame":actor.move_runner.total_frame}))
		actor.koed.connect(func():ko_events.append({"fighter":actor.fighter_id,"movie_frame":Engine.get_process_frames()-1,"stocks":actor.stocks}))
	var label:=Label.new();label.text="AUTOMATED INPUT · "+("idle charge fixture" if idle_opponent else "active CPU · "+band+" initial damage")+" · "+source_sha.left(12);label.position=Vector2(30,90);battle.hud.add_child(label)
	if stamp_frames:
		var layer:=CanvasLayer.new();layer.layer=100;battle.add_child(layer)
		for bit in range(20):
			var rect:=ColorRect.new();rect.position=Vector2(20+bit*12,190);rect.size=Vector2(10,24);layer.add_child(rect);frame_bars.append(rect)
	started_frame=Engine.get_physics_frames()
	for frame in range(max_frames):
		if current_scene!=battle:break
		if stamp_frames:
			var observed:=Engine.get_process_frames()-1
			var identity:int=preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS.find(fid)
			var code:int=(observed & 65535)|(identity<<16)
			for bit in range(20):frame_bars[bit].color=Color.WHITE if code & (1<<bit) else Color.BLACK
			frame_stamps.append({"expected_process_frame":observed,"identity":identity,"physics_frame":Engine.get_physics_frames()})
		var phase:=frame%1200
		var dx:float=battle.fighter2.position.x-p.position.x
		var actions: Array=[]
		if not probe.is_empty():
			actions=_probe_inputs(frame,p,dx)
		elif idle_opponent:
			if phase<400:actions.append_array(["special","shield"])
			elif phase<430:actions.append("attack")
			elif phase<720:
				if phase%55<4:actions.append("special")
			elif phase<850:
				actions.append_array(["special","shield"])
				if phase==800:actions.append("jump")
		else:
			if phase<200:
				if absf(dx)>50:actions.append("right" if dx>0 else "left")
				if frame%4==0 and p.state_machine.can_attack():actions.append("attack")
			elif phase<360:
				if absf(dx)>50:actions.append("right" if dx>0 else "left")
				if frame%4==0 and p.state_machine.can_attack():actions.append_array(["attack","special"])
			elif phase<520:
				if frame%55<5:actions.append("special")
			elif phase<800:actions.append_array(["special","shield"])
			elif phase<850:
				if frame%20<4:actions.append("attack")
			elif phase<970:actions.append("shield")
			else:
				if absf(dx)>55:actions.append("right" if dx>0 else "left")
				if frame%80<4:actions.append("jump")
				if frame%30<4:actions.append("attack")
		# Correct facing through movement input; never assign transform/facing/velocity.
		if not idle_opponent and p.state_machine.can_move() and (not probe.is_empty() or not (phase>=520 and phase<970)) and not ((probe=="edgeguard" and frame%600<260) or (probe=="edgeguard-throw" and frame<260)):
			if absf(dx)<12:retreating=true
			if retreating and absf(dx)<28:
				actions=["left" if dx>=0 else "right"];turn_latch=1
			elif turn_latch>0 or (absf(dx)>8 and signf(dx)!=float(p.facing)):
				retreating=false
				actions=["right" if dx>0 else "left"];turn_latch=maxi(0,turn_latch-1)
		inputs(actions)
		if frame%30==0:
			var body_aura: Dictionary=p.model_3d.get_empowerment_evidence()
			empowerment_observations.append({"frame":Engine.get_process_frames()-1,"meter":p.aura,"active":body_aura.get("active",false),"super_ready":body_aura.get("super_ready",false),"grammar":body_aura.get("grammar","calm"),"vertices":body_aura.get("vertices",0),"draw_cpu_us":body_aura.get("draw_cpu_us",0),"ambience_playing":p._elemental_audio!=null and p._elemental_audio.ambience!=null and p._elemental_audio.ambience.playing})
		if exact_trace or frame%6==0:
			samples.append({"movie_frame":Engine.get_process_frames()-1,"p1_state":p.state_machine.current_state,"p1_hitstop":p._hitstop,"p2_hitstop":battle.fighter2._hitstop,"p1_can_attack":p.state_machine.can_attack(),"p2_can_attack":battle.fighter2.state_machine.can_attack(),"p2_state_time":battle.fighter2.state_machine.state_time,"p2_hitstun_duration":battle.fighter2.hitstun_remaining,"p1_move":p.move_runner.current_move_id(),"p1_move_frame":p.move_runner.total_frame,"p1_phase":p.move_runner.phase,"p1_cancel_window":p.move_runner.in_cancel_window,"p2_state":battle.fighter2.state_machine.current_state,"p1_position":[p.position.x,p.position.y],"p2_position":[battle.fighter2.position.x,battle.fighter2.position.y],"p1_facing":p.facing,"p2_facing":battle.fighter2.facing,"p2_velocity":[battle.fighter2.velocity.x,battle.fighter2.velocity.y],"p1_damage":p.damage_percent,"p2_damage":battle.fighter2.damage_percent,"process_time_s":Performance.get_monitor(Performance.TIME_PROCESS),"physics_time_s":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)})
		if frame%30==0:write_evidence()
		await physics_frame
	inputs([]);write_evidence();final_written=true;quit()

func _probe_inputs(frame: int,p: Node,dx: float) -> Array:
	# Adaptive observation selects public controls only. No game state/result writes.
	var actions: Array=[]
	if probe=="authored-review":
		var dy:float=battle.fighter2.position.y-p.position.y
		var section:=frame%1300
		if section>=1000:
			return ["special","shield"] if section<1220 else ["special"] if frame%45==0 else []
		var radius:=110.0 if section>=800 else 25.0
		if absf(dx)>radius:actions.append("right" if dx>0 else "left")
		if dy< -55 and p.is_on_floor():actions.append("jump")
		if p.move_runner.active and frame%2==0 and p.move_runner.has_method("can_cancel_to"):
			if p.move_runner.can_cancel_to("jab_2") or p.move_runner.can_cancel_to("jab_finisher"):return ["attack"]
			if p.move_runner.can_cancel_to("up_tilt"):return ["up","attack"]
		if p.state_machine.can_attack() and frame%4==0 and absf(dx)<=radius and absf(dy)<65:
			# Neutral press explicitly releases movement; directional locomotion
			# otherwise selects a tilt instead of the authored jab chain.
			if section<550:return ["attack"]
			if section<800:return ["attack","special"]
			return ["special"]
		return actions
	if probe=="edgeguard-throw":
		# One bounded missing-evidence attempt: approach the existing edge, then
		# grab/throw using ordinary controls. CPU can attack, escape and recover.
		if p.state_machine.current_state=="grab_hold":
			return ["right" if p.position.x>=0 else "left","attack"]
		if frame<260:
			return ["right"] if p.position.x<470 else []
		if absf(dx)>25:actions.append("right" if dx>0 else "left")
		elif frame%4==0 and p.state_machine.can_attack():actions.append("grab")
		return actions
	if probe=="edgeguard":
		var stage_phase:=frame%600
		if stage_phase<180:
			return ["right"] if p.position.x<480 else ["shield"]
		if stage_phase<260:
			if frame%40<2:actions.append("jump")
			if p.position.x>battle.fighter2.position.x-28:actions.append("left")
			return actions
		if absf(dx)>28:actions.append("right" if dx>0 else "left")
		if frame%4==0 and p.state_machine.can_attack():actions.append_array(["attack","special"])
		return actions
	var hits:=0
	for c in contacts:
		if c.attacker==fid and c.result=="hit":hits+=1
	var radius:=120.0 if probe=="projectile-light" and hits==0 else 25.0
	if absf(dx)>radius:actions.append("right" if dx>0 else "left")
	if frame%2==0 and p.state_machine.can_attack():
		if probe=="heavy-light" and hits==0:actions.append_array(["attack","special"])
		elif probe=="light-heavy" and hits==1:actions.append_array(["attack","special"])
		elif probe=="projectile-light" and hits==0:
			# Horizontal movement + Special selects side_special. Release the
			# public movement input on the cast frame so this recipe actually
			# requests neutral Special; facing is still corrected by movement.
			if absf(dx)<=radius:actions=["special"]
		elif probe=="aerial-light" and hits==0 and p.is_on_floor():actions.append("jump")
		else:actions.append("attack")
	return actions
