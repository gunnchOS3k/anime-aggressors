extends SceneTree
## Public locomotion controls and live projected feet; isolated movement fixture.
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output: String=""
var failures: Array=[]
var rows: Array=[]
func _init() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label);push_error(label)
func feet(model) -> Dictionary:
	var sk=model.get_animation_controller().get_skeleton();sk.force_update_all_bone_transforms();var out: Dictionary={}
	for side in ["L","R"]:
		var pixel: Vector2=model._camera.unproject_position(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Foot_"+side)).origin)))
		out[side]=model._display.to_global(pixel-Vector2(model._viewport.size)*.5+model._display.offset)
	return out
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var p=current_scene.fighter1;var d=current_scene.fighter2;d.controls_enabled=false;d.position.x=420
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-100,240))
			for facing in [1,-1]:
				for strength in [.45,.65,1.0]:
					for key in ["left","right","jump"]:Input.action_release("p1_"+key)
					p.global_position=Vector2(-100,240);p.velocity=Vector2.ZERO;p.state_machine.enter("idle");p.controls_enabled=true;p.invincible=false
					for i in range(35):await physics_frame
					var controller=p.model_3d.get_animation_controller();var player=controller.get_animation_player()
					var previous: Dictionary={};var previous_phase: float=-1;var slips: Array=[];var moved:=0.0;var start_x:float=p.position.x;var phases: Array=[]
					Input.action_press("p1_right" if facing==1 else "p1_left",strength)
					for frame in range(30):
						await physics_frame
						if not p.is_on_floor():continue
						var now: Dictionary=feet(p.model_3d);var phase: float=controller._gait_phase;phases.append(phase)
						if not previous.is_empty() and phase>=previous_phase and phase-previous_phase<.3:
							for side in ["L","R"]:
								var old: float=fposmod(previous_phase+(0 if side=="L" else .5),1)
								var cur: float=fposmod(phase+(0 if side=="L" else .5),1)
								if old>.02 and cur<.48 and cur>=old:slips.append(now[side].distance_to(previous[side]))
						previous=now;previous_phase=phase
					moved=absf(p.position.x-start_x)
					var label:=fid+":"+body+":"+str(facing)+":"+str(strength)
					check(moved>5,label+":public_movement")
					check(player.current_animation.begins_with("combat_choreography/"),label+":authored_gait")
					check(controller.gait_period_px>0 and controller._locomotion_synchronized,label+":distance_clock")
					var sum:=0.0;var maximum:=0.0
					for value in slips:sum+=float(value);maximum=maxf(maximum,float(value))
					rows.append({"fighter":fid,"body":body,"facing":facing,"input_strength":strength,"model_path":p.model_3d._proxy_model.scene_file_path,"animation":player.current_animation,"distance_px":moved,"gait_period_px":controller.gait_period_px,"measured_stance_frames":slips.size(),"mean_projected_foot_slip_px_per_frame":sum/maxi(1,slips.size()),"max_projected_foot_slip_px_per_frame":maximum,"quality_status":"MEASURED_NOT_OWNER_APPROVED"})
					Input.action_release("p1_right" if facing==1 else "p1_left")
					for i in range(60):await physics_frame
					check(player.current_animation=="combat_choreography/idle_primary",label+":neutral_after_stop")
					Input.action_press("p1_jump")
					for i in range(12):await physics_frame
					Input.action_release("p1_jump")
					check(not p.is_on_floor() and not controller._locomotion_synchronized,label+":airborne_exits_foot_clock")
					for i in range(80):await physics_frame
	var file=FileAccess.open(output.path_join("roster_footwork.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"actual public locomotion on existing BattleScene; idle opponent fixture; no competitive match proof or human animation approval; stance slip is measured without arbitrary quality pass threshold"},"  "));file.close()
	print("ROSTER_FOOTWORK ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
