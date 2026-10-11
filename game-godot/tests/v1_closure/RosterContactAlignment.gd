extends SceneTree
## Live BattleScene geometry fixture, public attack controls, idle geometry target.
## This measures reach; it cannot certify active-CPU combos or artistic approval.
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var baseline := ""
var rows: Array=[]
var failures: Array=[]
var active_case: Dictionary={}
var p
var d
var contacts: Array=[]
var interrupted := false
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func release_inputs() -> void:
	for slot in [1,2]:
		for key in ["attack","special","left","right","up","down","shield"]: Input.action_release("p%d_%s"%[slot,key])
func projected(model,sk,name: String) -> Vector2:
	var pixel: Vector2=model._camera.unproject_position(sk.to_global(sk.get_bone_global_pose(sk.find_bone(name)).origin))
	var size: Vector2=Vector2(model._viewport.size)
	return model._display.to_global(pixel-size*.5+model._display.offset)
func limbs(model) -> Dictionary:
	var sk=model.get_animation_controller().get_skeleton(); sk.force_update_all_bone_transforms()
	var out: Dictionary={}
	for name in ["Hand_L","Hand_R","Foot_L","Foot_R"]:
		var point: Vector2=projected(model,sk,name);out[name]=[point.x,point.y]
	return out
func distance_to_rect(point: Vector2,rect: Rect2) -> float:
	return point.distance_to(Vector2(clampf(point.x,rect.position.x,rect.end.x),clampf(point.y,rect.position.y,rect.end.y)))
func rect_json(rect: Rect2) -> Array: return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
func observe(attacker,defender,info: Dictionary) -> void:
	if attacker==p and defender==d:
		var copy: Dictionary=info.duplicate(true)
		copy["attack_bounds"]=p.hit_resolver._world_bounds(p.get_node("Hitbox/HitShape"))
		copy["hurt_bounds"]=p.hit_resolver._world_bounds(d.get_node("Hurtbox/HurtShape"))
		copy["runtime_frame"]=p.move_runner.total_frame
		copy["runtime_timing"]={"startup":p.move_runner.move_data.startup_frames,"active":p.move_runner.move_data.active_frames,"recovery":p.move_runner.move_data.recovery_frames}
		contacts.append(copy)
		measure(copy,active_case.duplicate(true))
func measure(info: Dictionary,context: Dictionary) -> void:
	var model=p.model_3d;var controller=model.get_animation_controller();var player=controller.get_animation_player()
	var key: String=player.current_animation;var time: float=player.current_animation_position
	var after: Dictionary=limbs(model)
	var before: Dictionary={}
	var mid: String=info.move_id
	if player.has_animation("geometry_baseline/"+mid):
		player.play("geometry_baseline/"+mid,0);player.seek(float(info.runtime_frame)/60,true)
		before=limbs(model)
		player.play(key,0);player.seek(time,true)
	var overlap: Rect2=info.attack_bounds.intersection(info.hurt_bounds)
	var target: Vector2=info.contact_world
	var after_gap:=INF;var before_gap:=INF;var surface_gap:=INF
	for name in ["Hand_L","Hand_R"]:
		var h:=Vector2(after[name][0],after[name][1]);after_gap=minf(after_gap,h.distance_to(target));surface_gap=minf(surface_gap,distance_to_rect(h,overlap))
		if before.has(name): before_gap=minf(before_gap,Vector2(before[name][0],before[name][1]).distance_to(target))
	var clip: Dictionary=controller._choreography_timing.get(mid,{})
	var first_entry: bool=int(info.runtime_frame) in [int(info.runtime_timing.startup),int(info.runtime_timing.startup)+1]
	if first_entry and not clip.is_empty(): check(absf(time-float(clip.contact_frame)/60)<.0001,str(context)+":contact_clock")
	context.merge({"event_id":info.combat_event_id,"move":mid,"result":info.contact_result,"runtime_frame":info.runtime_frame,"runtime_timing":info.runtime_timing,"animation_time_s":time,"authored_contact_frame":clip.get("contact_frame",-1),"contact_world":[target.x,target.y],"attack_bounds":rect_json(info.attack_bounds),"hurt_bounds":rect_json(info.hurt_bounds),"overlap_bounds":rect_json(overlap),"limbs_world":after,"baseline_limbs_world":before,"wrist_to_overlap_center_px":after_gap,"baseline_wrist_to_overlap_center_px":before_gap if before_gap<INF else -1,"wrist_to_overlap_surface_px":surface_gap,"wrist_in_real_overlap":surface_gap<.0001,"reach_status":"GEOMETRY_DIAGNOSTIC_NO_ARTISTIC_PASS_THRESHOLD","model_path":model._proxy_model.scene_file_path,"mesh_yaw":model._proxy_model.rotation_degrees.y})
	rows.append(context)
