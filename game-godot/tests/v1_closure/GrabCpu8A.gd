extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
var grab_events: Array=[]
var cpu_moves: Array=[]
var cpu_rows: Array=[]
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=true;gs.cpu_level=3;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	var campaign=root.get_node("CampaignRuntime");var saved_progress: String=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.grab_event.connect(func(info):grab_events.append(info.duplicate(true)))
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	d.move_runner.move_started.connect(func(id):cpu_moves.append(id))
	for fid in IDs:
		release();d.cpu.clear_simulated_inputs()
		var n: int=IDs.find(fid);var other: String=IDs[(n+1)%IDs.size()]
		gs.p1_body_variant="female" if n%2==0 else "male";gs.p2_body_variant=gs.p1_body_variant
		p.configure(fid,1,false,9,Vector2(-80,240));d.configure(other,2,true,9,Vector2(40,240))
		p.global_position=Vector2(-80,240);d.global_position=Vector2(40,240)
		for a in [p,d]:
			a.move_runner.cancel();a.projectile_spawner.clear_all();a.state_machine.enter("idle")
			a.velocity=Vector2.ZERO;a.invincible=false;a.controls_enabled=true;a.aura=0;a.damage_percent=0;a._hitstop=0;a.hitstun_remaining=0;a._input_edge_held.clear()
		p.facing=1;d.facing=-1
		grab_events.clear();cpu_moves.clear();contacts.clear()
		for frame in range(300):
			# Public P1 edges only. The CPU remains active and unmodified throughout.
			for key in ["left","right","grab","attack"]:Input.action_release("p1_"+key)
			if p.grabbed_target!=null:
				if frame%4==0:Input.action_press("p1_attack")
			elif p.grabbed_by==null:
				var dx: float=d.global_position.x-p.global_position.x
				if absf(dx)>29:Input.action_press("p1_right" if dx>0 else "p1_left",.65)
				if frame%12==0:Input.action_press("p1_grab")
			await physics_frame
			check(p.grabbed_target==null or (p.grabbed_target==d and d.grabbed_by==p),fid+":no_invalid_owner")
		var ids: Dictionary={}
		for contact in contacts:
			check(not ids.has(contact.combat_event_id),fid+":no_duplicate_authoritative_contact")
			ids[contact.combat_event_id]=true
		var throws: Array=contacts.filter(func(c):return c.contact_owner=="direct_throw")
		cpu_rows.append({"fighter":fid,"opponent":other,"body":gs.p1_body_variant,"frames":300,"cpu_enabled":d.is_cpu,"actual_cpu_moves":cpu_moves.duplicate(),"grab_acquisitions":grab_events.filter(func(e):return e.get("result")=="success").size(),"throw_contacts":throws,"grab_events":grab_events.duplicate(true),"damage_received":p.damage_percent,"damage_dealt":d.damage_percent,"combo_claim":false,"KO_claim":false})
		write(false)
	check(saved_progress==JSON.stringify(campaign.progress),"no_Story_progress_change")
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("grab_cpu.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":cpu_rows,"failures":failures,"scope":"Nine bounded 300-frame public-input observations against active level3 CPU; declared fresh-match configuration; no forced results, combo or native visual acceptance. Zero grabs/throws remain valid negative observations."},"\t"));f.close()
