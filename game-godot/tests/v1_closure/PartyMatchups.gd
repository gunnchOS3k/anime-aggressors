extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
const Data=preload("res://scripts/data/data_loader.gd")
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for ai in range(IDs.size()):
		for di in range(IDs.size()):
			release();Input.action_release("p1_taunt")
			var fid:String=IDs[ai];var opponent:String=IDs[di];var face:int=1 if di%2==0 else -1
			var body:String="female" if ai%2==0 else "male";gs.p1_body_variant=body;gs.p2_body_variant=body
			for actor in [p,d]:
				actor.party_overdrive.reset("fixture");actor.move_runner.cancel();actor.projectile_spawner.clear_all()
			p.configure(fid,1,false,9,Vector2(-40,240));d.configure(opponent,2,false,9,Vector2(-40+48*face,240))
			p.global_position=Vector2(-40,240);d.global_position=Vector2(-40+48*face,240)
			for actor in [p,d]:
				actor.state_machine.enter("idle");actor.controls_enabled=true;actor.invincible=false;actor.shielding=false;actor.armor_frames_remaining=0
				actor.aura=0;actor.damage_percent=0;actor.velocity=Vector2.ZERO;actor._hitstop=0;actor._input_edge_held.clear();actor._recent_move_ids.clear();actor.combo_count=0
			p.facing=face;d.facing=-face;current_scene._battle_sim.body_spacing.previous_order.clear();items.clear_items()
			for ready in range(90):
				await physics_frame
				if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
			items.spawn_party_item("prism_heart",p.global_position+Vector2(0,-24));await frames(2)
			Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt");await frames(38)
			var guarded:bool=(ai+di)%2==0 and fid!="rook-ironside"
			if guarded:Input.action_press("p2_shield")
			contacts.clear();Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt")
			if fid=="rook-ironside":
				var incoming:Dictionary=Data.find_move(d.move_manifest,"forward_tilt")
				var input_frame:int=int(p._current_move.startup_frames)-int(incoming.startup_frames)+3
				for wait_frame in range(50):
					if p.move_runner.total_frame>=input_frame:break
					await physics_frame
				Input.action_press("p2_left" if face==1 else "p2_right",.5);Input.action_press("p2_attack");await frames(2)
				Input.action_release("p2_attack");Input.action_release("p2_left");Input.action_release("p2_right")
			for wait_frame in range(200):
				await physics_frame
				if p.party_overdrive.state=="BASE":break
			var label:String=fid+":"+opponent
			check(not contacts.is_empty(),label+":real_ultimate_contact")
			check(d.damage_percent==0 if guarded else d.damage_percent>0,label+":guard_or_body_outcome")
			var owners:Dictionary={}
			for info in contacts:
				check(info.blocked==guarded,label+":actual_defense_classification")
				var owner:String=str(info.get("projectile_instance_id",-1))+":"+str(info.move_id)
				check(not owners.has(owner),label+":one_damage_per_owner");owners[owner]=true
			check(p.party_overdrive.state=="BASE" and p.projectile_spawner.count()==0,label+":cleanup")
			rows.append({"fighter":fid,"opponent":opponent,"body":body,"facing":face,"guarded":guarded,"contacts":contacts.size(),"damage":d.damage_percent,"outcomes":contacts.map(func(info):return info.contact_result)})
			write(false)
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("party_matchups.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"81controlled ordered pair fixtures, public pickup/taunt/guard/attack; representative rotating body/facing, idleP2; no CPU/human balance/guaranteedcombo/earnedKO acceptance"},"\t"));f.close()
