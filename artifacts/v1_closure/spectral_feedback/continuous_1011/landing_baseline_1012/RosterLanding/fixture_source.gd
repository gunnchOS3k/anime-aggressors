extends "res://tests/v1_closure/RosterFootwork.gd"
## Actual public jump/fast-fall landings. Idle target: not combo/match evidence.
var actor
var landing_contact: Dictionary={}
func first_hips_y(animation: Animation) -> float:
	for track in range(animation.get_track_count()):
		if animation.track_get_type(track)==Animation.TYPE_POSITION_3D and str(animation.track_get_path(track)).ends_with(":Hips"):
			return animation.track_get_key_value(track,0).y
	return INF
func observe_landing(_from: String,to: String) -> void:
	if to!="land":return
	var c=actor.model_3d.get_animation_controller();var player=c.get_animation_player();var sk=c.get_skeleton()
	sk.force_update_all_bone_transforms()
	var hip: int=sk.find_bone("Hips")
	var neutral: float=first_hips_y(player.get_animation("combat_choreography/idle_primary"))
	landing_contact={"physics_frame":Engine.get_physics_frames(),"animation":player.current_animation,"clip_time_s":player.current_animation_position,"initial_hip_y_m":sk.get_bone_pose_position(hip).y,"neutral_hip_y_m":neutral,"resolved_landing_lag_s":actor.state_machine.landing_lag,"fast_fall":actor._fast_falling,"world_feet":feet(actor.model_3d),"model_path":actor.model_3d._proxy_model.scene_file_path}
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	actor=current_scene.fighter1;var d=current_scene.fighter2;d.controls_enabled=false;d.position.x=440
	actor.state_machine.state_changed.connect(observe_landing)
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;actor.configure(fid,1,false,9,Vector2(-100,240))
			for facing in [1,-1]:
				for fast in [false,true]:
					for key in ["left","right","jump","down","attack"]:Input.action_release("p1_"+key)
					# Initial isolated geometry placement only; subsequent motion uses inputs.
					actor.position=Vector2(-100,240)
					for i in range(35):await physics_frame
					Input.action_press("p1_right" if facing==1 else "p1_left",.45)
					for i in range(3):await physics_frame
					Input.action_release("p1_right" if facing==1 else "p1_left")
					for i in range(25):await physics_frame
					var label: String=fid+":"+body+":"+str(facing)+":"+str(fast)
					check(actor.is_on_floor() and actor.facing==facing,label+":ready_facing")
					landing_contact={};var sampled: Array=[];var airborne:=false
					Input.action_press("p1_jump")
					for frame in range(100):
						await physics_frame
						if frame==8:Input.action_release("p1_jump")
						if fast and actor.velocity.y>0 and not actor.is_on_floor():Input.action_press("p1_down")
						airborne=airborne or not actor.is_on_floor()
						if actor.state_machine.current_state=="land":
							var player=actor.model_3d.get_animation_controller().get_animation_player()
							var expected: float=clampf(actor.state_machine.state_time/actor.state_machine.landing_lag,0,1)*player.current_animation_length
							sampled.append({"state_time_s":actor.state_machine.state_time,"clip_time_s":player.current_animation_position,"expected_clip_time_s":expected,"clock_error_s":absf(player.current_animation_position-expected),"can_attack":actor.state_machine.can_attack()})
							check(absf(player.current_animation_position-expected)<.00001,label+":resolved_landing_clock")
							check(not actor.state_machine.can_attack(),label+":authority_locks_actions")
						if not landing_contact.is_empty() and actor.state_machine.current_state=="idle":break
					for key in ["jump","down"]:Input.action_release("p1_"+key)
					check(airborne and not landing_contact.is_empty(),label+":public_jump_and_land")
					if landing_contact.is_empty():continue
					check(landing_contact.initial_hip_y_m<landing_contact.neutral_hip_y_m-.000001,label+":first_frame_weight_absorption")
					check(landing_contact.animation=="combat_choreography/"+("land_hard" if fast else "land_soft"),label+":supported_landing_variant")
					check(landing_contact.clip_time_s==0,label+":immediate_landing_pose")
					check(actor.is_on_floor() and actor.state_machine.can_attack(),label+":unchanged_control_return")
					check(actor.model_3d.get_animation_controller().get_animation_player().current_animation=="combat_choreography/idle_primary",label+":neutral_return")
					rows.append({"fighter":fid,"body":body,"facing":facing,"public_fast_fall":fast,"contact":landing_contact,"clock_samples":sampled,"scope":"projected rig movement and state timing, not corrected floor placement or professional artistic approval"})
	var file=FileAccess.open(output.path_join("roster_landing.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"72public jump/fast-fall landing cases across9x2x2; original parameters/idle-target movement fixture; no CPU combo or owner-quality claim"},"  "));file.close()
	print("ROSTER_LANDING ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
