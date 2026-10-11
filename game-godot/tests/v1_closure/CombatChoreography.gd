extends SceneTree
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var failures: Array=[]
var rows: Array=[]
var output := ""
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
	for fid in Renderer.IDS:
		var paths: Array=[]
		for body in ["male","female"]:
			var model=Model.new(); root.add_child(model); model.configure(Data.load_fighter(fid),body)
			await process_frame
			paths.append(model._proxy_model.scene_file_path)
			var controller=model.get_animation_controller(); var player=controller.get_animation_player(); var sk=controller.get_skeleton()
			check(player.has_animation_library("combat_choreography"),fid+":"+body+":runtime_library")
			var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/combat_choreography/%s_%s.json"%[fid,body]))
			for move in Data.load_moves(fid).moves:
				var mid: String=move.move_id; var clip: Dictionary=doc.clips[mid]; var foot: int=sk.find_bone("Foot_L"); var hand: int=sk.find_bone("Hand_L" if mid in ["jab_2","back_air"] else "Hand_R")
				var initial:=Vector3.ZERO; var anchor:=Vector3.ZERO; var max_slip:=0.0; var hand_travel:=0.0
				for frame in range(int(clip.duration_frames)+1):
					controller.synchronize_move(frame,move); sk.force_update_all_bone_transforms()
					var f: Vector3=sk.get_bone_global_pose(foot).origin; var h: Vector3=sk.get_bone_global_pose(hand).origin
					if frame==0: anchor=f; initial=h
					max_slip=maxf(max_slip,f.distance_to(anchor));hand_travel=maxf(hand_travel,h.distance_to(initial))
					check(absf(player.current_animation_position-(fmod(float(frame),float(clip.duration_frames)) if clip.get("loop",false) else float(frame))/60)<.0001,fid+":"+body+":"+mid+":clock")
				check(hand_travel>(.004 if clip.get("loop",false) else .012),fid+":"+body+":"+mid+":actual_limb_motion")
				if clip.get("support_foot")!=null: check(max_slip<.001,fid+":"+body+":"+mid+":planted_support")
				rows.append({"fighter":fid,"body":body,"move":mid,"support_slip_m":max_slip,"hand_travel_m":hand_travel,"contact_frame":clip.get("contact_frame",-1),"animation_key":player.current_animation,"technique":clip.technique})
			# Interruption/state selection must select the new visible library and restore hips.
			controller.play_for_state("hurt_heavy"); player.advance(.1)
			check(player.current_animation.begins_with("combat_choreography/"),fid+":"+body+":reaction_library")
			model.queue_free(); await process_frame
		check(paths[0]!=paths[1] and paths[0].contains("male") and paths[1].contains("female"),fid+":actual_distinct_models")
	var f=FileAccess.open(output.path_join("combat_choreography.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"live existing male/female rig deformation, every move frame; stationary model-space foot support; not world moving-foot locking, contact reach or human quality acceptance"},"  "));f.close()
	print("COMBAT_CHOREOGRAPHY ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()); quit(0 if failures.is_empty() else 1)
