extends SceneTree
## Calls the real presentation entry points; never creates a win/KO/Story result.
const Model=preload("res://scripts/fighters/fighter_model_3d.gd")
const Data=preload("res://scripts/data/data_loader.gd")
var output:=""
var rows:Array=[]
var failures:Array=[]
func _init()->void:call_deferred("run")
func run()->void:
	create_timer(45).timeout.connect(func():push_error("terminal acting watchdog");quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for body in ["male","female"]:
			var model=Model.new();root.add_child(model);model.configure(Data.load_fighter(fid),body)
			await process_frame
			var c=model.get_animation_controller();var player:AnimationPlayer=c.get_animation_player();var sk:Skeleton3D=c.get_skeleton()
			for state in ["victory","defeat"]:
				c.play_for_state("idle")
				if state=="victory":model.play_victory_presentation()
				else:model.play_defeat_presentation()
				var key:String=player.current_animation
				var hand:int=sk.find_bone("Hand_R");sk.force_update_all_bone_transforms()
				var initial:Vector3=sk.get_bone_global_pose(hand).origin
				var travel:=0.0
				for i in range(18):
					c._process(1.0/60.0);sk.force_update_all_bone_transforms()
					travel=maxf(travel,initial.distance_to(sk.get_bone_global_pose(hand).origin))
				var clock:float=player.current_animation_position
				if clock<.29:failures.append(fid+body+state+":stalled_clock")
				if travel<.001:failures.append(fid+body+state+":stalled_body")
				c._process(2.0);sk.force_update_all_bone_transforms()
				var final:Vector3=sk.get_bone_global_pose(hand).origin
				c._process(.1);sk.force_update_all_bone_transforms()
				var drift:float=final.distance_to(sk.get_bone_global_pose(hand).origin)
				if drift>.00001:failures.append(fid+body+state+":unrequested_restart")
				# A subsequent player/state action still owns animation immediately.
				c.play_for_state("idle")
				if not c.get_active_clip().begins_with("idle"):failures.append(fid+body+state+":cannot_leave")
				rows.append({"fighter":fid,"body":body,"presentation":state,"animation_key":key,"clock_after_18frames_s":clock,"hand_travel_m":travel,"hold_drift_m":drift,"scope":"existing original body acting through real model presentation method; no battle result or human approval"})
			model.queue_free();await process_frame
	var f=FileAccess.open(output.path_join("terminal_body_acting.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"battle_results_forced":false,"human_approved":false},"  "));f.close()
	print("TERMINAL_BODY_ACTING ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
