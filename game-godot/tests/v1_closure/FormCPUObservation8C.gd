extends "res://tests/v1_closure/FormActingRuntime8C.gd"
## Bounded ordinary normalized-input observation, active CPU. Initial aura100
## and spacing are declared review fixtures; no later damage/state/result writes.
var observed_contacts: Array=[]
func _button(name: String,on: bool,strength: float=1.0) -> void:
	var action:="p1_"+name
	if on and not Input.is_action_pressed(action):Input.action_press(action,strength)
	elif not on and Input.is_action_pressed(action):Input.action_release(action)
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for resolver in [p.hit_resolver,d.hit_resolver]:
		resolver.hit_confirmed.connect(func(a,b,info):observed_contacts.append({"attacker":a.fighter_id,"defender":b.fighter_id,"frame":Engine.get_physics_frames(),"info":info.duplicate(true)}))
	for index in range(9):
		var fid: String=IDs[index];await configure(p,d,fid,"female" if index%2==0 else "male",1)
		observed_contacts.clear();d.is_cpu=true;d.dummy_mode="cpu";d.cpu.setup(d,3,8200+index)
		var samples: Array=[];var attempts:=0
		for frame in range(240):
			var transform:=frame in [0,90] and p._transform_pipeline.can_attempt_transform()
			if transform:attempts+=1
			var phase:=frame%40
			var delta_x: float=d.global_position.x-p.global_position.x
			for key in ["shield","special","attack"]:_button(key,transform)
			if not transform and not p._transform_sequence_active:
				_button("attack",phase in [8,9]);_button("special",phase in [0,1]);_button("shield",phase>=16 and phase<20)
			_button("right",delta_x>68,.6);_button("left",delta_x< -68,.6);_button("jump",phase==25 and not p._transform_sequence_active)
			await physics_frame
			if frame%30==0:samples.append({"frame":frame,"form":p.get_current_form_id(),"sequence":p._transform_sequence_active,"state":p.state_machine.current_state,"opponent_state":d.state_machine.current_state,"p_damage":p.damage_percent,"cpu_damage":d.damage_percent,"presentation":p.model_3d._form_presentation_8c.snapshot()})
		rows.append({"fighter":fid,"body":p.data.body_variant,"opponent":d.fighter_id,"cpu_level":3,"cpu_active":d.is_cpu and d.controls_enabled,"initial_aura_fixture":{"player":100,"cpu":100},"frames":240,"public_transform_attempts":attempts,"completed_advancements":p.get_transform_activations(),"final_form":p.get_current_form_id(),"p_damage":p.damage_percent,"cpu_damage":d.damage_percent,"p_stocks":p.stocks,"cpu_stocks":d.stocks,"contacts":observed_contacts.duplicate(true),"samples":samples,"scope":"Bounded driver observation, not human play, guaranteed combo, win or earnedStory acceptance"})
		release();d.is_cpu=false;d.dummy_mode="idle";d.cpu.clear_simulated_inputs()
		var f=FileAccess.open(output.path_join("form_cpu_observation_8c.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"complete":index==8,"rows":rows,"scope":"ActiveCPU/publicnormalizedinput, initialaura/spacingreviewfixture only. Misses, interruptions and damage retained; no sourcebalance or laterresult overrides.","human_approved":false},"\t"));f.close()
	quit()
