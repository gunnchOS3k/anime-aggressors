extends SceneTree
## 81 ordered, reset matchup fixtures. Last form and 50.5 aura are EXPLICIT
## setup, not public activation or earned progression. Actual contacts use public
## tilt/guard controls. This is not active-CPU, guaranteed combo or balance approval.
const IDs = preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output := ""
var failures: Array=[]
var rows: Array=[]
var contacts: Array=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func release() -> void:
	for slot in [1,2]:
		for key in ["left","right","attack","shield","special"]: Input.action_release("p%d_%s" % [slot,key])
func write_result(complete: bool) -> void:
	var f=FileAccess.open(output.path_join("advancement_matchups.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":complete and failures.is_empty(),"complete":complete,"failures":failures,"rows":rows,"scope":"81 ordered matchup fixtures; one alternating body/facing per pair, not 324 configuration coverage. Explicit top-form/aura setup; public attack/guard input, idle P2. No human/CPU/earned acceptance."},"\t")); f.close()
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
	var gs=root.get_node("GameState")
	gs.mode="versus"; gs.stage_id="training-grid"; gs.p2_is_cpu=false; gs.stocks=9; gs.match_timer_seconds=0; gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle"); await frames(220)
	var p=current_scene.fighter1; var d=current_scene.fighter2
	p.hit_resolver.hit_confirmed.connect(func(a,b,info): if a==p and b==d: contacts.append(info.duplicate(true)))
	for ai in range(IDs.size()):
		for di in range(IDs.size()):
			release()
			var direction: int=1 if (ai+di)%2==0 else -1
			var body: String="male" if di%2==0 else "female"
			var shield: bool=di%2==1
			gs.p1_body_variant=body; gs.p2_body_variant=body
			p.configure(IDs[ai],1,false,9,Vector2(-40,240))
			d.configure(IDs[di],2,false,9,Vector2(-40+48*direction,240))
			# configure records the next spawn; it does not teleport live actors.
			p.global_position=Vector2(-40,240); d.global_position=Vector2(-40+48*direction,240)
			for actor in [p,d]:
				actor.move_runner.cancel(); actor.projectile_spawner.clear_all()
				actor.state_machine.enter("idle"); actor.controls_enabled=true; actor.invincible=false
				actor.shielding=false; actor.shield_health=100; actor.damage_percent=0
				actor.velocity=Vector2.ZERO; actor._hitstop=0; actor.hitstun_remaining=0
				actor.armor_frames_remaining=0; actor._jab_chain=0; actor.aura=0
			p.facing=direction; d.facing=-direction
			current_scene._battle_sim.body_spacing.previous_order.clear()
			await frames(12)
			var ladder: Array=p.get_forms_doc().form_ladder
			p.apply_form(str(ladder[-1])); p.aura=50.5
			contacts.clear()
			if shield: Input.action_press("p2_shield"); await frames(3)
			Input.action_press("p1_right" if direction==1 else "p1_left",0.5)
			Input.action_press("p1_attack"); await frames(2)
			Input.action_release("p1_attack"); Input.action_release("p1_right"); Input.action_release("p1_left")
			await frames(45); release()
			var label: String=IDs[ai]+":"+IDs[di]
			check(contacts.size()==1,label+":one_authoritative_contact")
			if not contacts.is_empty():
				check(str(contacts[0].contact_result)==("shield" if shield else "hit"),label+":defender_authority")
				check(p._current_move.get("form_id","")==ladder[-1],label+":top_form_move_executed")
				check(d.damage_percent==0 if shield else d.damage_percent>0,label+":damage_or_shield_policy")
			rows.append({"fighter":IDs[ai],"defender":IDs[di],"body":body,"facing":direction,"form":p.get_current_form_id(),"shield":shield,"move":p._current_move.get("move_id",""),"attacker_world":[p.global_position.x,p.global_position.y],"defender_world":[d.global_position.x,d.global_position.y],"contacts":contacts.size(),"result":contacts[0].get("contact_result","") if not contacts.is_empty() else "none","damage":d.damage_percent})
			write_result(false)
	write_result(true); print("ADVANCEMENT_MATCHUPS rows=",rows.size()," failures=",failures.size()); quit(0 if failures.is_empty() else 1)
