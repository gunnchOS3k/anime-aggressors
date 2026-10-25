extends "res://tests/v1_closure/ElementalGuard8C.gd"
## Additional controlled form/Party, sustained-depletion and projectile coverage.
func write(done: bool) -> void:
	var f=FileAccess.open(output.path_join("guard_domains_8c.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Controlled public inputs in real BattleScene. Explicit initial forms/durability/geometry; Party uses actual item pickup/taunt. Idle opponents; no earned Story, CPU/native/device/human acceptance."},"\t"));f.close()
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):
		if a==p and b==d:contacts.append(info.duplicate(true)))
	d.shield_event.connect(func(event):_shield_events.append(event.duplicate(true)))
	for fid in IDs:
		for domain in ["legacy0","legacy1","legacy2","prism_heart","BLACK","WHITE"]:
			var index: int=["legacy0","legacy1","legacy2","prism_heart","BLACK","WHITE"].find(domain)
			await _ready_pair(p,d,fid,"female" if index%2==0 else "male",1)
			if domain.begins_with("legacy"):
				d.apply_form(str(d.get_forms_doc().form_ladder[int(domain.trim_prefix("legacy"))]))
			else:
				items.clear_items();items.spawn_party_item("prism_heart" if domain=="prism_heart" else "puppet_seal",d.global_position+Vector2(0,-24),"WHITE" if domain=="WHITE" else "BLACK")
				await frames(2);Input.action_press("p2_taunt");await frames(2);Input.action_release("p2_taunt");await frames(38)
				check(d.party_overdrive.active(),fid+domain+":actual_party_activation")
			Input.action_press("p2_shield");await frames(12);await _strike(p,1)
			check(await _wait_contact(1),fid+domain+":guard_contact")
			if not contacts.is_empty():check(contacts[0].contact_result=="shield" and d.damage_percent==0,fid+domain+":guard_ownership")
			check(d._guard_presentation.snapshot().guarding,fid+domain+":elemental_guard_active")
			# Explicit initial-durability fixture; only existing held-shield decay
			# may cross zero and enter actual SHIELD_BREAK. No direct state call.
			await frames(22);d.shield_health=.4;_shield_events.clear()
			for i in range(60):
				if d.state_machine.current_state=="shield_break":break
				await physics_frame
			check(d.state_machine.current_state=="shield_break",fid+domain+":natural_sustained_shield_break")
			check(_shield_events.filter(func(e):return e.result=="shield_break").size()==1,fid+domain+":one_break_event")
			var before: Dictionary=d._guard_presentation.snapshot()
			d.reset_fighter();await frames(2)
			check(not d.shield_break_8c.active and not d.shield_break_8c.needs_guard_release,fid+domain+":respawn_cleanup")
			rows.append({"fighter":fid,"domain":domain,"form":d.get_current_form_id(),"guard_contact":contacts[0] if not contacts.is_empty() else {},"break":before,"initial_durability_fixture":.4});write(false)
		await _ready_pair(p,d,fid,"female",-1)
		# Public quick shot into a held shield; no synthetic contact callback.
		Input.action_press("p2_shield");await frames(12)
		Input.action_press("p1_special");await frames(2);Input.action_release("p1_special")
		check(await _wait_contact(1),fid+":public_projectile_contact")
		if not contacts.is_empty():
			check(contacts[0].contact_result=="shield" and not contacts[0].get("perfect_guard",false),fid+":projectile_guard_separation")
		var count:=contacts.size();await frames(35)
		check(contacts.size()==count and count==1,fid+":no_late_projectile_guard_damage")
		rows.append({"fighter":fid,"case":"quick_projectile_guard","contacts":contacts.duplicate(true)});write(false)
	release();write(true);quit(0 if failures.is_empty() else 1)
