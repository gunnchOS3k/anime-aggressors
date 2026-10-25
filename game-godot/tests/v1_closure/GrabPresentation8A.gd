extends "res://tests/v1_closure/ElementalGrabThrow8A.gd"
var presentation_rows: Array=[]
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	p.combat_feedback.feedback_triggered.connect(func(info):feedback.append(info.duplicate(true)))
	d.damaged.connect(func(amount,_total):damages.append(amount))
	p.grab_event.connect(func(info):grab_events.append(info.duplicate(true)))
	var settings=root.get_node("StoryDialogue").settings;var previous=settings.duplicate(true)
	for fid in IDs:
		for mode in ["Full","Balanced","Reduced"]:
			settings.vfx_intensity=mode;settings.reduced_flash=mode=="Reduced";settings.reduced_particles=mode=="Reduced";settings.high_contrast_vfx=mode=="Reduced"
			var index: int=IDs.find(fid)+["Full","Balanced","Reduced"].find(mode)
			var direction: String=["forward","back","up","down"][index%4]
			p._grab_presentation.history.clear()
			await throw_case(p,d,fid,"female" if index%2==0 else "male",1 if index%2==0 else -1,direction)
			var observed: Array=p._grab_presentation.history.duplicate(true)
			var label=fid+":"+mode
			check(observed.filter(func(e):return e.phase=="hold").size()==1,label+":one_owned_hold")
			check(observed.filter(func(e):return e.phase=="release").size()==1,label+":one_directional_release")
			check(observed.filter(func(e):return e.phase=="audio" and e.detail.cue=="charge_release" and e.detail.playing).size()==1,label+":one_playing_release_layer")
			check(p._grab_presentation._hold_slot==-1,label+":no_lingering_hold")
			check(p._grab_presentation._voices.size()<=2,label+":bounded_audio")
			var renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(p)
			if not contacts.is_empty():
				var contact: Dictionary=contacts[0]
				var releases: Array=renderer.history.filter(func(h):return h.event_id==contact.combat_event_id+":release")
				check(releases.size()==1,label+":one_release_mesh")
				if releases.size()==1:
					var vector:=Vector2(releases[0].direction[0],releases[0].direction[1])
					check(vector.is_equal_approx(contact.contact_direction),label+":actual_launch_direction")
					check(str(releases[0].family)==str(p._grab_presentation.contract.fighters[fid].grammar),label+":correct_shape_family")
			presentation_rows.append({"fighter":fid,"mode":mode,"direction":direction,"phases":observed,"renderer":renderer.stats()})
			write(false)
	for key in previous:settings[key]=previous[key]
	# Actual match-close method must tear down a live paired hold and prevent late release.
	release();p.reset_position();d.reset_position();await frames(25)
	p.global_position=Vector2(-40,240);d.global_position=Vector2(-8,240);p.facing=1;d.facing=-1
	for a in [p,d]:a.controls_enabled=true;a.invincible=false;a.state_machine.enter("idle");a._input_edge_held.clear()
	Input.action_press("p1_grab");await frames(18);release()
	check(p.grabbed_target==d,"match_end:real_hold")
	var count_before: int=contacts.size()
	current_scene._finish_match(1)
	check(p.grabbed_target==null and d.grabbed_by==null and p._grab_presentation._hold_slot==-1,"match_end:paired_and_visual_teardown")
	p.execute_throw()
	check(contacts.size()==count_before,"match_end:no_late_throw")
	for voice in p._grab_presentation._voices:check(not voice.playing,"match_end:phase_audio_stopped")
	write(true);quit(0 if failures.is_empty() else 1)
func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("grab_presentation.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"presentation_rows":presentation_rows,"failures":failures,"scope":"27 controlled live-engine nine-fighter/accessibility contacts, original loaded audio and shader meshes; headless is not native visual/GPU/device/human acceptance"},"\t"));f.close()
