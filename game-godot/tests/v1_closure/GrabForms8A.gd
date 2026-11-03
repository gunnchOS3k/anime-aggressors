extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var defender=current_scene.fighter1;var owner=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	owner.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==owner and b==defender:contacts.append(info.duplicate(true)))
	for fid in IDs:
		for domain in ["legacy0","legacy1","legacy2","prism_heart","BLACK","WHITE"]:
			var n: int=["legacy0","legacy1","legacy2","prism_heart","BLACK","WHITE"].find(domain)
			var body: String="female" if n%2==0 else "male";var face: int=1 if n%2==0 else -1
			release();Input.action_release("p2_taunt");await prepare(defender,owner,fid,body,face)
			if domain.begins_with("legacy"):
				var ladder: Array=owner.get_forms_doc().get("form_ladder",[])
				owner.apply_form(str(ladder[int(domain.trim_prefix("legacy"))]));owner.aura=90
			else:
				items.clear_items();items.spawn_party_item("prism_heart" if domain=="prism_heart" else "puppet_seal",owner.global_position+Vector2(0,-24),"WHITE" if domain=="WHITE" else "BLACK");await frames(2)
				Input.action_press("p2_taunt");await frames(2);Input.action_release("p2_taunt");await frames(38)
				check(owner.party_overdrive.active(),fid+domain+":real_party_activation")
			# Acquisition uses the unchanged range, after the real item transform has settled.
			defender.global_position=owner.global_position+Vector2(32*owner.facing,0)
			var before: Dictionary=owner.party_overdrive.snapshot()
			contacts.clear();Input.action_press("p2_grab")
			for wait_frame in range(35):
				if owner.move_runner.active and owner.move_runner.total_frame>=int(owner._current_move.get("startup_frames",4))-1:break
				await physics_frame
			Input.action_press("p1_shield")
			for wait_frame in range(30):
				await physics_frame
				if owner.grabbed_target==defender:break
			Input.action_release("p2_grab");Input.action_release("p1_shield")
			var label=fid+":"+domain
			check(owner.grabbed_target==defender and defender.grabbed_by==owner,label+":fresh_guard_cannot_prevent_normal_grab")
			check(not defender.invincible,label+":no_new_immunity")
			var held_slot: int=owner._grab_presentation._hold_slot
			check(held_slot>=0,label+":charged_form_hold_feedback")
			Input.action_press("p2_attack");await frames(3);release()
			check(contacts.size()==1 and contacts[0].contact_owner=="direct_throw" and not contacts[0].get("perfect_guard",false),label+":one_ordinary_throw_not_parry")
			check(owner.grabbed_target==null and defender.grabbed_by==null and owner._grab_presentation._hold_slot==-1,label+":release_cleanup")
			rows.append({"fighter":fid,"body":body,"facing":owner.facing,"domain":domain,"actual_legacy":owner.get_current_form_id(),"party_before":before,"contact":contacts[0] if not contacts.is_empty() else {},"earned_unlock":false})
			await frames(48);write(false)
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("grab_forms.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"54 controlled public-grab/release fixtures: nine fighters x three existing legacy/cosmic ladders and three temporary Party states; rotating bodies/facings; no earned Story forms, boss kits or full form/body/facing product claimed"},"\t"));f.close()
