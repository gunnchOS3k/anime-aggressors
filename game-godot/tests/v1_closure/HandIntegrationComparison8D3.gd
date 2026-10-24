extends "res://tests/v1_closure/SourceHandsComparison8D2.gd"
## Exact repaired8D2 before/new8D3 after; no body/root/pose camouflage.
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	check(DisplayServer.get_name()!="headless","native_renderer_required")
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.items_enabled=false;gs.hazards_enabled=false;gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(200)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for body in ["male","female"]:
		var sheet:=Image.create(TILE.x*12,TILE.y*9,false,Image.FORMAT_RGBA8)
		for fid in IDs:
			var pair: Array=[]
			for version in [0,1]:
				lane="hands_8d2" if version==0 else "hands_8d3"
				gs.set_meta("source_controls_8d",false);gs.set_meta("source_hands_8d2",version==0);gs.set_meta("source_hands_8d3",version==1)
				await configure(p,d,fid,body,1)
				check(is_instance_valid(p.model_3d._source_controls_8d),fid+body+lane+":saved_model")
				if is_instance_valid(p.model_3d._source_controls_8d):pair.append(await capture_hands(p,sheet,IDs.find(fid),version))
			check(pair.size()==2,fid+body+":two_actual_saved_candidates")
			if pair.size()==2:
				check(pair[0].canonical_pose==pair[1].canonical_pose,fid+body+":exact_canonical_before_after")
				for i in range(pair[0].samples.size()):
					for field in ["camera","camera_size","hand_world_transform"]:
						check(pair[0].samples[i][field]==pair[1].samples[i][field],fid+body+":matched_"+field)
			comparisons.append({"fighter":fid,"body":body,"versions":pair})
		check(sheet.save_png(output.path_join("hand_interface_before_after_"+body+".png"))==OK,"native_sheet_saved:"+body)
	release()
	var file:=FileAccess.open(output.path_join("hand_interface_comparison_8d3.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":comparisons,"failures":failures,"observer_sha":OS.get_environment("GITHUB_SHA"),"renderer":RenderingServer.get_current_rendering_method(),"scope":"Staged actual repaired8D2/new8D3 meshes. Fixed source body/camera/wrists; no 3D paired grip, CPU, native audio or human art approval.","human_approved":false},"\t"));file.close()
	quit(0 if failures.is_empty() else 1)
