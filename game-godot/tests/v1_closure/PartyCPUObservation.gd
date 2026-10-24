extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
## Bounded active-CPU observation; no manufactured contact or success gate.
## Initial roster/spacing/item placements are declared review fixtures.
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed";gs.cpu_level=3
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	for a in [p,d]:a.hit_resolver.hit_confirmed.connect(func(atk,def,info):contacts.append(info.duplicate(true)))
	for index in range(IDs.size()):
		var fid:String=IDs[index]
		d.is_cpu=false;d.cpu.clear_simulated_inputs();await prepare(p,d,fid,"female",1)
		p.configure(fid,1,false,9,p.global_position);d.configure(IDs[(index+1)%IDs.size()],2,false,9,d.global_position)
		p.global_position.x=-110;d.global_position.x=110;p.facing=1;d.facing=-1;p.aura=0;d.aura=0
		for ready in range(90):
			await physics_frame
			if p.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
		d.is_cpu=true;d.cpu.setup(d,int(gs.cpu_level),int(gs.match_seed)) # Normal configured level, no strategy changes.
		items.clear_items();items.spawn_party_item("prism_heart",p.global_position+Vector2(0,-24));await frames(2)
		contacts.clear();Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt");await frames(38)
		var activated:bool=p.party_overdrive.active()
		Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt")
		var ai_states:Dictionary={};var ai_moves:Dictionary={}
		for frame in range(180):
			var axis:float=signf(d.global_position.x-p.global_position.x)
			Input.action_release("p1_left");Input.action_release("p1_right")
			if absf(p.global_position.x-d.global_position.x)>60:Input.action_press("p1_right" if axis>0 else "p1_left",.5)
			if frame%35==0:Input.action_press("p1_attack")
			if frame%35==2:Input.action_release("p1_attack")
			await physics_frame
			ai_states[d.state_machine.current_state]=true
			if d.move_runner.active:ai_moves[d.move_runner.current_move_id()]=true
		release()
		var ultimate_hits:Array=contacts.filter(func(info):return str(info.move_id).begins_with("party_ultimate:"))
		rows.append({"fighter":fid,"opponent":d.fighter_id,"active_CPU":d.is_cpu,"CPU_level":d.cpu.level,"CPU_public_states":ai_states.keys(),"CPU_moves_observed":ai_moves.keys(),"activation_survived":activated,"ultimate_contacts":ultimate_hits.size(),"all_contacts":contacts.size(),"player_damage":p.damage_percent,"CPU_damage":d.damage_percent,"state":p.party_overdrive.snapshot(),"outcome":"OBSERVED_ONLY; no success manufactured"})
		check(not p.invincible,"no_permanent_invulnerability_after_observation:"+fid)
		p.party_overdrive.reset("observation_end");write(false)
		d.is_cpu=false;d.cpu.clear_simulated_inputs()
		p.controls_enabled=false;d.controls_enabled=false
		p.reset_fighter();d.reset_fighter();await frames(85) # Explicit between-observation reset only.
	d.is_cpu=false;d.cpu.clear_simulated_inputs();release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("party_cpu_observation.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Nine bounded public-input activeCPU observations, declared starting lineup/spacing/item placement; no video, human, balance, combo guarantee or platform acceptance"},"\t"));f.close()
