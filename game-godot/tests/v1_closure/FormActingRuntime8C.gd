extends SceneTree
## Real saved-action imports, existing public transformation input and pipeline.
## Initial aura/position/form are explicit fixtures, not earned Story evidence.
const IDs = preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output := ""
var rows: Array = []
var failures: Array = []
var pilot := false
func _init() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label);push_error(label)
func release() -> void:
	for slot in [1,2]:
		for key in ["left","right","up","down","jump","attack","special","shield","grab","dodge","taunt"]:Input.action_release("p%d_%s" % [slot,key])
func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("form_acting_runtime_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Controlled real BattleScene; actual saved source actions and GLBs; public inputs; initial aura/forms/spacing declared fixtures. No earned Story/native visual/device/human acceptance.","human_approved":false},"\t"));f.close()
func configure(p,d,fid: String,body: String,face: int) -> void:
	release();var gs=root.get_node("GameState");gs.p1_body_variant=body;gs.p2_body_variant=body
	p.configure(fid,1,false,9,Vector2(-150,240));d.configure(IDs[(IDs.find(fid)+1)%9],2,false,9,Vector2(150,240))
	for a in [p,d]:
		a.global_position=a.spawn_point;a.state_machine.enter("idle");a.move_runner.cancel();a.controls_enabled=true;a.invincible=false;a._hitstop=0;a.aura=100;a.damage_percent=0;a.velocity=Vector2.ZERO;a._input_edge_held.clear();a.shielding=false
	p.facing=face;d.facing=-face;p.model_3d.set_facing(face);d.model_3d.set_facing(-face)
	await frames(8)
func perform(p,form_id: String,label: String) -> void:
	var initial_facing: int=p.facing
	var control=p.model_3d.get_animation_controller()
	var source: Dictionary=control.get_form_acting_report()
	check(source.status=="verified_saved_export",label+":actual_saved_overlay")
	var scale_before: Vector3=p.model_3d._model_root.scale
	var root_before: Vector3=p.model_3d._model_root.position
	# Initial aura fixture required for the pre-existing transformation threshold.
	p.aura=100
	for key in ["shield","special","attack"]:Input.action_press("p1_"+key)
	await frames(2);release()
	check(p._transform_sequence_active,label+":public_input_started_pipeline")
	var paused_progress: float=control.get_form_acting_report().progress
	paused=true
	for pause_frame in range(3):await process_frame
	check(absf(float(control.get_form_acting_report().progress)-paused_progress)<.00001,label+":paused_pipeline_and_pose")
	paused=false
	var samples: Array=[]
	var preview_seen:=false
	for i in range(110):
		if not p._transform_sequence_active:break
		var player: AnimationPlayer=control.get_animation_player()
		var report: Dictionary=control.get_form_acting_report()
		check(str(report.sequence).begins_with("form_transform_"),label+":sequence_owned_clip")
		check(str(report.sequence).ends_with("_left")== (initial_facing<0),label+":correct_facing_track")
		check(absf(player.current_animation_position-player.current_animation_length*float(report.progress))<.001,label+":same_pipeline_phase")
		var presentation: Dictionary=p.model_3d._form_presentation_8c.snapshot()
		if presentation.preview_form==form_id:preview_seen=true
		if i%8==0:
			var sk: Skeleton3D=control.get_skeleton();var hand:=sk.find_bone("Hand_R")
			samples.append({"physics_frame":Engine.get_physics_frames(),"progress":report.progress,"time":player.current_animation_position,"hand_rotation":sk.get_bone_pose_rotation(hand),"presentation":presentation})
		await physics_frame
	check(p.get_current_form_id()==form_id and not p._transform_sequence_active,label+":existing_completion")
	await frames(4)
	var final: Dictionary=p.model_3d._form_presentation_8c.snapshot()
	check(preview_seen and final.installed_form==form_id and int(final.sockets)>0 and final.failures.is_empty(),label+":actual_GLTF_sockets_and_persistent_reveal")
	for socket in final.get("socket_correspondence",[]):check(float(socket.rest_max_component_error)<.00001,label+":source_to_imported_rest_correspondence")
	check(control.get_active_clip().begins_with("form_idle_"),label+":powered_idle_selected")
	var player: AnimationPlayer=control.get_animation_player();var time0:=player.current_animation_position
	await frames(6)
	check(absf(player.current_animation_position-time0)>.001,label+":idle_actually_advances")
	check(p.model_3d._model_root.scale==scale_before and p.model_3d._model_root.position==root_before,label+":original_anatomy_and_visual_root")
	# Real public movement and attack must immediately leave owned idle.
	Input.action_press("p1_right" if initial_facing>0 else "p1_left",.6);await frames(3);release()
	check(not control.get_active_clip().begins_with("form_idle_"),label+":movement_not_overridden")
	await frames(10);Input.action_press("p1_attack");await frames(3);release()
	check(not control.get_active_clip().begins_with("form_idle_") and not p._current_move.is_empty(),label+":attack_retains_gameplay_authority")
	await frames(50)
	rows.append({"fighter":p.fighter_id,"body":p.data.body_variant,"facing":p.facing,"target_form":form_id,"samples":samples,"final":final,"saved_source":source,"scope":"initial aura=100 fixture; public transform/movement/attack"});write(false)
