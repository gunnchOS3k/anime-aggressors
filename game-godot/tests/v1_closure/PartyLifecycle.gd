extends "res://tests/v1_closure/PerfectGuardRuntime.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--pilot":pilot=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=true;gs.hazards_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	var campaign=root.get_node("CampaignRuntime")
	var saved:PackedByteArray=FileAccess.get_file_as_bytes(campaign.save_path) if FileAccess.file_exists(campaign.save_path) else PackedByteArray()
	var progress:String=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;var items=current_scene._hazard_runtime;items._spawn_timer=100000
	for fid in (["rook-ironside"] if pilot else IDs):
		await prepare(p,d,fid,"male",1)
		p.configure(fid,1,false,9,p.global_position);d.configure("kaia-windrow",2,false,9,d.global_position)
		p.facing=1;d.facing=-1;p.controls_enabled=true;d.controls_enabled=true;p.invincible=false;d.invincible=false
		for ready in range(90):
			await physics_frame
			if p.is_on_floor() and d.is_on_floor() and p.state_machine.can_attack() and d.state_machine.can_attack():break
		# Real public attack interrupts36-frame item startup.
		items.spawn_party_item("prism_heart",p.global_position+Vector2(0,-24));await frames(2)
		Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt")
		var defender_input_state:String=d.state_machine.current_state
		Input.action_press("p2_left",.5);Input.action_press("p2_attack");await frames(2);release();await frames(25)
		var interrupted:bool=p.party_overdrive.state=="BASE" and p.damage_percent>0 and not p.invincible
		check(interrupted,fid+":startup_interrupt_without_immunity")
		await frames(40)
		# Existing legacy state is retained underneath temporary item priority.
		var ladder:Array=p.get_forms_doc().get("form_ladder",[])
		if not ladder.is_empty():p.apply_form(str(ladder[-1]))
		var legacy:String=p.get_current_form_id()
		p.aura=95
		items.spawn_party_item("puppet_seal",p.global_position+Vector2(0,-24),"WHITE");await frames(2)
		Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt");await frames(38)
		check(p.party_overdrive.active() and p.get_current_form_id()==legacy and not p.attempt_transform(),fid+":party_precedence_without_destroying_legacy")
		check(p.get_effective_combat_aura()==0 and p.perfect_guard.WINDOW_FRAMES==4,fid+":no_passive_stacking_or_bigger_parry")
		# Declared stock-loss fixture through the existing real lifecycle method.
		# This is cleanup evidence, never an earned competitive KO claim.
		p.lose_stock();check(p.party_overdrive.state=="BASE" and p.projectile_spawner.count()==0,fid+":stock_cleanup")
		await frames(85)
		check(not p.invincible and p.party_overdrive.state=="BASE",fid+":no_post_respawn_item_or_immunity")
		rows.append({"fighter":fid,"startup_interrupt":interrupted,"defender_input_state":defender_input_state,"legacy_underlay":legacy,"stock_cleanup":p.party_overdrive.state=="BASE" and not p.invincible,"scope":"public hit interruption plus explicit stock lifecycle fixture"});write(false)
	if pilot:release();write(true);quit(0 if failures.is_empty() else 1);return
	# One complete unaccelerated600-tick duration. No clocks or damage overridden.
	await prepare(p,d,"kaia-windrow","female",1)
	d.global_position.x+=250
	items.spawn_party_item("puppet_seal",p.global_position+Vector2(0,-24),"BLACK");await frames(2)
	Input.action_press("p1_taunt");await frames(2);Input.action_release("p1_taunt")
	while p.party_overdrive.state=="TRANSFORMATION_STARTUP":await physics_frame
	var begin:int=p.party_overdrive.clock
	check(p.party_overdrive.remaining==600,"full_duration_begins_at600")
	while p.party_overdrive.active():await physics_frame
	check(p.party_overdrive.clock-begin==600,"exact_natural600_frame_expiry")
	check(p.get_current_form_id().ends_with("BASE") and not p.invincible,"natural_expiry_restores_base")
	rows.append({"case":"natural_expiry","elapsed_frames":p.party_overdrive.clock-begin})
	# Pending acquisition cannot survive a closed round or a new match owner.
	items.spawn_party_item("prism_heart",p.global_position+Vector2(0,-24));await frames(2)
	p.close_transformation_for_match_end();await frames(2)
	check(p.party_overdrive.state=="BASE" and not p.party_overdrive.acquire("prism_heart","BLACK",999),"match_end_closes_party_activation")
	check(progress==JSON.stringify(campaign.progress),"no_Story_progress_mutation")
	var now:PackedByteArray=FileAccess.get_file_as_bytes(campaign.save_path) if FileAccess.file_exists(campaign.save_path) else PackedByteArray()
	check(saved==now,"no_Story_save_mutation")
	release();write(true);quit(0 if failures.is_empty() else 1)
func write(done:bool) -> void:
	var f=FileAccess.open(output.path_join("party_lifecycle.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":done and failures.is_empty(),"complete":done,"rows":rows,"failures":failures,"scope":"Isolated declared live fixtures; public damage interruption, legacy underlay, stock method, unaccelerated expiry and unchanged Story memory/save; not earned KO or Story acceptance"},"\t"));f.close()
