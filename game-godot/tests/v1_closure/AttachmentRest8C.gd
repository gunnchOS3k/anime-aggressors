extends "res://tests/v1_closure/FormActingRuntime8C.gd"
## Actual saved GLB/socket/rest import across72body/facing/stage configurations.
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for fid in IDs:
		for body in ["male","female"]:
			for face in [1,-1]:
				await configure(p,d,fid,body,face)
				for form_id in p.get_forms_doc().form_ladder.slice(1):
					p.apply_form(form_id);p._play_current_animation("idle");await frames(3)
					var report: Dictionary=p.model_3d._form_presentation_8c.snapshot()
					var label:String=fid+body+str(face)+str(form_id)
					check(report.installed_form==form_id and report.failures.is_empty() and report.sockets>0,label+":actual_GLTF_import")
					for socket in report.socket_correspondence:check(float(socket.rest_max_component_error)<.00001,label+":exact_source_rest_correspondence")
					check(p.model_3d._model_root.scale==Vector3.ONE and p.model_3d._model_root.position==Vector3.ZERO,label+":original_body_root_preserved")
					rows.append({"fighter":fid,"body":body,"facing":face,"form":form_id,"presentation":report})
	var f=FileAccess.open(output.path_join("attachment_rest_8c.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"72actual savedGLB/rest/body/facing import checks; declared form fixture, no final art/native/earned/CPU approval"},"\t"));f.close();release();quit(0 if failures.is_empty() else 1)