func interrupt(p,d,fid: String,target: String,previous: String) -> void:
	await configure(p,d,fid,"female",-1)
	p.apply_form(previous);p.aura=100
	d.global_position=p.global_position+Vector2(-48,0);d.facing=1;d.model_3d.set_facing(1)
	var contacts: Array=[]
	var callback=func(a,b,info):
		if a==d and b==p:contacts.append(info.duplicate(true))
	d.hit_resolver.hit_confirmed.connect(callback)
	for key in ["shield","special","attack"]:Input.action_press("p1_"+key)
	await frames(3);release()
	check(p._transform_sequence_active,fid+target+":interrupt_fixture_public_start")
	Input.action_press("p2_right",.5);Input.action_press("p2_attack");await frames(2);release()
	for i in range(40):
		if not contacts.is_empty():break
		await physics_frame
	check(contacts.size()==1 and p.damage_percent>0,fid+target+":real_interrupt_contact")
	var report: Dictionary=p.model_3d.get_animation_controller().get_form_acting_report()
	var presentation: Dictionary=p.model_3d._form_presentation_8c.snapshot()
	check(not p._transform_sequence_active and report.sequence.is_empty(),fid+target+":pose_ownership_retired")
	check(p.get_current_form_id()==previous and presentation.preview_form.is_empty(),fid+target+":no_unearned_advance_or_preview")
	check(not p._form_audio_8c.active,fid+target+":audio_sequence_retired")
	rows.append({"fighter":fid,"body":"female","facing":-1,"case":"public_attack_interrupt","target":target,"previous_form":previous,"contacts":contacts,"acting":report,"presentation":presentation,"audio":p._form_audio_8c.snapshot()});write(false)
	d.hit_resolver.hit_confirmed.disconnect(callback)
	p.close_transformation_for_match_end()
	check(p._form_audio_8c.snapshot().playing==0,fid+target+":match_audio_cleanup")
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
			for face in ([1] if pilot else [1,-1]):
				await configure(p,d,fid,body,face)
				var ladder: Array=p.get_forms_doc().form_ladder
				for target in ladder.slice(1):await perform(p,str(target),fid+body+str(face)+str(target))
				p.close_transformation_for_match_end()
				check(not p._transform_sequence_active,fid+":match_owner_retired")
	for fid in (IDs.slice(0,1) if pilot else IDs):
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/forms/%s.json" % fid))
		for index in [1,2]:await interrupt(p,d,fid,str(doc.form_ladder[index]),str(doc.form_ladder[index-1]))
	check(before==JSON.stringify(campaign.progress),"Story:unchanged")
	release();write(true);quit(0 if failures.is_empty() else 1)
