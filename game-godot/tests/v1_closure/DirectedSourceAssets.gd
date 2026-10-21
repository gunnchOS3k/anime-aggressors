extends SceneTree
## Loaded source clips / weighted sole reference, never a visual acceptance test.
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
var output := ""
var failures: Array = []
var rows: Array = []

func _init() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if not value: failures.append(label); push_error(label)
func vector(a: Array) -> Vector3: return Vector3(float(a[0]),float(a[1]),float(a[2]))

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for body in ["male","female"]:
			var model = Model.new(); root.add_child(model)
			model.configure(Data.load_fighter(fid),body); await process_frame
			var c = model.get_animation_controller(); var player: AnimationPlayer=c.get_animation_player()
			var sk: Skeleton3D=c.get_skeleton()
			check(sk!=null and player!=null,fid+body+":rig_loaded")
			if fid in ["kaia-windrow","juno-spark"]:
				var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/combat_performance/%s_%s.json"%[fid,body]))
				var directed_count:=0
				for name in doc.clips:
					var clip:Dictionary=doc.clips[name]
					if not clip.has("directed_source"):continue
					directed_count+=1
					check(player.has_animation("combat_choreography/"+name),fid+body+name+":source_clip_loaded")
					check(not clip.bone_tracks.has("Root"),fid+body+name+":no_root_animation")
					check(not clip.get("human_approved",true),fid+body+name+":approval_false")
				check(directed_count==32,fid+body+":all_directed_clips_loaded")
				for required in ["walk_loop","run_loop","dash_loop","grab","throw_forward","throw_back","throw_up","throw_down","ko","defeat"]:
					check(doc.clips.get(required,{}).has("directed_source"),fid+body+":directed_category:"+required)
				for gait in ["walk_loop","run_loop","dash_loop"]:
					var clip:Dictionary=doc.clips[gait]
					var stride:float=clip.gait_half_stride_m
					var max_stance:=0.0;var max_penetration:=0.0;var min_knee:=0.0
					player.play("combat_choreography/"+gait,0)
					for frame in range(int(clip.duration_frames)+1):
						player.seek(float(frame)/60,true);sk.force_update_all_bone_transforms()
						var phase:float=float(frame)/float(clip.duration_frames)
						var side:String="L" if phase<=.5 else "R"
						var reference:Dictionary=doc.source_sole_reference.soles[side]
						var sole:Vector3=sk.get_bone_global_pose(sk.find_bone("Foot_"+side))*vector(reference.foot_local_m)
						var expected:Vector3=vector(reference.world_rest_m)+Vector3(0,0,stride*((1-4*phase) if phase<=.5 else (3-4*phase)))
						max_stance=maxf(max_stance,sole.distance_to(expected))
						max_penetration=maxf(max_penetration,float(reference.world_rest_m[1])-sole.y)
						var hip:Vector3=sk.get_bone_global_pose(sk.find_bone("UpperLeg_"+side)).origin
						var knee:Vector3=sk.get_bone_global_pose(sk.find_bone("LowerLeg_"+side)).origin
						var ankle:Vector3=sk.get_bone_global_pose(sk.find_bone("Foot_"+side)).origin
						var axis:Vector3=(ankle-hip).normalized()
						min_knee=minf(min_knee,(knee-hip-axis*(knee-hip).dot(axis)).dot(Vector3.BACK-axis*Vector3.BACK.dot(axis)))
					check(max_stance<.0001,fid+body+gait+":authored_stance_path")
					check(max_penetration<.0001 and min_knee>-.00001,fid+body+gait+":source_sole_and_knee_plane")
					rows.append({"fighter":fid,"body":body,"gait":gait,"stance_path_error_m":max_stance,"source_sole_penetration_m":max_penetration,"minimum_forward_knee_component":min_knee,"phase_owner":"left_then_right","stage_floor_projection_verified":false})
				for facing in [1,-1]:
					model.set_facing(facing)
					for mid in ["jab_1","heavy_attack"]:
						var name:String=mid+("_left" if facing==-1 else "")
						var clip:Dictionary=doc.clips[name]
						var side:String="L" if facing==1 else "R"
						var reference:Dictionary=doc.source_sole_reference.soles[side]
						var maximum:=0.0
						var move:Dictionary=Data.find_move(Data.load_moves(fid),mid)
						for frame in range(int(clip.duration_frames)+1):
							c.synchronize_move(frame,move);sk.force_update_all_bone_transforms()
							var foot:Transform3D=sk.get_bone_global_pose(sk.find_bone("Foot_"+side))
							maximum=maxf(maximum,(foot*vector(reference.foot_local_m)).distance_to(vector(reference.world_rest_m)))
						check(maximum<.0001,fid+body+name+":weighted_source_sole_plant")
						rows.append({"fighter":fid,"body":body,"facing":facing,"move":mid,"source_sole_error_m":maximum,"stage_floor_projection_verified":false})
			model.queue_free();await process_frame
	var file=FileAccess.open(output.path_join("directed_source_assets.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"models_loaded":18,"source_rigs":4,"directed_clips_per_rig":32,"VISUAL_VERIFICATION_PENDING":true,"scope":"live resources, no root keys and weighted source-space sole constancy. Does not establish stage-floor fit, silhouette/art quality, outer-range contact or device performance."},"  "));file.close()
	print("DIRECTED_SOURCE_ASSETS ","PASS" if failures.is_empty() else "FAIL");quit(0 if failures.is_empty() else 1)