func reset_case(facing: int,kind: String) -> void:
	release_inputs();p.move_runner.cancel();d.move_runner.cancel();p.projectile_spawner.clear_all();d.projectile_spawner.clear_all()
	p.global_position=Vector2(-80,240);d.global_position=Vector2(-80+facing*(150 if kind=="whiff" else 42),240)
	for actor in [p,d]:
		actor.velocity=Vector2.ZERO;actor._hitstop=0;actor.hitstun_remaining=0;actor.damage_percent=0;actor.invincible=false;actor.shielding=false;actor.aura=0;actor.state_machine.enter("idle");actor._input_edge_held.clear();actor.hitbox.monitoring=false;actor.armor_frames_remaining=0
	p.controls_enabled=true;d.controls_enabled=true;p.facing=facing;d.facing=-facing;p.model_3d.set_facing(facing);d.model_3d.set_facing(-facing);p._jab_chain=0
	contacts.clear()
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg.begins_with("--geometry-baseline="):baseline=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_fighter_id="juno-spark";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	p=current_scene.fighter1;d=current_scene.fighter2;p.hit_resolver.hit_confirmed.connect(observe)
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-80,240))
			for i in range(3):await physics_frame
			if not baseline.is_empty():
				var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(baseline.path_join(fid+"_"+body+".json")))
				var library:=AnimationLibrary.new();var controller=p.model_3d.get_animation_controller()
				for mid in ["jab_1","heavy_attack","aura_burst"]:library.add_animation(mid,controller._animation_from_data(doc.clips[mid]))
				controller.get_animation_player().add_animation_library("geometry_baseline",library)
			for facing in [1,-1]:
				for kind in ["light","heavy","signature","shield","whiff","interruption"]:
					reset_case(facing,kind)
					for i in range(30):await physics_frame
					p.controls_enabled=true;d.controls_enabled=false
					check(p.is_on_floor() and d.is_on_floor(),fid+":"+body+":grounded_fixture")
					active_case={"fighter":fid,"body":body,"facing":facing,"case":kind}
					if kind=="shield":d.state_machine.enter("shield_hold")
					if kind=="signature":p.aura=100
					Input.action_press("p1_attack")
					if kind in ["heavy","interruption"]:Input.action_press("p1_special")
					if kind=="interruption":d.controls_enabled=true;Input.action_press("p2_attack")
					var interrupted_here:=false
					for frame in range(70):
						await physics_frame
						if frame==2:release_inputs();p.controls_enabled=false;d.controls_enabled=false
						if p.state_machine.current_state in ["hitstun","hurt_light","hurt_heavy","launched"]:
							interrupted_here=true;check(not p.move_runner.active and not p.hitbox.monitoring,str(active_case)+":interrupt_cleanup")
					await process_frame
					if kind in ["whiff","interruption"]:
						check(contacts.is_empty(),str(active_case)+":no_attacker_contact")
						if kind=="interruption":check(interrupted_here,str(active_case)+":public_defender_interrupt")
						rows.append(active_case.merged({"contacts":contacts.size(),"interrupted":interrupted_here,"reach_status":"NO_CONTACT_EXPECTED"}))
					else:check(contacts.size()==1,str(active_case)+":one_public_contact")
					var controller=p.model_3d.get_animation_controller()
					check(controller.get_animation_player().current_animation=="combat_choreography/idle_primary",str(active_case)+":visible_return_to_neutral:"+p.state_machine.current_state+":"+controller.get_animation_player().current_animation)
	var file=FileAccess.open(output.path_join("roster_contact_alignment.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"baseline_pose_sha":"0ab1d6532f7fe233603fff581f6dcfd426b0057d","scope":"actual BattleScene geometry; public controls, reconfigured idle targets; baseline is old pose replay at same resolved contact, not old whole-match simulation; no human/competitive quality acceptance","acceptance":"clock/contact/interruption invariants only; measured reach requires anatomy/art and combat geometry review"},"  "));file.close()
	print("ROSTER_CONTACT_ALIGNMENT ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
