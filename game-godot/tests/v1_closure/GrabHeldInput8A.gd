extends "res://tests/v1_closure/GrabLifecycle8A.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.grab_event.connect(func(info):events.append(info.duplicate(true)))
	var contacts: Array=[]
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		await prepare(p,d);p.configure(fid,1,false,9,p.global_position)
		for ready in range(100):
			await physics_frame
			if p.is_on_floor() and p.state_machine.can_attack():break
		p.facing=1;contacts.clear();events.clear()
		Input.action_press("p1_grab")
		for i in range(30):
			await physics_frame
			if p.grabbed_target==d:break
		check(p.grabbed_target==d,fid+":real_held_button_grab")
		await frames(110)
		check(contacts.is_empty(),fid+":no_early_auto_throw")
		await frames(105)
		Input.action_release("p1_grab")
		var acquired: int=events.filter(func(e):return e.get("result")=="success").size()
		check(acquired==1,fid+":held_button_cannot_acquire_again")
		check(contacts.size()==1,fid+":one_original_timed_auto_release")
		rows.append({"fighter":fid,"acquisitions":acquired,"contacts":contacts.size(),"events":events.duplicate(true)})
	release()
	var f=FileAccess.open(output.path_join("grab_held_input.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"Nine public held-grab/timed-auto-release fixtures against idle opponent; unchanged two-second timeout, no ordinary competitive result claim"},"\t"));f.close()
	quit(0 if failures.is_empty() else 1)
