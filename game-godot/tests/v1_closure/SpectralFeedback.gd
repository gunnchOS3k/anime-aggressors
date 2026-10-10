extends SceneTree
## Source fixtures test presentation contracts. They are not combo or human-quality evidence.
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var failures: Array=[]
var rows: Array=[]
var output := ""
func _init() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	if not value: failures.append(label);push_error(label)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.p1_fighter_id="ember-vale";gs.p2_fighter_id="juno-spark";gs.p2_is_cpu=false;gs.battle_eval_mode=true;gs.battle_eval_max_frames=100000;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(15): await physics_frame
	var p=current_scene.fighter1
	var d=current_scene.fighter2
	p.controls_enabled=false;d.controls_enabled=false
	var renderer=Renderer.obtain(p)
	var bus=root.get_node("JuiceEventBus")
	var events: Array=[]
	bus.juice_event.connect(func(event,payload):events.append({"event":event,"payload":payload}))
	var bridge=load("res://scripts/visual/animation_event_bridge.gd").new();current_scene.add_child(bridge)
	bridge.emit_from_anim_event("active_start")
	check(events.size()==1 and events[0].event=="attack_swing","animation_activation_is_not_contact_or_hitstop")
	var rejected: Dictionary=p.combat_feedback.apply_hit(p,d,{"feedback":{"tier":"heavy"}},{"damage":9,"launch":Vector2(30,-30),"hitstop_frames":8})
	check(rejected.get("presentation_rejected","")=="unconfirmed_contact" and renderer.history.is_empty(),"unconfirmed_feedback_cannot_emit_contact_or_audio")
	# Ordinary input/physics whiff, with neither fighter frozen.
	p.invincible=false;d.invincible=false;p.global_position=Vector2(-220,260);d.global_position=Vector2(220,260)
	p.controls_enabled=true;Input.action_press("p1_attack")
	for i in range(3):await physics_frame
	Input.action_release("p1_attack")
	for i in range(50):await physics_frame
	var impacts:=0
	for h in renderer.history:
		if h.kind==0:impacts+=1
	check(impacts==0 and d.damage_percent==0,"real_public_input_whiff_has_no_contact_burst")
	p.controls_enabled=false;p.move_runner.cancel()
	for fid in Renderer.IDS:
		p.configure(fid,1,false,9,Vector2(-15,260))
		p.controls_enabled=false;p.invincible=false;d.invincible=false;d.shielding=false;d.armor_frames_remaining=0;d.damage_percent=0
		p.global_position=Vector2(-15,260);d.global_position=Vector2(15,260)
		p.training_play_move("heavy_attack")
		var move: Dictionary=p._current_move.duplicate(true)
		# Direct contact fixture isolated from the natural-collision captures.
		move["_contact_world"]=Vector2(9,232)
		var info: Dictionary=p.hit_resolver.resolve(p,d,move,0)
		check(not info.is_empty() and info.confirmed_contact and info.attacker_id==fid,fid+":confirmed_contract")
		check(info.contact_world==Vector2(9,232),fid+":world_contact_not_child_local")
		check(info.gameplay_frame==Engine.get_physics_frames() and info.has("counterhit"),fid+":frame_and_context")
		var count: int=renderer.history.size()
		check(p.hit_resolver.resolve(p,d,move,0).is_empty() and renderer.history.size()==count,fid+":move_target_deduplicated")
		check(not renderer.contact(info,d),fid+":renderer_event_deduplicated")
		var hit_rows: Array=[]
		for h in renderer.history:
			if h.event_id==info.combat_event_id:hit_rows.append(h)
		check(hit_rows.size()==1 and hit_rows[0].family==Renderer.FAMILIES[Renderer.IDS.find(fid)],fid+":unique_family_single_impact")
		d.shielding=true;d.state_machine.enter("shield_hold");p.training_play_move("heavy_attack")
		var damage_before: float=d.damage_percent
		var block: Dictionary=p.hit_resolver.resolve(p,d,p._current_move,0)
		check(block.contact_result=="shield" and block.launch==Vector2.ZERO and d.damage_percent==damage_before,fid+":shield_deflect_no_body_damage")
		check(renderer.history[-1].kind==1,fid+":shield_shape_distinct")
		d.shielding=false;d.state_machine.enter("idle");d.armor_frames_remaining=3;p.training_play_move("heavy_attack")
		var armor: Dictionary=p.hit_resolver.resolve(p,d,p._current_move,0)
		check(armor.contact_result=="armor" and armor.hitstop_frames==2 and d.damage_percent==damage_before,fid+":armor_preserved")
		d.armor_frames_remaining=0;d.invincible=true;p.training_play_move("heavy_attack");count=renderer.history.size()
		check(p.hit_resolver.resolve(p,d,p._current_move,0).is_empty() and renderer.history.size()==count,fid+":rejected_target_no_burst")
		d.invincible=false;p.training_play_move("neutral_special_projectile")
		var projectile=p.projectile_spawner.spawn_from_move(p._current_move,0)
		check(projectile!=null and projectile.uses_intentional_visual(),fid+":live_projectile_mesh")
		if projectile!=null:
			var start: Vector2=projectile.global_position
			var emission_count: int=renderer.history.size()
			for i in range(12):projectile.tick_sim_frame()
			if projectile.global_position==start:check(renderer.history.size()==emission_count,fid+":stationary_projectile_has_no_fake_motion_wake")
			for i in range(48):projectile.tick_sim_frame()
			check(projectile.global_position!=start,fid+":actual_flight")
			projectile._expire()
			check(not projectile.active and projectile._flight_slot==-1,fid+":expire_releases_emitter")
		p.projectile_spawner.clear_all()
		p.move_runner.cancel();p.state_machine.enter("aura_charge");p.aura=50;p._set_aura_vfx(true)
		var charge: int=p._spectral_charge_slot
		p._set_aura_vfx(true)
		check(charge>=0 and p._spectral_charge_slot==charge,fid+":one_charge_emitter")
		p.state_machine.enter("hurt_light")
		check(p._spectral_charge_slot==-1,fid+":charge_interruption_cleanup")
		rows.append({"fighter":fid,"family":Renderer.FAMILIES[Renderer.IDS.find(fid)],"contract":info,"blocked":block.contact_result,"armor":armor.contact_result})
		for i in range(20):await physics_frame
	# Stable analytic seeds, independent of engine instance IDs; bounded resource reuse.
	for i in range(65):await physics_frame
	var first: int=renderer.emit_effect("juno-spark",0,Vector2.ZERO,Vector2.RIGHT,64,.02,"seed-a")
	var family_seed: float=renderer.slots[first].seed
	var repeated=Renderer.new();current_scene.add_child(repeated)
	var second:=repeated.emit_effect("juno-spark",0,Vector2.ZERO,Vector2.RIGHT,64,.02,"different-instance")
	# Renderer sequence differs after roster fixtures; deterministic for a same seeded sequence.
	var comparison=Renderer.new();current_scene.add_child(comparison)
	var third:=comparison.emit_effect("juno-spark",0,Vector2.ZERO,Vector2.RIGHT,64,.02,"seed-c")
	check(repeated.slots[second].seed==comparison.slots[third].seed,"seed_independent_of_instance_and_event_ids")
	var settings_node=root.get_node("StoryDialogue")
	settings_node.set_option("reduced_particles",true);settings_node.set_option("reduced_flash",true);settings_node.set_option("high_contrast_vfx",true)
	for i in range(120):comparison.emit_effect("ember-vale",4,Vector2.ZERO,Vector2.RIGHT,30,.1)
	check(comparison.active_count()<=32 and comparison.slots.size()<=32,"reduced_pool_cap_32")
	await process_frame
	await process_frame
	print("ACCESSIBILITY_UNIFORMS ",comparison.slots[0].mesh.material.get_shader_parameter("flash")," ",comparison.slots[0].mesh.material.get_shader_parameter("density"))
	check(comparison.slots[0].mesh.material.get_shader_parameter("flash")==0.0 and comparison.slots[0].mesh.material.get_shader_parameter("density")>.19 and comparison.slots[0].mesh.material.get_shader_parameter("density")<.21,"reduced_flash_and_density_shader")
	for i in range(20):await physics_frame
	check(comparison.active_count()==0,"all_transient_slots_cleaned")
	var allocated: int=comparison.slots.size()
	comparison.emit_effect("yang",0,Vector2.ZERO)
	check(comparison.slots.size()==allocated and comparison.reused>0,"pool_reuse_without_node_growth")
	settings_node.set_option("reduced_particles",false);settings_node.set_option("reduced_flash",false);settings_node.set_option("high_contrast_vfx",false)
	var trail=load("res://scripts/visual/launch_trail_system.gd").new();d.add_child(trail)
	d._hitstop=0;d.state_machine.enter("launched");d.hitstun_remaining=.3
	trail.begin(d,"juno-spark","HIGH");d.global_position+=Vector2(20,-5);trail.follow(d,Vector2(90,-20))
	check(trail.emitted==1,"smoke_requires_real_displacement")
	d.state_machine.enter("idle");trail._physics_process(.016)
	check(not trail._active,"smoke_stops_when_control_returns")
	var file=FileAccess.open(output.path_join("spectral_runtime.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"ok":failures.is_empty(),"failures":failures,"fixtures":"source contact fixtures; natural public-input whiff; no combo-success claim","rows":rows,"pool":renderer.stats(),"parry_clash":"not supported by current collision rules; no fabricated outcomes"},"  ")+"\n");file.close()
	print("SPECTRAL_FEEDBACK ","PASS" if failures.is_empty() else "FAIL"," ",failures)
	current_scene.queue_free()
	for i in range(180):await physics_frame
	quit(0 if failures.is_empty() else 1)
