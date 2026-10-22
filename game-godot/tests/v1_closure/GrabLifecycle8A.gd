extends SceneTree
## Declared positioning fixtures; acquisition/mash use public inputs. Not earned play or art acceptance.
var output := ""
var failures: Array = []
var rows: Array = []
var events: Array = []
func _init() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func release() -> void:
	for slot in [1,2]:
		for key in ["attack","grab","jump","shield","special","up","down","left","right"]: Input.action_release("p%d_%s" % [slot,key])
func prepare(p,d) -> void:
	release()
	# Explicit fixture teardown, never treated as proof of runtime cleanup.
	p.grabbed_target=null; p.grabbed_by=null; d.grabbed_target=null; d.grabbed_by=null
	p.move_runner.cancel(); d.move_runner.cancel()
	p.configure("kaia-windrow",1,false,9,Vector2(-40,240)); d.configure("juno-spark",2,false,9,Vector2(-8,240))
	p.global_position=Vector2(-40,240);d.global_position=Vector2(-8,240)
	for actor in [p,d]:
		actor.velocity=Vector2.ZERO;actor.invincible=false;actor.controls_enabled=true;actor.shielding=false
		actor._hitstop=0;actor.hitstun_remaining=0;actor.aura=0;actor.damage_percent=0
		actor._input_edge_held.clear();actor.state_machine.enter("idle")
	p.facing=1;d.facing=-1
	for ready in range(100):
		await physics_frame
		if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
	await frames(2)
	events.clear()
func acquire(p,d) -> bool:
	Input.action_press("p1_grab")
	for i in range(30):
		await physics_frame
		if p.grabbed_target==d:break
	Input.action_release("p1_grab")
	return p.grabbed_target==d and d.grabbed_by==p
func record(label: String,p,d) -> void:
	rows.append({"case":label,"owner_holding":p.grabbed_target==d,"victim_held":d.grabbed_by==p,"owner_state":p.state_machine.current_state,"victim_state":d.state_machine.current_state,"victim_move_active":d.move_runner.active,"events":events.duplicate(true)})
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	p.grab_event.connect(func(info):events.append(info.duplicate(true)))
	await prepare(p,d)
	check(await acquire(p,d),"mash:genuine_grab")
	for i in range(4):
		Input.action_press("p2_attack");await frames(2);Input.action_release("p2_attack");await frames(2)
	check(p.grabbed_target==null and d.grabbed_by==null,"mash:reciprocal_escape")
	record("mash",p,d)
	await prepare(p,d)
	# Stagger public presses so the grab acquires during the defender's startup.
	Input.action_press("p1_grab");await frames(3)
	Input.action_press("p2_attack");await frames(2);Input.action_release("p2_attack")
	check(d.move_runner.active,"startup:real_defender_move")
	check(await acquire(p,d),"startup:genuine_grab")
	check(not d.move_runner.active and not d.hitbox.monitoring,"startup:held_move_cancelled")
	await frames(25)
	check(p.grabbed_target==d and d.grabbed_by==p and d.state_machine.current_state=="grab_hold","startup:hold_ownership_stable")
	check(events.filter(func(e):return e.get("result","")=="success").size()==1,"startup:one_acquisition")
	check(events.filter(func(e):return e.get("result","")=="whiff").is_empty(),"startup:no_false_whiff_after_acquisition")
	record("startup",p,d)
	await prepare(p,d)
	Input.action_press("p1_grab");Input.action_press("p2_grab");await frames(20);release()
	check(not (p.grabbed_target==d and d.grabbed_target==p),"simultaneous:no_mutual_ownership_cycle")
	record("simultaneous",p,d)
	await prepare(p,d);check(await acquire(p,d),"hurt:genuine_grab")
	# Direct receive fixture isolates holder interruption, not additional authoritative damage proof.
	p.receive_hit(d,{"damage":1.0,"launch":Vector2(-80,-40),"hitstop_frames":2,"move_id":"jab_1"})
	await frames(4)
	check(p.grabbed_target==null and d.grabbed_by==null,"hurt:reciprocal_release")
	check(p.state_machine.current_state!="grab_hold","hurt:cannot_restore_hold")
	record("hurt",p,d)
	for operation in ["reset_position","configure","match_end"]:
		for side in ["owner","victim"]:
			await prepare(p,d);check(await acquire(p,d),operation+":"+side+":genuine_grab")
			var actor=p if side=="owner" else d
			if operation=="configure":actor.configure(actor.fighter_id,actor.slot,false,9,actor.global_position)
			elif operation=="match_end":actor.close_transformation_for_match_end()
			else:actor.reset_position()
			check(p.grabbed_target==null and d.grabbed_by==null,operation+":"+side+":reciprocal_release")
			record(operation+":"+side,p,d)
	release()
	var f=FileAccess.open(output.path_join("grab_lifecycle.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"Declared positioning/receive-hit fixtures; genuine public grab/mash controls; not CPU or visual acceptance"},"\t"));f.close()
	print("GRAB_LIFECYCLE_8A ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size())
	quit(0 if failures.is_empty() else 1)
