extends SceneTree
## All18 rigs/both facings; public charge/release/movement, idle-target lifecycle
## fixture. Explicit clear/respawn setups are not competitive or Story evidence.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var failures: Array=[]
var rows: Array=[]
func _init() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func release_inputs() -> void:
	for key in ["left","right","special","shield","jump","attack"]:Input.action_release("p1_"+key)
func evidence(p) -> Dictionary:
	return p.model_3d.get_empowerment_evidence() if p.model_3d.has_method("get_empowerment_evidence") else {}
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var p=current_scene.fighter1;current_scene.fighter2.controls_enabled=false;current_scene.fighter2.position.x=440
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			for facing in [1,-1]:
				release_inputs();gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-100,240));p.move_runner.cancel();p.state_machine.enter("idle");p.controls_enabled=true;p.invincible=false;p.clear_aura();p.velocity=Vector2.ZERO;p._hitstop=0;p.facing=facing
				for i in range(40):await physics_frame
				var label: String=fid+":"+body+":"+str(facing)
				check(not evidence(p).get("active",false),label+":zero_meter_is_calm")
				Input.action_press("p1_special");Input.action_press("p1_shield")
				var tiers: Array=[]
				for frame in range(280):
					await physics_frame
					if frame%30==0:tiers.append({"amount":p.aura,"evidence":evidence(p)})
					if p.aura>=100:break
				for i in range(3):await physics_frame
				var full:=evidence(p)
				check(p.aura==100,label+":public_charge_reaches_real100")
				check(full.get("active",false) and full.get("super_ready",false),label+":actual_full_presentation")
				Input.action_release("p1_special");Input.action_release("p1_shield")
				for i in range(12):await physics_frame
				var idle:=evidence(p)
				check(idle.get("active",false) and not idle.get("super_ready",true),label+":release_persists_but_real_decay_is_not_max")
				check(p._elemental_audio.charge==null,label+":charge_loop_stops_on_release")
				var before_move: Vector2=p.position
				Input.action_press("p1_right" if facing==1 else "p1_left",.55)
				for i in range(18):await physics_frame
				var moving:=evidence(p)
				check((p.position-before_move).length()>1 and moving.get("active",false),label+":real_empowered_movement")
				check(p._elemental_audio.ambience!=null and p._elemental_audio.ambience.playing,label+":single_owned_ambience")
				var ambient_id: int=p._elemental_audio.ambience.get_instance_id()
				for i in range(4):await physics_frame
				check(p._elemental_audio.ambience.get_instance_id()==ambient_id,label+":ambience_does_not_stack")
				Input.action_press("p1_jump")
				for i in range(8):await physics_frame
				release_inputs()
				var airborne:=evidence(p)
				check(not p.is_on_floor() and airborne.get("active",false),label+":airborne_aura_survives")
				for i in range(85):await physics_frame
				check(p.state_machine.can_attack(),label+":landing_returns_control")
				var options=root.get_node("StoryDialogue");var old_options: Dictionary=options.settings.duplicate(true)
				var intensity_rows: Array=[]
				for mode in ["Full","Balanced","Reduced"]:
					options.settings.vfx_intensity=mode
					options.settings.reduced_flash=mode=="Reduced";options.settings.reduced_particles=mode=="Reduced";options.settings.high_contrast_vfx=mode=="Reduced"
					for i in range(3):await process_frame
					intensity_rows.append(evidence(p))
				check(intensity_rows[0].vertices>intensity_rows[1].vertices and intensity_rows[1].vertices>intensity_rows[2].vertices,label+":bounded_intensity_geometry")
				check(intensity_rows[2].reduced_flash and intensity_rows[2].high_contrast,label+":accessible_state")
				options.settings=old_options
				var old_mesh_ref: WeakRef=weakref(p.model_3d._body_aura)
				p.model_3d.configure(p.data,body)
				for i in range(4):await process_frame
				check(old_mesh_ref.get_ref()==null and evidence(p).active,label+":model_swap_retires_old_geometry")
				var before_pause: int=evidence(p).generation
				paused=true
				for i in range(3):await process_frame
				check(evidence(p).generation==before_pause,label+":pause_freezes_presentation")
				paused=false
				p.state_machine.enter("ko")
				for i in range(3):await process_frame
				check(not evidence(p).active and p._elemental_audio.ambience==null,label+":ko_hides_and_stops_loop")
				p.state_machine.enter("idle")
				p.clear_aura()
				for i in range(3):await physics_frame
				check(not evidence(p).get("active",true),label+":depletion_cleanup")
				check(p._elemental_audio.ambience==null and evidence(p).vertices==0,label+":depleted_resources_inactive")
				rows.append({"fighter":fid,"body":body,"facing":facing,"charging_tiers":tiers,"full":full,"released_idle":idle,"movement":moving,"airborne":airborne,"intensity":intensity_rows,"depleted":evidence(p),"scope":"public charging/movement; explicit lifecycle setup, idle defender; no competitive/Story acceptance"})
	var f=FileAccess.open(output.path_join("persistent_empowerment.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows},"  "));f.close()
	print("PERSISTENT_EMPOWERMENT ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
