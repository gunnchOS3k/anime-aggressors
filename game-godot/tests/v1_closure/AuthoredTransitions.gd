extends SceneTree
## Public movement/attack input fixture. Opponent isolated for pose measurement,
## never presented as an active-CPU match or guaranteed combo evidence.
const Data=preload("res://scripts/data/data_loader.gd")
var output:=""
var failures:Array=[]
var rows:Array=[]
var references:Dictionary={}
var expect_authored:=false
var all_roster_support:=false
func _init()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label);push_error(label)
func release()->void:
	for a in ["left","right","attack","special","jump","shield"]:Input.action_release("p1_"+a)
func observe(p,frame:int)->Dictionary:
	var c=p.model_3d.get_animation_controller();var sk:Skeleton3D=c.get_skeleton()
	sk.force_update_all_bone_transforms()
	var soles:Dictionary={};var ankles:Dictionary={}
	var id:String=p.fighter_id+":"+c._body_variant
	if not references.has(id):references[id]=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/source_support_references.json")).rigs[id]
	var reference:Dictionary=references[id]
	for side in ["L","R"]:
		var a:Array=reference.soles[side].foot_local_m
		var tr:Transform3D=sk.get_bone_global_pose(sk.find_bone("Foot_"+side))
		for pair in [[soles,tr*Vector3(a[0],a[1],a[2])],[ankles,tr.origin]]:
			var pixel:Vector2=p.model_3d._camera.unproject_position(sk.to_global(pair[1]))
			var screen:Vector2=p.model_3d._display.to_global(pixel-Vector2(p.model_3d._viewport.size)*.5+p.model_3d._display.offset)
			pair[0][side]=[screen.x,screen.y]
	return {"frame":frame,"x":p.position.x,"velocity_x":p.velocity.x,"facing":p.facing,"phase":c._gait_phase,"previous_gait_clip":c._previous_gait_clip,"gait_period_px":c.gait_period_px,"state":p.state_machine.current_state,"move_frame":p.move_runner.total_frame,"animation":c.get_animation_player().current_animation,"transition":c.get_locomotion_transition_evidence(),"soles":soles,"ankles":ankles,"stop_support_active":c._grounded_return.active,"attack_support_active":c._attack_support_exchange.active}
func run()->void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--expect-authored-transitions":expect_authored=true
		if arg=="--all-roster-support":all_roster_support=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(180):await physics_frame
	var p=current_scene.fighter1;current_scene.fighter2.controls_enabled=false;current_scene.fighter2.position.x=420
	for fid in (preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS if all_roster_support else ["kaia-windrow","juno-spark"]):
		for body in ["male","female"]:
			gs.p1_body_variant=body;p.configure(fid,1,false,9,Vector2(-100,240))
			for facing in [1,-1]:
				for kind in (["stop","move_light","move_heavy"] if all_roster_support else ["start","accelerate","stop","reverse","pivot","dash","move_light","move_heavy","guard"]):
					release();p.global_position=Vector2(-100,240);p.velocity=Vector2.ZERO;p.state_machine.enter("idle");p.controls_enabled=true;p.facing=facing;p.model_3d.set_facing(facing)
					for i in range(30):await physics_frame
					var direction:String="p1_right" if facing==1 else "p1_left"
					if kind not in ["start","pivot","dash"]:
						Input.action_press(direction,.45 if kind=="accelerate" else .65)
						for i in range(18):await physics_frame
					var trace:Array=[observe(p,-1)]
					match kind:
						"start":Input.action_press(direction,.45)
						"accelerate":Input.action_press(direction,.7)
						"dash":Input.action_press(direction,1.0)
						"stop","guard":Input.action_release(direction)
						"pivot","reverse":
							Input.action_release(direction);Input.action_press("p1_left" if facing==1 else "p1_right",.65)
						"move_light":Input.action_press("p1_attack")
						"move_heavy":Input.action_press("p1_attack");Input.action_press("p1_special")
					for frame in range(28 if kind not in ["move_light","move_heavy","guard"] else 55):
						await physics_frame;trace.append(observe(p,frame))
						if all_roster_support and kind.begins_with("move_") and p.move_runner.total_frame>=maxi(1,int(p._current_move.get("startup_frames",1))-1):
							check(not p.model_3d.get_animation_controller()._attack_support_exchange.active,fid+body+kind+":retires_before_contact")
						if frame==0:
							Input.action_release("p1_attack");Input.action_release("p1_special")
						if kind=="guard" and frame==2:Input.action_press("p1_attack")
						if kind=="guard" and frame==3:Input.action_release("p1_attack")
					check(p.is_on_floor(),fid+body+kind+str(facing)+":grounded")
					if all_roster_support:
						var observed_exchange:=false
						for t in trace:
							if t.get("stop_support_active",false) or t.get("attack_support_active",false):observed_exchange=true
						check(observed_exchange,fid+body+kind+str(facing)+":support_exchange_observed")
						for index in range(1,trace.size()):
							var now:Dictionary=trace[index];var before:Dictionary=trace[index-1]
							if kind=="move_light" and str(now.state).begins_with("attack"):
								check(str(now.previous_gait_clip).is_empty(),fid+body+kind+":attack_releases_gait_owner")
							if kind=="move_light" and now.state=="walk" and before.state=="idle" and str(before.previous_gait_clip).is_empty():
								var expected:=fposmod(.25+absf(float(now.x)-float(before.x))/float(now.gait_period_px),1.0)
								check(absf(float(now.phase)-expected)<.00001,fid+body+kind+":fresh_post_attack_support_phase")
					for observed in trace:check(observed.has("soles") and observed.has("transition"),fid+body+kind+":complete_trace")
					if expect_authored:
						var found:=false
						for observed in trace:
							if observed.get("transition",{}).get("kind","")==kind:
								found=true
								check(str(observed.transition.get("source_action","")).begins_with("ANI06_WIP_"),fid+body+kind+":saved_source_action")
						check(found,fid+body+str(facing)+kind+":runtime_transition_observed")
					rows.append({"fighter":fid,"body":body,"initial_facing":facing,"kind":kind,"trace":trace})
	release()
	var f=FileAccess.open(output.path_join("authored_transitions.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"public input transitions on actual BattleScene rigs; isolated opponent for measurement; no human visual/CPU match acceptance"}));f.close()
	print("AUTHORED_TRANSITIONS ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
