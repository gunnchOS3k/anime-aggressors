extends "res://tests/v1_closure/FormActingRuntime8C.gd"
## Staged actual Godot form/body render, not earned progression, CPU or movie.
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	var caption:=Label.new();caption.add_theme_font_size_override("font_size",12);caption.add_theme_color_override("font_color",Color.WHITE);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_outline_size",3);current_scene.hud.add_child(caption)
	for body in ["male","female"]:
		var atlas:=Image.create(768,2016,false,Image.FORMAT_RGBA8)
		for index in range(9):
			var fid: String=IDs[index];await configure(p,d,fid,body,1)
			d.global_position.x=500;p.aura=0
			var ladder: Array=p.get_forms_doc().form_ladder
			for stage in range(3):
				var form_id: String=ladder[stage]
				p.apply_form(form_id);p._play_current_animation("idle")
				await frames(12)
				var head: Vector2=p.model_3d.project_bone_to_combat_world("Head")
				var foot: Vector2=(p.model_3d.project_bone_to_combat_world("Foot_L")+p.model_3d.project_bone_to_combat_world("Foot_R"))*.5
				var center: Vector2=p.get_canvas_transform()*((head+foot)*.5)
				var texture_size:=root.get_texture().get_size()
				var origin:=Vector2i(clampi(int(center.x)-128,0,int(texture_size.x)-256),clampi(int(center.y)-112,0,int(texture_size.y)-224))
				caption.position=Vector2(origin)+Vector2(4,3);caption.text=fid+" · "+body+"\n"+str(p.get_forms_doc().forms[form_id].ladder_step)+" · STAGED WIP"
				await process_frame;await RenderingServer.frame_post_draw
				var frame:=root.get_texture().get_image().get_region(Rect2i(origin,Vector2i(256,224)))
				atlas.blit_rect(frame,Rect2i(0,0,256,224),Vector2i(stage*256,index*224))
				var presentation: Dictionary=p.model_3d._form_presentation_8c.snapshot()
				if stage>0:check(presentation.installed_form==form_id and int(presentation.sockets)>0 and presentation.failures.is_empty(),fid+body+form_id+":actual_native_form_resource")
				rows.append({"fighter":fid,"body":body,"form":form_id,"facing":1,"presentation":presentation,"acting":p.model_3d.get_animation_controller().get_form_acting_report(),"crop":Rect2i(origin,Vector2i(256,224)),"scope":"Direct form/idle visual fixture in actual BattleScene, not earned advancement or activeCPU"})
		var err:=atlas.save_png(output.path_join("forms_"+body+"_staged_actual_renderer.png"));check(err==OK,body+":native_sheet")
	var f=FileAccess.open(output.path_join("native_forms_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"scope":"54staged BASE/first/second form renders across18bodies; actualGodotGLTF/savedidle. No CPU, earnedStory, cinematic/finalart/human/device/FPS acceptance.","human_approved":false},"\t"));f.close();release();quit(0 if failures.is_empty() else 1)
