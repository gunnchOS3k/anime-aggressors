extends "res://tests/v1_closure/FormCPUObservation8C.gd"
## Bounded real controls/active CPU; only initial aura and spacing are fixtures.
## No damage/form/position/control-state writes after observation begins.
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	var campaign=root.get_node("CampaignRuntime");var campaign_before:=JSON.stringify(campaign.progress)
	for resolver in [p.hit_resolver,d.hit_resolver]:
		resolver.hit_confirmed.connect(func(a,b,info):observed_contacts.append({"attacker":a.fighter_id,"defender":b.fighter_id,"frame":Engine.get_physics_frames(),"info":info.duplicate(true)}))
	for index in range(9):
		var fid: String=IDs[index];await configure(p,d,fid,"female" if index%2==0 else "male",1 if index%2==0 else -1)
		var start_count: int=p.get_transform_activations()
		observed_contacts.clear();d.is_cpu=true;d.dummy_mode="cpu";d.cpu.setup(d,3,9200+index)
		var samples: Array=[];var attempts: Array=[];var completions: Array=[]
		var previous_form: String=p.get_current_form_id()
		for frame in range(720):
			var count: int=p.get_transform_activations()-start_count
			var attempting:bool=count<2 and frame%4==0 and p._transform_pipeline.can_attempt_transform()
			var distance_x:float=d.global_position.x-p.global_position.x
			var charge:bool=count<2 and not p._transform_sequence_active and absf(distance_x)>110
			for key in ["shield","special","attack","dodge","jump","left","right"]:_button(key,false)
			if attempting:
				for key in ["shield","special","attack"]:_button(key,true)
				attempts.append({"frame":frame,"aura":p.aura,"form":p.get_current_form_id()})
			elif charge:
				_button("shield",true);_button("special",true)
			elif not p._transform_sequence_active:
				var retreat:bool=count<2 and absf(distance_x)<140
				_button("left",distance_x>0 if retreat else distance_x < -60,.65)
				_button("right",distance_x<0 if retreat else distance_x > 60,.65)
				_button("attack",not retreat and frame%24 in [0,1])
				_button("special",not retreat and frame%45 in [8,9])
				_button("dodge",retreat and frame%50==16)
			await physics_frame
			if p.get_current_form_id()!=previous_form:
				previous_form=p.get_current_form_id();completions.append({"frame":frame,"form":previous_form,"aura":p.aura})
			if frame%30==0:samples.append({"frame":frame,"form":p.get_current_form_id(),"aura":p.aura,"state":p.state_machine.current_state,"cpu_state":d.state_machine.current_state,"player_damage":p.damage_percent,"cpu_damage":d.damage_percent,"face":p.model_3d._expression_controller.evidence()})
		rows.append({"fighter":fid,"body":p.model_3d._body_variant,"initial_facing":1 if index%2==0 else -1,"opponent":d.fighter_id,"cpu_level":3,"cpu_active":d.is_cpu and d.controls_enabled,"initial_aura_fixture":{"player":100,"cpu":100},"frames":720,"attempts":attempts,"completions":completions,"completed_advancements":p.get_transform_activations()-start_count,"final_form":p.get_current_form_id(),"p_damage":p.damage_percent,"cpu_damage":d.damage_percent,"p_stocks":p.stocks,"cpu_stocks":d.stocks,"contacts":observed_contacts.duplicate(true),"samples":samples,"scope":"One bounded public-input driver recipe per fighter; one body/facing each; declared initial aura100, no subsequent stat/result writes; not earnedStory/strictcombo/human/device acceptance"})
		release();d.is_cpu=false;d.dummy_mode="idle";d.cpu.clear_simulated_inputs()
		var f=FileAccess.open(output.path_join("second_advancement_cpu_8d.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"complete":index==8,"rows":rows,"human_approved":false,"Story_unchanged":campaign_before==JSON.stringify(campaign.progress)},"\t"));f.close()
	quit()
