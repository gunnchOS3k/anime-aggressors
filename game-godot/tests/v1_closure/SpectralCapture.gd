extends SceneTree
## Public-input versus fixtures. Active CPU for combo evidence; idle fixture only for uninterrupted charge.
var held: Array=[]
var events: Array=[]
var contacts: Array=[]
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
func _init() -> void: call_deferred("_run")
func inputs(actions: Array) -> void:
	for action in held:
		if action not in actions:Input.action_release("p1_"+action)
	for action in actions:
		if action not in held:Input.action_press("p1_"+action)
	held=actions
func observe_contact(attacker: Node, defender: Node, info: Dictionary) -> void:
	var point: Vector2=info.get("contact_world",Vector2.ZERO)
	var launch: Vector2=info.get("launch",Vector2.ZERO)
	contacts.append({"event_id":info.get("combat_event_id",""),"attacker":attacker.fighter_id,"defender":defender.fighter_id,"move":info.move_id,
		"frame":Engine.get_physics_frames(),"movie_frame":Engine.get_process_frames()-1,"result":info.get("contact_result","legacy"),"damage":info.damage,"damage_before":info.get("defender_damage_before",defender.damage_percent-info.damage),
		"contact_world":[point.x,point.y],"launch":[launch.x,launch.y],"actual_velocity":[defender.velocity.x,defender.velocity.y],"hitstop_frames":info.hitstop_frames,
		"hitstun_seconds":defender.hitstun_remaining,"defender_state_before":info.get("defender_state_before","unknown"),"follow_up_before_control":info.get("defender_in_hitstun_before",false),
		"attacker_move_frame":info.get("move_frame",-1)})
func write_evidence() -> void:
	if output.is_empty() or battle == null or not is_instance_valid(battle):return
	var renderer=battle.get_node_or_null("SpectralFeedback")
	var file=FileAccess.open(output.path_join("combat_capture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":source_sha,"movie_fps":60,"fixture":"versus; seeded public-input driver; explicit starting damage band "+band,
		"starting_opponent_damage":50 if band=="medium" else 110 if band=="high" else 0,"opponent_cpu":battle.fighter2.is_cpu,"controls_enabled":battle.fighter2.controls_enabled,
		"forced_moves":false,"forced_ko":false,"frozen_opponent":false,"story_receipts":false,"human_playthrough":false,
		"idle_fixture_not_combo_evidence":idle_opponent,"moves":events,"contacts":contacts,"samples":samples,"ko_events":ko_events,
		"presentation_events":renderer.history if renderer != null else [],"pool":renderer.stats() if renderer != null else {},"player_damage":battle.fighter1.damage_percent,"opponent_damage":battle.fighter2.damage_percent},"  ")+"\n");file.close()
func _run() -> void:
	await process_frame
	seed(431017)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--performance-fighter="):fid=arg.get_slice("=",1)
		if arg.begins_with("--source-sha="):source_sha=arg.get_slice("=",1)
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--performance-opponent=idle":idle_opponent=true
		if arg.begins_with("--damage-band="):band=arg.get_slice("=",1)
		if arg.begins_with("--capture-frames="):max_frames=int(arg.get_slice("=",1))
	var state=root.get_node("GameState")
	state.mode="versus";state.p1_is_cpu=false;state.cpu_level=3;state.battle_eval_mode=false;state.p1_fighter_id=fid;state.p2_fighter_id="ember-vale" if fid=="juno-spark" else "juno-spark"
	state.p1_body_variant="female";state.p2_body_variant="female";state.p2_is_cpu=not idle_opponent;state.stocks=9;state.match_timer_seconds=180
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	battle=current_scene
	battle.fighter2.damage_percent=50 if band=="medium" else 110 if band=="high" else 0
	var p=battle.fighter1
	for actor in [p,battle.fighter2]:
		actor.hit_resolver.hit_confirmed.connect(observe_contact)
		actor.move_runner.move_started.connect(func(mid):events.append({"fighter":actor.fighter_id,"move":mid,"frame":Engine.get_physics_frames(),"movie_frame":Engine.get_process_frames()-1}))
		actor.koed.connect(func():ko_events.append({"fighter":actor.fighter_id,"movie_frame":Engine.get_process_frames()-1,"stocks":actor.stocks}))
	var label:=Label.new();label.text="AUTOMATED INPUT · "+("idle charge fixture" if idle_opponent else "active CPU · "+band+" initial damage")+" · "+source_sha.left(12);label.position=Vector2(30,90);battle.hud.add_child(label)
	started_frame=Engine.get_physics_frames()
	for frame in range(max_frames):
		if current_scene!=battle:break
		var phase:=frame%1200
		var dx:float=battle.fighter2.position.x-p.position.x
		var actions: Array=[]
		if idle_opponent:
			if phase<650:actions.append_array(["special","shield"])
			elif phase<690:
				if phase%20<4:actions.append("special")
			elif phase<720:actions.append("attack")
		else:
			if phase<200:
				if absf(dx)>50:actions.append("right" if dx>0 else "left")
				if frame%25<4:actions.append("attack")
			elif phase<360:
				if absf(dx)>50:actions.append("right" if dx>0 else "left")
				if frame%60<5:actions.append_array(["attack","special"])
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
		inputs(actions)
		if frame%6==0:
			samples.append({"movie_frame":Engine.get_process_frames()-1,"p1_state":p.state_machine.current_state,"p2_state":battle.fighter2.state_machine.current_state,"p2_velocity":[battle.fighter2.velocity.x,battle.fighter2.velocity.y],"p1_damage":p.damage_percent,"p2_damage":battle.fighter2.damage_percent,"process_time_s":Performance.get_monitor(Performance.TIME_PROCESS),"physics_time_s":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)})
		if frame%30==0:write_evidence()
		await physics_frame
	inputs([]);write_evidence();final_written=true;quit()
