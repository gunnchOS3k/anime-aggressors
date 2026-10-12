extends "res://tests/v1_closure/RosterFootwork.gd"
var movie_pilot := false
var review_label: Label
## Public starts/stops/reversals across both bodies/facings. Idle target, not combo proof.
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--transition-movie-pilot":movie_pilot=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	var p=current_scene.fighter1;current_scene.fighter2.controls_enabled=false;current_scene.fighter2.position.x=440
	if movie_pilot:
		var layer:=CanvasLayer.new();layer.layer=95;current_scene.add_child(layer)
		review_label=Label.new();review_label.position=Vector2(20,112);review_label.add_theme_font_size_override("font_size",19);layer.add_child(review_label)
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-100,240))
			if movie_pilot:
				current_scene._p1_panel.configure(p.data.get("displayName",fid),Color(p.data.get("color",Color.WHITE)),9,false)
				review_label.text="%s · %s · public start / reverse / stop
Movement fixture · idle target · no competitive acceptance"%[fid,body]
			for facing in ([1] if movie_pilot else [1,-1]):
				for key in ["right","left","jump","attack"]:Input.action_release("p1_"+key)
				p.position=Vector2(-100,240)
				for i in range(40):await physics_frame
				var c=p.model_3d.get_animation_controller();var seen: Dictionary={};var samples: Array=[]
				Input.action_press("p1_right" if facing==1 else "p1_left",.65)
				for frame in range(85):
					if frame==28:
						Input.action_release("p1_right" if facing==1 else "p1_left")
						Input.action_press("p1_left" if facing==1 else "p1_right",.65)
					if frame==56:Input.action_release("p1_left" if facing==1 else "p1_right")
					await physics_frame
					var e: Dictionary=c.get_locomotion_transition_evidence() if c.has_method("get_locomotion_transition_evidence") else {}
					if not str(e.get("kind","")).is_empty():seen[e.kind]=true
					if frame<56:check(e.get("kind","")!="stop",fid+":"+body+":"+str(facing)+":held_input_never_owns_stop:"+str(frame))
					samples.append({"frame":frame,"movie_frame":Engine.get_process_frames()-1,"world_position":[p.position.x,p.position.y],"velocity":[p.velocity.x,p.velocity.y],"facing":p.facing,"state":p.state_machine.current_state,"pose":e})
				var label: String=fid+":"+body+":"+str(facing)
				for kind in ["start","pivot","stop"]:check(seen.has(kind),label+":authored_"+kind)
				check(p.state_machine.current_state=="idle" and p.state_machine.can_attack(),label+":unchanged_neutral_control")
				Input.action_press("p1_right" if facing==1 else "p1_left",.65)
				for i in range(3):await physics_frame
				Input.action_press("p1_attack")
				for i in range(3):await physics_frame
				Input.action_release("p1_attack");Input.action_release("p1_right" if facing==1 else "p1_left")
				check(str(p._current_move.get("move_id","")) in ["jab_1","forward_tilt","dash_attack"],label+":public_attack_immediate")
				var attack_e: Dictionary=c.get_locomotion_transition_evidence() if c.has_method("get_locomotion_transition_evidence") else {}
				check(attack_e.get("kind","")=="",label+":attack_owns_pose")
				var max_error:=0.0
				for sample in samples:max_error=maxf(max_error,float(sample.pose.get("support_error_m",0)))
				check(max_error<.00001,label+":analytic_support_precision")
				rows.append({"fighter":fid,"body":body,"facing":facing,"seen":seen,"samples":samples,"max_support_error_m":max_error,"scope":"original additive body weight shifts with rig-space gait support preserved; physical floor placement and professional choreography remain open"})
				for i in range(90):await physics_frame
	var file=FileAccess.open(output.path_join("roster_transitions.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows},"  "));file.close()
	print("ROSTER_TRANSITIONS ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
