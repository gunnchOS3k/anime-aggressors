extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	for fid in IDs:
		await prepare(p,d,fid,"female",1)
		p.configure(fid,1,false,9,p.global_position);d.configure("kaia-windrow",2,false,9,d.global_position);p.facing=1;d.facing=-1
		for ready in range(90):
			await physics_frame
			if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
		items.clear_items();items.spawn_party_item("prism_heart",p.global_position+Vector2(0,-24));await frames(2)
		Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt");await frames(38)
		Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt")
		var observation:Dictionary=d.cpu.observe(p)
		check(p.state_machine.current_state=="ultimate_startup" and observation.opp_attacking,fid+":visible_ultimate_recognized_as_attack")
		rows.append({"fighter":fid,"public_state":p.state_machine.current_state,"observed_attack":observation.opp_attacking});write(false)
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("party_AI_observation.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Public-input ultimate states passed through existing CPU public observation; no strategy/difficulty tuning or forced outcomes"},"\t"));f.close()
