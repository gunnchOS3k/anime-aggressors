extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var dialogue=root.get_node("StoryDialogue")
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for fid in IDs:
		for mode in ["Full","Balanced","Reduced"]:
			dialogue.settings["vfx_intensity"]=mode;dialogue.settings["reduced_flash"]=true;dialogue.settings["high_contrast_vfx"]=true;dialogue.settings["reduced_particles"]=mode=="Reduced"
			await prepare(p,d,fid,"female" if mode=="Reduced" else "male",-1 if mode=="Reduced" else 1)
			Input.action_press("p1_left" if mode=="Reduced" else "p1_right",.5);Input.action_press("p1_attack");await frames(2)
			Input.action_release("p1_attack");Input.action_release("p1_right");Input.action_release("p1_left")
			for frame in range(40):
				if p.move_runner.active and p.move_runner.total_frame>=int(p._current_move.startup_frames)-1:break
				await physics_frame
			Input.action_press("p2_shield");await frames(18);release()
			check(contacts.size()==1 and contacts[0].get("perfect_guard",false),fid+mode+":actual_guard")
			var renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(d)
			if contacts.size()==1:
				var info:Dictionary=contacts[0]
				check(renderer.history.filter(func(e):return e.event_id==info.combat_event_id and e.kind==24).size()==1,fid+mode+":primary_retained")
				check(not info.get("screen_flash",true) and str(info.get("camera_event","x")).is_empty(),fid+mode+":no_flash_or_camera_impulse")
			check(renderer.active_count()<=renderer.slots.size(),fid+mode+":bounded_pool")
			rows.append({"fighter":fid,"mode":mode,"active_slots":renderer.active_count(),"pool_slots":renderer.slots.size(),"primary":24,"high_contrast":true,"reduced_flash":true});write(false)
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("guard_accessibility.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"27actual public contact dispatch/pool fixtures,9fighters x3modes; not pixel comparison, GPU frame-time or photosensitivity certification"},"\t"));f.close()
