extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for fid in IDs:
		for kind in ["legacy0","legacy1","legacy2","prism_heart","BLACK","WHITE"]:
			var index:int=["legacy0","legacy1","legacy2","prism_heart","BLACK","WHITE"].find(kind)
			var body:String="female" if index%2==0 else "male";var face:int=1 if index%2==0 else -1
			Input.action_release("p2_taunt");await prepare(p,d,fid,body,face)
			if kind.begins_with("legacy"):
				var ladder:Array=d.get_forms_doc().get("form_ladder",[])
				d.apply_form(str(ladder[int(kind.trim_prefix("legacy"))]));d.aura=90
			else:
				items.clear_items();items.spawn_party_item("prism_heart" if kind=="prism_heart" else "puppet_seal",d.global_position+Vector2(0,-24),"WHITE" if kind=="WHITE" else "BLACK");await frames(2)
				Input.action_press("p2_taunt");await frames(2);Input.action_release("p2_taunt");await frames(38)
				check(d.party_overdrive.active(),fid+kind+":real_transformed_defender")
			contacts.clear();Input.action_press("p1_right" if face==1 else "p1_left",.5);Input.action_press("p1_attack");await frames(2)
			Input.action_release("p1_attack");Input.action_release("p1_right");Input.action_release("p1_left")
			for wait_frame in range(40):
				if p.move_runner.active and p.move_runner.total_frame>=int(p._current_move.startup_frames)-1:break
				await physics_frame
			Input.action_press("p2_shield");await frames(20);release()
			check(contacts.size()==1 and contacts[0].get("perfect_guard",false) and d.damage_percent==0,fid+kind+":one_actual_parry")
			check(not d.invincible,fid+kind+":no_hidden_immunity")
			if contacts.size()==1:
				var renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd").obtain(d)
				var primary:Array=renderer.history.filter(func(e):return e.event_id==contacts[0].combat_event_id and e.kind==24)
				check(primary.size()==1 and contacts[0].get("played_audio",{}).get("ok",false),fid+kind+":one_original_guard_primary_and_audio")
			rows.append({"fighter":fid,"body":body,"facing":face,"domain":kind,"legacy":d.get_current_form_id(),"party":d.party_overdrive.snapshot(),"guard_age":contacts[0].get("guard_age_frames",-1) if not contacts.is_empty() else -1});write(false)
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("perfect_guard_forms.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"54public shield/contact fixtures,9fighters x3legacy/cosmic +3temporaryParty states, rotating representative body/facing; not exhaustive Story boss/Gray, device or human acceptance"},"\t"));f.close()
