extends SceneTree
## Declared matchup/geometry/resource fixtures plus actual public attack inputs.
## Not ordinary earned Story, human balance approval or guaranteed combo proof.
const Data = preload("res://scripts/data/data_loader.gd")
const IDs = preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output := ""
var failures: Array = []
var rows: Array = []
var contacts: Array = []
var battle
var p
var d
var pilot := false
var public_only := false
# Trace221 reached the old recipe one frame AFTER the authored window. Send
# the opposing public shot two frames earlier; do not extend the real counter.
var counter_delay := 3
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func release() -> void:
	for slot in [1, 2]:
		for key in ["left", "right", "up", "down", "attack", "special", "shield", "jump", "grab", "dodge"]: Input.action_release("p%d_%s" % [slot,key])
func reset_pair(direction: int, distance := 48.0) -> void:
	release()
	for actor in [p,d]:
		actor.projectile_spawner.clear_all(); actor.move_runner.cancel(); actor.reset_fighter()
		actor.controls_enabled = true; actor.invincible = false; actor.shielding = false
		actor.velocity = Vector2.ZERO; actor._hitstop = 0; actor.hitstun_remaining = 0
		actor.armor_frames_remaining = 0; actor._jab_chain = 0; actor._input_edge_held.clear()
		actor.state_machine.enter("idle"); actor.hitbox.monitoring = false
	p.position = Vector2(-40,240); d.position = Vector2(-40+distance*direction,240)
	p.facing = direction; d.facing = -direction
	p.model_3d.set_facing(direction); d.model_3d.set_facing(-direction)
	battle._battle_sim.body_spacing.previous_order.clear()
	await frames(25); contacts.clear()
func write_result(complete: bool) -> void:
	var file = FileAccess.open(output.path_join("cosmic_kits.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":complete and failures.is_empty(),"complete":complete,"failures":failures,"rows":rows,"scope":"explicit reset/aura/overlap fixtures and real public attacks on live BattleScene rigs; no human approval, ordinary campaign, CPU match, guaranteed combo or platform acceptance"},"  "));file.close()
