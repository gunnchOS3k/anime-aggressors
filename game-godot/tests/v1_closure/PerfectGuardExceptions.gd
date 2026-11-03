extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
const Data=preload("res://scripts/data/data_loader.gd")
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info):if a==p and b==d:contacts.append(info.duplicate(true)))
	for fid in IDs:
		await prepare(p,d,fid,"female",-1)
		Input.action_press("p1_grab");await frames(2);Input.action_release("p1_grab")
		for i in range(40):
			if p.move_runner.active and p.move_runner.total_frame>=int(p._current_move.startup_frames)-1:break
			await physics_frame
		Input.action_press("p2_shield");await frames(5)
		check(p.grabbed_target==d and d.grabbed_by==p and not d.perfect_guard.consumed,fid+":public_grab_bypasses_guard_window")
		# Release through genuine existing throw path, retaining one contact owner.
		Input.action_release("p2_shield");Input.action_press("p1_attack");await frames(2);release();await frames(45)
		check(contacts.size()==1 and contacts[0].contact_owner=="direct_throw" and not contacts[0].get("perfect_guard",false),fid+":throw_not_parried")
		rows.append({"fighter":fid,"case":"public_grab_throw","contacts":contacts.size()})
		await prepare(p,d,fid,"female",-1)
		p.configure("juno-spark",1,false,9,p.global_position);p.facing=-1
		d.global_position.x=p.global_position.x-140
		for ready in range(90):
			await physics_frame
			if p.is_on_floor() and p.state_machine.can_attack():break
		Input.action_press("p1_special");await frames(2);release()
		var shot
		for i in range(70):
			await physics_frame
			var live:Array=p.projectile_spawner.active_projectiles.filter(func(x):return is_instance_valid(x) and x.active)
			if not live.is_empty():
				shot=live[0]
				if absf(shot.global_position.x-d.global_position.x)<44:break
		Input.action_press("p2_shield");await frames(16);release()
		check(contacts.size()==1 and contacts[0].get("perfect_guard",false),fid+":public_projectile_guard")
		check(p.projectile_spawner.count()==0 and d.damage_percent==0,fid+":shot_retired_without_reflection")
		rows.append({"fighter":fid,"case":"public_projectile_guard","contacts":contacts.size(),"guard_age":contacts[0].get("guard_age_frames",-1) if not contacts.is_empty() else -1})
		# Exact same guard policy in every existing playable advancement state.
		var forms:Dictionary=d.get_forms_doc().get("forms",{})
		for form_id in forms:
			d.apply_form(str(form_id))
			check(d.perfect_guard.WINDOW_FRAMES==4,fid+":form_does_not_extend_guard")
		write(false)
	# Holding guard through an ordinary shield-stun recovery must not create a
	# fresh parry window. Only a new legal press may open the four-frame window.
	await prepare(p,d,"juno-spark","male",1)
	Input.action_press("p2_shield");await frames(12)
	var first_open:int=d.perfect_guard.opened
	Input.action_press("p1_right",.5);Input.action_press("p1_attack");await frames(2)
	Input.action_release("p1_attack");Input.action_release("p1_right");await frames(40)
	check(d.perfect_guard.opened==first_open,"held_shield_cannot_automatically_rearm_after_stun")
	rows.append({"case":"held_guard_after_shield_stun","first_open":first_open,"after":d.perfect_guard.opened})
	# Explicit swept-contact fixtures: Rook's one authorized piercer still
	# terminates on guard; PerfectGuard grants no general reflection/absorption.
	await prepare(p,d,"yin","male",1)
	p.configure("rook-ironside",1,false,9,p.global_position);p.facing=1
	Input.action_press("p2_shield");await frames(1);d.perfect_guard.reset();d.perfect_guard.begin();d.perfect_guard.clock=d.perfect_guard.opened
	var pierce=p.projectile_spawner.spawn_from_move(Data.find_move(p.move_manifest,"neutral_special_projectile"),100)
	pierce.global_position=d.global_position+Vector2(0,-20)
	await frames(1)
	check(not is_instance_valid(pierce) or not pierce.active,"Rook:piercing_stops_on_guard")
	check(d.damage_percent==0,"Rook:guard_no_damage")
	rows.append({"case":"Rook_explicit_piercing_guard","scope":"declared swept overlap fixture"})
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("perfect_guard_exceptions.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Public grab/throw/shot inputs with configured opponent geometry; explicit Rook swept overlap and form policy fixtures; no CPU/native/human acceptance"},"\t"));f.close()
