extends SceneTree
## Declared positions/aura/defensive states test actual BattleScene fighters.
## Ordinary public-input evidence is recorded separately; no Story save writes.
const Data = preload("res://scripts/data/data_loader.gd")
const Sim = preload("res://scripts/combat/projectile_interactions.gd")
var output := ""
var failures: Array = []
var rows: Array = []
var p; var d; var third
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func reset_targets() -> void:
	p.projectile_spawner.clear_all()
	# Independent cases are not a same-frame 54-contact pool stress test.
	preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(p)._process(2.0)
	for actor in [p,d,third]:
		actor.damage_percent = 0; actor.aura = 0; actor._hitstop = 0
		actor.invincible = false; actor.armor_frames_remaining = 0
		actor.state_machine.enter("idle")
		for key in ["story_team","story_cosmic_contract","story_released"]:
			if actor.has_meta(key): actor.remove_meta(key)
func spawn(amount: float):
	return p.projectile_spawner.spawn_from_move(Data.find_move(p.move_manifest,"neutral_special_projectile"), amount)
func retired(shot, token: String) -> void:
	check(not shot.active and shot.pending_targets.is_empty(), token+":authority_retired")
	check(shot._flight_slot == -1 and not shot._visual.visible, token+":core_retired")
	check(not shot._elemental_audio.travel.playing, token+":travel_stopped")
	check(shot._renderer.slots.filter(func(s): return s.active and str(s.event_id).begins_with("projectile-flight:"+str(shot.get_instance_id())+":")).is_empty(),token+":no_owned_flight_residue")
func run() -> void:
	create_timer(60).timeout.connect(func(): push_error("impact watchdog"); quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(220): await physics_frame
	p=current_scene.fighter1;d=current_scene.fighter2
	third=load("res://scenes/fighters/Fighter.tscn").instantiate();current_scene.add_child(third)
	third.configure("juno-spark",3,false,9,Vector2(180,240))
	for actor in [p,d,third]:actor.controls_enabled=false
	var confirmations:Array=[]
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):confirmations.append(info.duplicate(true)))
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-200,240));p.controls_enabled=false
			for amount in [0,50,75]:
				reset_targets();var start:=confirmations.size();var shot=spawn(amount)
				var point:Vector2=d.global_position+Vector2(-12,-24)
				shot.tick_sim_frame();shot._queue_target(d)
				shot._deliver_hit(d,point)
				var expected_pierce:bool=bool(Data.find_move(p.move_manifest,"neutral_special_projectile").projectile.get("pierce",false))
				var token:String=fid+":"+body+":"+str(amount)
				check(confirmations.size()==start+1,token+":one_authoritative_contact")
				check(shot.active==expected_pierce,token+":authored_policy_not_motion")
				var total:float=d.damage_percent
				shot._deliver_hit(d,point);shot._deliver_hit(third,third.global_position)
				check(d.damage_percent==total,token+":same_target_dedup")
				check((third.damage_percent>0)==expected_pierce,token+":next_target_policy")
				if not expected_pierce:
					retired(shot,token)
					check(shot.global_position==point,token+":at_confirmed_impact")
				var primary:Array=shot._renderer.history.filter(func(e):return e.event_id==confirmations[start].combat_event_id and e.kind in [0,1,10])
				check(primary.size()==1,token+":one_contact_primary")
				rows.append({"fighter":fid,"body":body,"aura_prerequisite":amount,"behavior":shot.behavior,"authored_pierce":expected_pierce,"damage":total,"continued":shot.active,"point":[point.x,point.y]})
	# Defense/Story rejection remains authoritative; only accepted results consume.
	gs.p1_body_variant="female";p.configure("juno-spark",1,false,9,Vector2(-200,240));p.controls_enabled=false
	for rule in ["shield","armor","invulnerable","same_team","cosmic","released"]:
		reset_targets();var shot=spawn(75);var start:=confirmations.size()
		match rule:
			"shield":d.state_machine.enter("shield_hold")
			"armor":d.armor_frames_remaining=10
			"invulnerable":d.invincible=true
			"same_team":p.set_meta("story_team","allies");d.set_meta("story_team","allies");shot.team_key="story:allies"
			"cosmic":d.set_meta("story_cosmic_contract",true)
			"released":d.set_meta("story_released",true)
		shot._deliver_hit(d,d.global_position+Vector2(0,-24))
		check(d.damage_percent==0,rule+":protected_damage")
		var confirmed:bool=rule in ["shield","armor"]
		check((confirmations.size()==start+1)==confirmed,rule+":contact_policy")
		check(shot.active!=confirmed,rule+":expiry_policy")
		if confirmed:retired(shot,rule)
		else:check(shot.hit_targets.is_empty(),rule+":not_a_confirmed_target")
		rows.append({"defense":rule,"confirmed":confirmed,"active":shot.active,"damage":d.damage_percent})
	# A fast sweep must retire at the near face, not its overshot endpoint.
	for mode in ["Full","Balanced","Reduced"]:
		root.get_node("StoryDialogue").set_option("vfx_intensity",mode)
		reset_targets();var shot=spawn(75)
		var hurt:Rect2=d.hit_resolver._world_bounds(d.get_node("Hurtbox/HurtShape"))
		shot.direction=Vector2.RIGHT;shot.global_position=hurt.get_center()-Vector2(100,0);shot.spawn_bounds=shot.world_bounds();shot.speed=18000
		var sim=Sim.new();sim.begin_frame([p,d,third]);shot.tick_sim_frame()
		var endpoint:Vector2=shot.global_position
		sim.resolve_frame([p,d,third]);retired(shot,mode+":swept")
		check(shot.global_position.x<=hurt.position.x+.001 and shot.global_position.x<endpoint.x,mode+":swept_face_not_endpoint")
		var damage:float=d.damage_percent
		shot._on_body_entered(third);shot._queue_target(third);shot._deliver_hit(third);shot.tick_sim_frame()
		check(d.damage_percent==damage and third.damage_percent==0,mode+":no_late_or_second_damage")
		rows.append({"mode":mode,"fast_sweep_endpoint":[endpoint.x,endpoint.y],"impact":[shot.global_position.x,shot.global_position.y],"damage":damage})
	reset_targets();p.projectile_spawner.clear_all();third.queue_free()
	var f=FileAccess.open(output.path_join("projectile_fighter_impact.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"explicit native fighter/position/aura/defense prerequisites, not ordinary play or full-roster artistic acceptance","piercing_exception":"Rook quake_slab pierce:true; one hit per target, existing lifetime, shield/armor stop. No native explicit sustained-contact contract exists; beam is movement only."},"  "));f.close()
	print("PROJECTILE_FIGHTER_IMPACT ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
