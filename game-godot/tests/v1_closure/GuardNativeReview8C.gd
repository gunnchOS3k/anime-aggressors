extends "res://tests/v1_closure/ElementalGuard8C.gd"
## Two compact montages from actual BattleScene renders, held public guard
## against active CPU. No forced contact/result/damage or recording/export.
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=false;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):
		if a==p and b==d:contacts.append(info.duplicate(true)))
	for body in ["male","female"]:
		var atlas:=Image.create(1920,1080,false,Image.FORMAT_RGBA8)
		for index in range(9):
			var fid: String=IDs[index];await _ready_pair(p,d,fid,body,1 if body=="male" else -1)
			current_scene._p1_panel.configure(p.data.get("displayName",p.fighter_id),Color(p.data.get("color","#55dddd")),9,false)
			current_scene._p2_panel.configure(d.data.get("displayName",d.fighter_id)+" · "+body,Color(d.data.get("color","#55dddd")),9,true)
			p.is_cpu=true;p.dummy_mode="cpu";p.cpu.setup(p,3,1022+index)
			Input.action_press("p2_shield")
			await frames(90)
			await RenderingServer.frame_post_draw
			var frame:=root.get_texture().get_image();frame.resize(640,360,Image.INTERPOLATE_LANCZOS)
			atlas.blit_rect(frame,Rect2i(0,0,640,360),Vector2i(index%3*640,index/3*360))
			rows.append({"fighter":fid,"body":body,"defender_facing":d.facing,"cpu_attacker":p.fighter_id,"cpu_active":p.is_cpu and p.controls_enabled,"contacts":contacts.duplicate(true),"guard":d._guard_presentation.snapshot(),"model_loaded":d.is_model_loaded(),"scope":"90frames public held shield against activeCPU; ordinary gameplay results retained, no guaranteed contact"})
			check(d.is_model_loaded(),fid+body+":visible_model_loaded")
			p.is_cpu=false;p.dummy_mode="idle";p.cpu.clear_simulated_inputs();release()
		var err:=atlas.save_png(output.path_join("battle_guard_"+body+"_actual_renderer.png"));check(err==OK,body+":native_montage_saved")
	var f=FileAccess.open(output.path_join("native_guard_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Actual BattleScene compact 18-body render observations with activeCPU and public held guard. Not recorded nativeaudio/video, sustainedFPS/device or owner art acceptance.","human_approved":false},"\t"));f.close();release();quit(0 if failures.is_empty() else 1)
