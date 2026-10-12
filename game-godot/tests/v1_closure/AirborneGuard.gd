extends SceneTree
## Public jump+guard reproduction, active CPU; no velocity/state/damage/result writes.
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var failures: Array=[]
var rows: Array=[]
func _init() -> void:call_deferred("_run")
func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func clear_player() -> void:
	for action in ["jump","shield","left","right","attack","special"]:Input.action_release("p1_"+action)
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState")
	gs.mode="versus";gs.stage_id="training-grid";gs.stocks=9;gs.p1_is_cpu=false;gs.p2_is_cpu=true;gs.cpu_level=3;gs.match_seed=431017
	gs.p1_fighter_id="ember-vale";gs.p2_fighter_id="juno-spark"
	var p: Node
	var d: Node
	for fid in Renderer.IDS:
		for body in ["male","female"]:
			gs.p1_body_variant=body
			for facing in [1,-1]:
				clear_player()
				# configure() preserves live velocity/state; each fixture therefore starts
				# with fresh actors, never fabricated velocity or a forced neutral state.
				gs.p1_fighter_id=fid
				root.get_node("SceneRouter").go("battle")
				for i in range(220):await physics_frame
				p=current_scene.fighter1;d=current_scene.fighter2
				p.configure(fid,1,false,9,Vector2(-460*facing,240));d.configure("juno-spark",2,true,9,Vector2(460*facing,240))
				p.controls_enabled=true;d.controls_enabled=true
				for i in range(35):await physics_frame
				Input.action_press("p1_right" if facing==1 else "p1_left",.4)
				for i in range(2):await physics_frame
				clear_player()
				for i in range(5):await physics_frame
				check(p.facing==facing,fid+body+str(facing)+":public_facing")
				check(p.is_on_floor(),fid+body+str(facing)+":starts_grounded")
				var start_y: float=p.position.y;var start_stocks: int=p.stocks
				Input.action_press("p1_jump");Input.action_press("p1_shield")
				var illegal_guard_frames: Array=[];var samples: Array=[];var left_floor:=false;var returned_to_floor:=false
				for frame in range(60):
					await physics_frame
					if frame==6:Input.action_release("p1_jump")
					var state: String=p.state_machine.current_state
					if not p.is_on_floor():left_floor=true
					if left_floor and p.is_on_floor():returned_to_floor=true
					if state in ["shield_start","shield_hold"] and (not p.is_on_floor() or p.velocity.y<0):illegal_guard_frames.append(frame)
					samples.append({"frame":frame,"state":state,"floor":p.is_on_floor(),"y":p.position.y,"vy":p.velocity.y,"stocks":p.stocks})
				check(left_floor,fid+body+str(facing)+":public_jump_occurs")
				check(illegal_guard_frames.is_empty(),fid+body+str(facing)+":no_airborne_guard_lock")
				check(returned_to_floor,fid+body+str(facing)+":authentic_gravity_and_landing")
				check(p.stocks==start_stocks,fid+body+str(facing)+":no_spurious_stock_loss")
				check(d.is_cpu and d.controls_enabled,fid+body+str(facing)+":CPU_remains_active")
				clear_player()
				for i in range(3):await physics_frame
				check(not p.shielding,fid+body+str(facing)+":release_cleans_guard")
				rows.append({"fighter":fid,"body":body,"facing":facing,"actual_model":p.model_3d._proxy_model.scene_file_path,"start_y":start_y,"illegal_air_guard_frames":illegal_guard_frames,"left_floor":left_floor,"returned_to_floor":returned_to_floor,"stocks_before":start_stocks,"stocks_after":p.stocks,"CPU_active":d.is_cpu and d.controls_enabled,"samples":samples})
	clear_player()
	var file=FileAccess.open(output.path_join("airborne_guard.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"public jump+shield, active CPU with explicit initial spacing; no scripted attacks or velocity/state/damage/KO overrides, not combo acceptance"},"  "));file.close()
	print("AIRBORNE_GUARD ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
