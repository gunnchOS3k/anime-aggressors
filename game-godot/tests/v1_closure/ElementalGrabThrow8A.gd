extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
## Public grab/directional release, declared idle/position fixtures. No earned or art claims.
var feedback: Array=[]
var damages: Array=[]
var grab_events: Array=[]
func release() -> void:
	super.release()
	for slot in [1,2]:
		for key in ["up","down","jump","taunt"]:Input.action_release("p%d_%s" % [slot,key])
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	p.combat_feedback.feedback_triggered.connect(func(info):feedback.append(info.duplicate(true)))
	d.damaged.connect(func(amount,_total):damages.append(amount))
	p.grab_event.connect(func(info):grab_events.append(info.duplicate(true)))
	for fid in (IDs.slice(0,1) if pilot else IDs):
		for body in ["male","female"]:
			for face in [1,-1]:
				for direction in ["forward","back","up","down"]:
					await throw_case(p,d,fid,body,face,direction)
	release();write(true);quit(0 if failures.is_empty() else 1)
func throw_case(p,d,fid: String,body: String,face: int,direction: String) -> void:
	release();var gs=root.get_node("GameState");gs.p1_body_variant=body;gs.p2_body_variant=body
	p.configure(fid,1,false,9,Vector2(-40,240));d.configure("juno-spark" if fid!="juno-spark" else "kaia-windrow",2,false,9,Vector2(-40+32*face,240))
	p.global_position=Vector2(-40,240);d.global_position=Vector2(-40+32*face,240)
	for actor in [p,d]:
		actor.move_runner.cancel();actor.projectile_spawner.clear_all();actor.state_machine.enter("idle")
		actor.velocity=Vector2.ZERO;actor.controls_enabled=true;actor.invincible=false;actor.shielding=false
		actor.aura=0;actor.damage_percent=0;actor._hitstop=0;actor.hitstun_remaining=0;actor.armor_frames_remaining=0
		actor._input_edge_held.clear();actor._recent_move_ids.clear();actor.combo_count=0
	p.facing=face;d.facing=-face;current_scene._battle_sim.body_spacing.previous_order.clear()
	for ready in range(100):
		await physics_frame
		if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
	contacts.clear();feedback.clear();damages.clear();grab_events.clear()
	var renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(p)
	var start: int=renderer.history.size()
	var label=fid+":"+body+":"+str(face)+":"+direction
	Input.action_press("p1_grab")
	for i in range(30):
		await physics_frame
		if p.grabbed_target==d:break
	Input.action_release("p1_grab")
	check(p.grabbed_target==d and d.grabbed_by==p,label+":genuine_acquisition")
	if p.grabbed_target!=d:write(false);return
	await frames(5)
	check(grab_events.filter(func(e):return e.get("result")=="success").size()==1,label+":one_acquisition")
	check(grab_events.filter(func(e):return e.get("result")=="whiff").is_empty(),label+":no_false_whiff")
	var axis=face if direction=="forward" else -face
	var command=direction if direction in ["up","down"] else "right" if axis==1 else "left"
	Input.action_press("p1_"+command);Input.action_press("p1_attack");await frames(2);release()
	check(contacts.size()==1 and damages.size()==1 and feedback.size()==1,label+":one_damage_contact_feedback")
	var before: float=d.damage_percent
	if contacts.size()==1:
		var contact: Dictionary=contacts[0]
		check(contact.move_id=="throw_"+direction and contact.contact_owner=="direct_throw" and contact.move_frame==0,label+":original_frame_zero_release")
		check(renderer.history.slice(start).filter(func(h):return h.event_id==contact.combat_event_id).size()==1,label+":one_primary_mesh")
		check(is_equal_approx(float(damages[0]),float(contact.damage)),label+":damage_matches_authority")
		check(p.hit_resolver.resolve(p,d,p._current_move,p.damage_percent).is_empty(),label+":duplicate_rejected")
		rows.append({"fighter":fid,"body":body,"facing":face,"direction":direction,"damage":before,"contact":contact,"model_loaded":p.is_model_loaded(),"actual_body":p.data.body_variant,"defender_body":d.data.body_variant,"feedback_count":feedback.size(),"damage_applications":damages.size(),"events":grab_events.duplicate(true)})
	check(p.is_model_loaded() and p.data.body_variant==body and d.data.body_variant==body,label+":actual_models_loaded")
	p.execute_throw();await frames(48)
	check(is_equal_approx(d.damage_percent,before) and contacts.size()==1,label+":no_late_damage")
	check(p.grabbed_target==null and d.grabbed_by==null and not p.hitbox.monitoring,label+":clean_release")
	write(false)
func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("elemental_grab_throw.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Live BattleScene declared positioning, real public grab/directional throw; both model resources; no active CPU, native visual approval or earned Story evidence","balance_defaults_changed":false},"\t"));f.close()
