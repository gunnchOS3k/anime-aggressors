extends "res://tests/v1_closure/FormActingRuntime8C.gd"
## Actual original morph imports and public transform input; controlled fixtures.
func facial_values(controller) -> Array:
	var values: Array = []
	for mesh in controller.meshes:
		for index in range(mesh.mesh.get_blend_shape_count()):values.append(mesh.get_blend_shape_value(index))
	return values

func facial_case(p, target: String, label: String) -> void:
	var model=p.model_3d
	var face=model._expression_controller
	check(face!=null and face.meshes.size()>0,label+":original_source_morphs_loaded")
	var original_scale: Vector3=model._model_root.scale
	var original_position: Vector3=model._model_root.position
	p.aura=100
	for key in ["shield","special","attack"]:Input.action_press("p1_"+key)
	await frames(3);release()
	check(p._transform_sequence_active,label+":public_input_started")
	var initial:=facial_values(face)
	paused=true
	for i in range(3):await process_frame
	check(initial==facial_values(face),label+":pause_does_not_advance_morphs")
	paused=false
	var samples: Array=[]
	var peak:=0.0
	while p._transform_sequence_active:
		var report: Dictionary=face.evidence()
		check(report.performance_owned,label+":phase_ownership")
		var control: Dictionary=model.get_animation_controller().get_form_acting_report()
		check(absf(float(report.performance_phase)-float(control.progress))<.00001,label+":shared_authority_phase")
		var total:=0.0
		for value in report.targets.values():total+=float(value)
		check(total<=1.00001 and total>=0,label+":normalized_blend_without_double_deformation")
		for mesh in face.meshes:
			for index in range(mesh.mesh.get_blend_shape_count()):
				var want:=float(report.targets.get(str(mesh.mesh.get_blend_shape_name(index)),0))
				check(absf(mesh.get_blend_shape_value(index)-want)<.00001,label+":actual_mesh_weights")
		peak=maxf(peak,total)
		if Engine.get_physics_frames()%12==0:samples.append(report)
		await physics_frame
	await frames(3)
	check(peak>.4,label+":expressive_source_keys_used")
	check(p.get_current_form_id()==target and not face.evidence().performance_owned,label+":completion_releases_face")
	check(face.form==target,label+":actual_form_not_stale_BASE")
	check(model._model_root.position==original_position and model._model_root.scale==original_scale,label+":no_anatomy_root_workaround")
	# Explicit ownership probes, not claims of earned hits/guard breaks.
	model._update_expression_for_state("shield_break")
	check(face.expression=="shock",label+":break_is_visible_shock")
	model.set_cinematic_expression("grief")
	model._transform_target_8c=target
	model.set_transform_progress(.6)
	check(face.expression=="grief" and not face.evidence().performance_owned,label+":cinematic_priority")
	model.set_cinematic_expression("")
	model.set_transform_progress(.6)
	model._update_expression_for_state("hurt_light")
	check(not face.evidence().performance_owned,label+":hurt_preempts_face")
	model.end_form_sequence()
	model._update_expression_for_state("idle")
	rows.append({"fighter":p.fighter_id,"body":model._body_variant,"facing":p.facing,"target":target,"samples":samples,"peak_total":peak,"morph_meshes":face.meshes.size(),"scope":"Actual source meshes; controlled aura100; public transform inputs; explicit presentation ownership probes, no earned Story/CPU/device/human claim"})
	write_facial(false)

func write_facial(done: bool) -> void:
	var f=FileAccess.open(output.path_join("facial_performance_8d.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"human_approved":false},"\t"));f.close()

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.items_enabled=false;gs.hazards_enabled=false;gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	var campaign=root.get_node("CampaignRuntime");var before:=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for fid in (IDs.slice(0,1) if pilot else IDs):
		for body in (["male"] if pilot else ["male","female"]):
			for facing in ([1] if pilot else [1,-1]):
				await configure(p,d,fid,body,facing)
				for target in p.get_forms_doc().form_ladder.slice(1):await facial_case(p,str(target),fid+body+str(facing)+str(target))
				p.close_transformation_for_match_end()
	check(before==JSON.stringify(campaign.progress),"Story:unchanged")
	release();write_facial(true);quit(0 if failures.is_empty() else 1)
