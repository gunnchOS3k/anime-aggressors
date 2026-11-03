extends SceneTree
## Geometry fixture on existing BattleScene rigs, not human animation approval.
var output:=""
var rows:Array=[]
var failures:Array=[]
func _init()->void:call_deferred("run")
func positions(sk:Skeleton3D)->Dictionary:
	sk.force_update_all_bone_transforms()
	var out:Dictionary={}
	for name in ["Hips","Hand_L","Hand_R","UpperLeg_L","LowerLeg_L","Foot_L","UpperLeg_R","LowerLeg_R","Foot_R"]:
		out[name]=sk.get_bone_global_pose(sk.find_bone(name)).origin
	return out
func knee_direction(pos:Dictionary,side:String)->float:
	var hip:Vector3=pos["UpperLeg_"+side];var knee:Vector3=pos["LowerLeg_"+side];var foot:Vector3=pos["Foot_"+side]
	var axis:Vector3=(foot-hip).normalized()
	var bend:Vector3=knee-hip-axis*(knee-hip).dot(axis)
	return bend.dot((Vector3.BACK-axis*Vector3.BACK.dot(axis)).normalized())
func run()->void:
	create_timer(60).timeout.connect(func():quit(2))
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
			for i in range(45):await physics_frame
			p.controls_enabled=false
			var c=p.model_3d.get_animation_controller();var sk:Skeleton3D=c.get_skeleton();var player:AnimationPlayer=c.get_animation_player()
			for facing in [-1,1]:
				p.facing=facing;p.model_3d.set_facing(facing)
				for clip in ["idle","jab_1","heavy_attack","shield_hold"]:
					var key:String="combat_choreography/"+clip+("_left" if facing<0 and clip in ["jab_1","heavy_attack"] else "")
					player.play(key,0);player.seek(player.get_animation(key).length*.3,true)
					var before:=positions(sk)
					if c.has_method("_correct_support_knees"):c._correct_support_knees()
					var after:=positions(sk)
					var maximum_anchor_drift:=0.0
					for bone in ["Hips","Hand_L","Hand_R","Foot_L","Foot_R"]:maximum_anchor_drift=maxf(maximum_anchor_drift,before[bone].distance_to(after[bone]))
					var maximum_length_drift:=0.0
					for side in ["L","R"]:
						for pair in [["UpperLeg_","LowerLeg_"],["LowerLeg_","Foot_"]]:
							var a:String=pair[0]+side;var b:String=pair[1]+side
							maximum_length_drift=maxf(maximum_length_drift,absf(before[a].distance_to(before[b])-after[a].distance_to(after[b])))
					var signed_forward:float=minf(knee_direction(after,"L"),knee_direction(after,"R"))
					if signed_forward<-.000001:failures.append(fid+":"+body+":"+clip+":backward_knee")
					if maximum_anchor_drift>.00001:failures.append(fid+":"+body+":"+clip+":anchor_drift")
					if maximum_length_drift>.00001:failures.append(fid+":"+body+":"+clip+":segment_length_changed")
					rows.append({"fighter":fid,"body":body,"facing":facing,"clip":clip,"before_forward_m":minf(knee_direction(before,"L"),knee_direction(before,"R")),"after_forward_m":signed_forward,"maximum_hip_hand_foot_drift_m":maximum_anchor_drift,"maximum_segment_length_drift_m":maximum_length_drift,"physical_floor":p.is_on_floor()})
	var f=FileAccess.open(output.path_join("support_knee_plane.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"+Z rig knee bend plane, anchors preserved; no model/floor root translation or collision changes; not complete choreography or human approval"},"  "));f.close()
	print("SUPPORT_KNEE_PLANE ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