func run() -> void:
	#144 melee cases alone require192 simulation seconds at60Hz; retain a
	#bounded360s simulation watchdog for the full matrix and negative fixtures.
	create_timer(360).timeout.connect(func(): write_result(false); quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
		if arg=="--cosmic-pilot": pilot=true
		if arg=="--cosmic-public-only":public_only=true
		if arg.begins_with("--counter-delay="):counter_delay=int(arg.get_slice("=",1))
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle");await frames(180)
	battle=current_scene;p=battle.fighter1;d=battle.fighter2
	for actor in [p,d]:actor.hit_resolver.hit_confirmed.connect(func(a,b,info):contacts.append({"attacker":a.slot,"defender":b.slot,"info":info.duplicate(true)}))
	for fid in ([] if public_only else ["yin","yang"]):
		var manifest=Data.load_moves(fid)
		check(manifest.moves.size()==24,fid+":24existing_move_ids")
		check(Data.load_fighter(fid).combatTag!="burn_rushdown",fid+":not_Ember_profile")
		for move in manifest.moves:
			check(move.fighter_id==fid and move.owner_approved==false and move.status=="TUNING_CANDIDATE",fid+":"+move.move_id+":identity_and_candidate_gates")
		for opponent in (["juno-spark"] if pilot else IDs):
			for body in (["male"] if pilot else ["male","female"]):
				gs.p1_body_variant=body;gs.p2_body_variant=body
				p.configure(fid,1,false,9,Vector2.ZERO);d.configure(opponent,2,false,9,Vector2.ZERO)
				for direction in ([1] if pilot else [1,-1]):
					for heavy in [false,true]:
						await reset_pair(direction)
						Input.action_press("p1_attack")
						if heavy:Input.action_press("p1_special")
						await frames(1);release();await frames(55)
						var owned=contacts.filter(func(x):return x.attacker==1)
						var label=fid+":"+opponent+":"+body+":"+str(direction)+":"+str(heavy)
						check(owned.size()==1,label+":single_public_contact")
						if not owned.is_empty():
							check(owned[0].info.contact_result=="hit",label+":real_hit")
							check(owned[0].info.element==("void" if fid=="yin" else "radiance"),label+":own_element")
						rows.append({"fighter":fid,"opponent":opponent,"body":body,"facing":direction,"heavy":heavy,"contacts":owned.size(),"damage":d.damage_percent,"model":p.model_3d._proxy_model.scene_file_path})
					write_result(false)
	# Explicit active-window fixtures test the new defense against every roster
	# projectile, using the existing swept resolution and target rejection rules.
	for opponent in ([] if public_only else ["juno-spark"] if pilot else IDs):
		gs.p1_body_variant="female";p.configure("yin",1,false,9,Vector2.ZERO);d.configure(opponent,2,false,9,Vector2.ZERO)
		await reset_pair(1,100)
		p.aura=50 # Declared resource fixture, never an earned-playthrough claim.
		p.training_play_move("down_special")
		while not p.move_runner.is_active_phase(): await frames(1)
		var shot=d.projectile_spawner.spawn_from_move(Data.find_move(d.move_manifest,"neutral_special_projectile"),0)
		var late_damage: Array=[]
		shot.projectile_expired.connect(func(): shot._deliver_hit(p,p.position+Vector2(0,-20));late_damage.append(p.damage_percent))
		shot.global_position=p.position+Vector2(0,-20) # Declared overlap fixture.
		await frames(1)
		check(not is_instance_valid(shot) or not shot.active,opponent+":weak_shot_absorbed")
		check(p.cosmic_kit_history.size()==1 and p.cosmic_kit_history[0].aura_cost==25,opponent+":one_paid_counter")
		check(p.damage_percent==0 and contacts.is_empty(),opponent+":no_forged_hit_or_damage")
		check(late_damage==[0.0] and p.cosmic_kit_history.size()==1 and p.damage_percent==0,opponent+":late_callback_retired")
		rows.append({"case":"absorption","opponent":opponent,"events":p.cosmic_kit_history.duplicate(true),"scope":"declared resource/overlap fixture, not ordinary CPU timing acceptance"})
	# Explicit counterplay: stronger shots, insufficient meter, invulnerability,
	# same-team targeting and a second shot cannot become unlimited absorption.
	for kind in ([] if public_only else ["strong", "insufficient", "invulnerable", "ally", "second"]):
		p.configure("yin",1,false,9,Vector2.ZERO);d.configure("juno-spark",2,false,9,Vector2.ZERO)
		await reset_pair(1,100);p.aura=50 if kind!="insufficient" else 0
		p.training_play_move("down_special")
		while not p.move_runner.is_active_phase():await frames(1)
		if kind=="invulnerable":p.invincible=true
		if kind=="ally":p.set_meta("story_team","fixture");d.set_meta("story_team","fixture")
		var shot=d.projectile_spawner.spawn_from_move(Data.find_move(d.move_manifest,"neutral_special_projectile"),50 if kind=="strong" else 0)
		if kind=="second":
			shot._deliver_hit(p,p.position+Vector2(0,-20))
			shot=d.projectile_spawner.spawn_from_move(Data.find_move(d.move_manifest,"neutral_special_projectile"),0)
		shot._deliver_hit(p,p.position+Vector2(0,-20))
		if kind in ["invulnerable","ally"]:
			check(shot.active and p.damage_percent==0 and p.cosmic_kit_history.is_empty(),kind+":target_rejection_preserved")
		else:
			check(not shot.active and p.damage_percent>0,kind+":valid_unabsorbed_hit")
			check(p.cosmic_kit_history.size()==(1 if kind=="second" else 0),kind+":bounded_counter")
		rows.append({"case":"counterplay","kind":kind,"damage":p.damage_percent,"absorptions":p.cosmic_kit_history.size()})
		for actor in [p,d]:
			if actor.has_meta("story_team"):actor.remove_meta("story_team")
	# Public controls exercise the actual window timing; only position/meter are
	# declared fixture prerequisites. No direct move/contact forcing here.
	for body in (["female"] if pilot else ["male","female"]):
		for direction in ([1] if pilot else [1,-1]):
			gs.p1_body_variant=body;p.configure("yin",1,false,9,Vector2.ZERO);d.configure("juno-spark",2,false,9,Vector2.ZERO)
			await reset_pair(direction,100);p.aura=50
			var timing:Array=[]
			Input.action_press("p1_down");Input.action_press("p1_special");await frames(1);release();await frames(counter_delay)
			Input.action_press("p2_special");await frames(1);release()
			for tick in range(50):
				timing.append({"physics_frame":Engine.get_physics_frames(),"yin_state":p.state_machine.current_state,"yin_move":p.move_runner.current_move_id(),"yin_phase":p.move_runner.phase,"yin_phase_frame":p.move_runner.frame_in_phase,"aura":p.aura,"damage":p.damage_percent,"juno_move":d.move_runner.current_move_id(),"juno_phase":d.move_runner.phase,"shots":d.projectile_spawner.count()})
				await frames(1)
			check(p.cosmic_kit_history.size()==1 and p.damage_percent==0,"public_counter:"+body+str(direction))
			rows.append({"case":"public_counter","body":body,"direction":direction,"delay":counter_delay,"damage":p.damage_percent,"events":p.cosmic_kit_history.duplicate(true),"timing":timing,"scope":"public timing with declared50aura prerequisite; not earned campaign or activeCPU acceptance"})
	for body in (["female"] if pilot else ["male","female"]):
		for direction in ([1] if pilot else [1,-1]):
			gs.p1_body_variant=body;p.configure("yang",1,false,9,Vector2.ZERO);d.configure("juno-spark",2,false,9,Vector2.ZERO)
			await reset_pair(direction,140)
			Input.action_press("p1_down");Input.action_press("p1_special");await frames(1);release();await frames(12)
			var live=p.projectile_spawner.active_projectiles.filter(func(x):return is_instance_valid(x) and x.active)
			check(live.size()==1,"public_panel:"+body+str(direction)+":one_construct")
			if not live.is_empty():
				check(live[0].move_id=="down_special" and live[0].speed==0 and (live[0].position.x-p.position.x)*direction>0,"public_panel:"+body+str(direction)+":direction_and_stationary")
			rows.append({"case":"public_panel","body":body,"direction":direction,"active":live.size(),"model":p.model_3d._proxy_model.scene_file_path})
			await frames(50);check(p.projectile_spawner.count()==0,"public_panel:expiry")
	if public_only:
		write_result(true);quit(0 if failures.is_empty() else 1);return
	# Yang's finite construct uses existing projectile clash/damage/expiration.
	p.configure("yang",1,false,9,Vector2.ZERO);d.configure("juno-spark",2,false,9,Vector2.ZERO)
	await reset_pair(1,140)
	var panel=Data.find_move(p.move_manifest,"down_special")
	var first=p.projectile_spawner.spawn_from_move(panel,0)
	var first_position:Vector2=first.position
	await frames(8)
	var stationary:bool=first.position==first_position
	check(stationary,"Yang:stationary_construct")
	var second=p.projectile_spawner.spawn_from_move(panel,100)
	var replaced:bool=not first.active and second.active and p.projectile_spawner.count()==1
	check(replaced,"Yang:single_construct_limit")
	check(second.integrity==1 and second.damage==4 and not second.pierces_fighters,"Yang:finite_counterplay_and_no_piercing")
	await frames(40)
	var expired:bool=not is_instance_valid(second) or not second.active
	check(expired,"Yang:bounded_expiry")
	rows.append({"case":"construct","stationary":stationary,"old_retired":replaced,"expired":expired})
	for opponent in (["juno-spark"] if pilot else IDs):
		p.configure("yang",1,false,9,Vector2.ZERO);d.configure(opponent,2,false,9,Vector2.ZERO)
		await reset_pair(1,180)
		var construct=p.projectile_spawner.spawn_from_move(Data.find_move(p.move_manifest,"down_special"),0)
		var shot=d.projectile_spawner.spawn_from_move(Data.find_move(d.move_manifest,"neutral_special_projectile"),0)
		shot.global_position=construct.global_position # Declared clash overlap fixture.
		var before:int=battle._battle_sim.projectile_interactions.history.size()
		await frames(1)
		var events=battle._battle_sim.projectile_interactions.history
		check(events.size()>before and events[-1].result=="mutual_cancel",opponent+":construct_intercepts_quick")
		check(p.damage_percent==0 and d.damage_percent==0,opponent+":no_forged_fighter_damage")
		rows.append({"case":"construct_interception","opponent":opponent,"result":events[-1].result if not events.is_empty() else "missing"})
	release();write_result(true)
	print("COSMIC_KITS ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
