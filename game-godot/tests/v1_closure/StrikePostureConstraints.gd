extends SceneTree
const Data=preload("res://scripts/data/data_loader.gd")
var output:=""
var rows:Array=[]
var failures:Array=[]
func _init()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label);push_error(label)
func points(sk:Skeleton3D)->Dictionary:
	sk.force_update_all_bone_transforms();var out:Dictionary={}
	for name in ["Hips","Head","Foot_L","Foot_R","UpperArm_L","LowerArm_L","Hand_L","UpperArm_R","LowerArm_R","Hand_R"]:out[name]=sk.get_bone_global_pose(sk.find_bone(name)).origin
	return out
func project(model,sk:Skeleton3D,p:Vector3)->Vector2:
	return model._camera.unproject_position(sk.to_global(p))
func run()->void:
	create_timer(70).timeout.connect(func():quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var p=current_scene.fighter1;current_scene.fighter2.controls_enabled=false
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-100,240));p.controls_enabled=true
			for i in range(40):await physics_frame
			p.controls_enabled=false
			var c=p.model_3d.get_animation_controller();var sk:Skeleton3D=c.get_skeleton();var player:AnimationPlayer=c.get_animation_player()
			for facing in [-1,1]:
				p.facing=facing;p.attack_direction=facing;p.model_3d.set_facing(facing)
				for mid in ["jab_1","jab_2","forward_tilt","heavy_attack"]:
					var move:Dictionary=Data.find_move(p.move_manifest,mid);var source:=JSON.stringify(move)
					var start:int=move.startup_frames;var end:int=start+int(move.active_frames)+int(move.recovery_frames)
					var samples:Array=[]
					for frame in [0,maxi(0,start-1),start,start+int(move.active_frames),end-1,end]:
						c.synchronize_move(frame,move)
						var adjusted:=points(sk);var evidence:Dictionary=c._strike_posture.last.duplicate(true)
						var root_before:Transform3D=p.model_3d._model_root.transform;var position_before:Vector2=p.position
						var time:float=player.current_animation_position
						player.seek(time,true);c._correct_support_knees()
						var original:=points(sk);var anchors:=0.0;var wrists:=0.0;var length_drift:=0.0
						for name in ["Hips","Foot_L","Foot_R"]:anchors=maxf(anchors,adjusted[name].distance_to(original[name]))
						for side in ["L","R"]:
							wrists=maxf(wrists,project(p.model_3d,sk,adjusted["Hand_"+side]).distance_to(project(p.model_3d,sk,original["Hand_"+side])))
							for pair in [["UpperArm_","LowerArm_"],["LowerArm_","Hand_"]]:
								var a:String=pair[0]+side;var b:String=pair[1]+side
								length_drift=maxf(length_drift,absf(adjusted[a].distance_to(adjusted[b])-original[a].distance_to(original[b])))
						var label:String=fid+body+str(facing)+mid+str(frame)
						check(anchors<.00001,label+":hips_and_feet_preserved")
						check(wrists<.001,label+":combat_plane_wrist_preserved")
						check(length_drift<.00001,label+":anatomical_lengths")
						check(p.model_3d._model_root.transform==root_before and p.position==position_before,label+":no_root_translation")
						check(JSON.stringify(move)==source,label+":no_move_edits")
						c.synchronize_move(frame,move);var again:=points(sk)
						check(again.Head.distance_to(adjusted.Head)<.00001,label+":repeat_sample_not_compounded")
						if frame==start:
							# Hook arcs are deliberately preserved throughout this pass.
							var preserved_hook:bool=mid=="jab_2" and evidence.get("reason","")=="authored_hook_preserved"
							check(evidence.get("admitted",false) or preserved_hook,label+":reachable_or_preserved_hook")
							if preserved_hook:check(adjusted.Head.distance_to(original.Head)<.00001,label+":unreachable_hook_unchanged")
							c.presentation_frozen=true;c._process(.1)
							check(points(sk).Head.distance_to(adjusted.Head)<.00001,label+":hitstop_pose_held")
							c.presentation_frozen=false
						samples.append({"frame":frame,"posture":evidence,"hip_foot_drift_m":anchors,"wrist_projection_drift_viewport_px":wrists,"arm_length_drift_m":length_drift})
					c.play_for_state("hurt_light")
					check(c._strike_posture.last.is_empty(),fid+mid+":hurt_owns_pose")
					c.play_for_state("idle")
					rows.append({"fighter":fid,"body":body,"facing":facing,"move":mid,"samples":samples})
	var f=FileAccess.open(output.path_join("strike_posture_constraints.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"existing native BattleScene rigs, explicit state/pose prerequisites; projected contact/support/anatomy/timing invariants, not human choreography acceptance"},"  "));f.close()
	print("STRIKE_POSTURE_CONSTRAINTS ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
