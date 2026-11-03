extends SceneTree
## 81 ordered, reset matchup fixtures. Last form and 50.5 aura are EXPLICIT
## setup, not public activation or earned progression. Actual contacts use public
## tilt/guard controls. This is not active-CPU, guaranteed combo or balance approval.
const IDs = preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output := ""
var failures: Array=[]
var rows: Array=[]
var contacts: Array=[]
var case_limit := 81
var match_end_verified := false
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
	f.store_string(JSON.stringify({"PASS":complete and failures.is_empty() and rows.size()==case_limit,"complete":complete,"expected_cases":case_limit,"match_end_verified":match_end_verified,"failures":failures,"rows":rows,"scope":"Bounded ordered matchup fixtures; one alternating body/facing per pair, not 324 configuration coverage. Explicit top-form/aura setup; public attack/guard input, idle P2. One explicit match-end callback fixture, not an earned win. No human/CPU/earned acceptance."},"\t")); f.close()
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
		if arg.begins_with("--case-limit="): case_limit=int(arg.get_slice("=",1))
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
				actor._recent_move_ids.clear(); actor.combo_count=0
			p.facing=direction; d.facing=-direction
			current_scene._battle_sim.body_spacing.previous_order.clear()
			for i in range(90):
				await physics_frame
				if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack(): break
			var grounded: bool=p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack()
			check(grounded,IDs[ai]+":"+IDs[di]+":ground_fixture_ready")
			var ladder: Array=p.get_forms_doc().form_ladder
			p.apply_form(str(ladder[-1])); p.aura=50.5
			contacts.clear()
			if shield: Input.action_press("p2_shield"); await frames(3)
			Input.action_press("p1_right" if direction==1 else "p1_left",0.5)
			Input.action_press("p1_attack"); await frames(2)
			Input.action_release("p1_attack"); Input.action_release("p1_right"); Input.action_release("p1_left")
			await frames(45); release()
			var label: String=IDs[ai]+":"+IDs[di]
			var expected_damage: float=float(p._current_move.get("damage",0))*p.get_damage_dealt_mult()*float(gs.damage_ratio)
			# Existing Ember confirm burn is a separate, explicit runtime hook.
			if not contacts.is_empty(): expected_damage+=float(contacts[0].get("burn_trail",0))*0.35
			check(contacts.size()==1,label+":one_authoritative_contact")
			if not contacts.is_empty():
				check(str(contacts[0].contact_result)==("shield" if shield else "hit"),label+":defender_authority")
				check(p._current_move.get("form_id","")==ladder[-1],label+":top_form_move_executed")
				check(d.damage_percent==0 if shield else d.damage_percent>0,label+":damage_or_shield_policy")
				check(is_equal_approx(float(contacts[0].damage),expected_damage),label+":resolved_form_damage_not_scaled_twice")
			rows.append({"fighter":IDs[ai],"defender":IDs[di],"body":body,"facing":direction,"form":p.get_current_form_id(),"shield":shield,"move":p._current_move.get("move_id",""),"attacker_world":[p.global_position.x,p.global_position.y],"defender_world":[d.global_position.x,d.global_position.y],"contacts":contacts.size(),"result":contacts[0].get("contact_result","") if not contacts.is_empty() else "none","damage":d.damage_percent,"resolved_move_damage":p._current_move.get("damage",0),"expected_single_pass_damage":expected_damage,"confirmed_damage":contacts[0].get("damage",0) if not contacts.is_empty() else 0})
			write_result(false)
			if not grounded or rows.size()>=case_limit:
				if grounded: await verify_match_end(p,gs)
				write_result(true); quit(0 if failures.is_empty() else 1); return
	write_result(true); print("ADVANCEMENT_MATCHUPS rows=",rows.size()," failures=",failures.size()); quit(0 if failures.is_empty() else 1)

func verify_match_end(p,gs) -> void:
	p.apply_form(str(p.get_forms_doc().form_ladder[0])); p.aura=100
	Input.action_press("p1_shield"); Input.action_press("p1_special"); Input.action_press("p1_attack")
	await frames(2); release()
	check(p._transform_sequence_active,"match_end:public_start")
	gs.battle_eval_mode=true # Isolated fixture avoids a career record.
	current_scene._finish_match(1)
	p.tick_transform_pipeline(2.0,false) # Explicit stale-callback negative probe.
	check(not p._transform_sequence_active and not p.can_start_transform_sequence(),"match_end:pending_and_new_activation_retired")
	check(p.get_current_form_id()==p.get_forms_doc().form_ladder[0],"match_end:no_delayed_upgrade")
	match_end_verified=true
