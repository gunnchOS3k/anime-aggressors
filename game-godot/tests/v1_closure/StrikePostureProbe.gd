extends "res://tests/v1_closure/RosterContactRange.gd"
const Posture=preload("res://scripts/visual/grounded_strike_posture.gd")
func area(poly:PackedVector2Array)->float:
	var value:=0.0
	for i in range(poly.size()):value+=poly[i].cross(poly[(i+1)%poly.size()])
	return absf(value)*.5
func overlap(a:PackedVector2Array,b:PackedVector2Array)->float:
	var result:=0.0
	for shape in Geometry2D.intersect_polygons(a,b):result+=area(shape)
	return result
func _run()->void:
	create_timer(60).timeout.connect(func():quit(2))
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	p=current_scene.fighter1;d=current_scene.fighter2
	for fid in ["kaia-windrow","juno-spark"]:
		for body in ["male","female"]:
			gs.p1_body_variant=body;gs.p2_body_variant=body
			p.configure(fid,1,false,9,Vector2(-80,240));d.configure("juno-spark" if fid=="kaia-windrow" else "kaia-windrow",2,false,9,Vector2(-38,240))
			p.controls_enabled=true;d.controls_enabled=true
			for i in range(40):await physics_frame
			p.controls_enabled=false;d.controls_enabled=false
			mesh_cache[p.model_3d.get_instance_id()]=cache_meshes(p.model_3d);mesh_cache[d.model_3d.get_instance_id()]=cache_meshes(d.model_3d)
			for facing in [-1,1]:
				p.facing=facing;p.attack_direction=facing;d.facing=-facing;d.position.x=p.position.x+42*facing
				p.model_3d.set_facing(facing);d.model_3d.set_facing(-facing)
				var c=p.model_3d.get_animation_controller();var sk:Skeleton3D=c.get_skeleton()
				for mid in ["jab_1","heavy_attack"]:
					var move:Dictionary=preload("res://scripts/data/data_loader.gd").find_move(p.move_manifest,mid)
					# Evaluate the unmodified authored contact pose for this isolated
					# before/after candidate measurement; production has its own hook.
					var key:String="combat_choreography/"+mid+("_left" if facing<0 else "")
					var player:AnimationPlayer=c.get_animation_player()
					player.play(key,0);player.seek(float(c._choreography_timing[mid+("_left" if facing<0 else "")].contact_frame)/60.0,true)
					var before:Dictionary=limbs(p.model_3d)
					var original_head:=projected_surface(p.model_3d,"Head")
					var target_head:=projected_surface(d.model_3d,"Head")
					var pose=Posture.new();pose.apply(p,sk,int(move.startup_frames),move)
					var after:Dictionary=limbs(p.model_3d);var drift:=0.0
					for name in before:drift=maxf(drift,Vector2(before[name][0],before[name][1]).distance_to(Vector2(after[name][0],after[name][1])))
					rows.append({"fighter":fid,"body":body,"facing":facing,"move":mid,"posture":pose.last,"limb_projection_drift_px":drift,"head_overlap_before_px2":overlap(original_head,target_head),"head_overlap_after_px2":overlap(projected_surface(p.model_3d,"Head"),target_head)})
	var f=FileAccess.open(output.path_join("strike_posture_probe.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"rows":rows,"failures":failures,"scope":"candidate posture on actual native rigs at resolved contact phase; explicit positions, not ordinary-play/CPU acceptance"},"  "));f.close()
	print("STRIKE_POSTURE_PROBE rows=",rows.size());quit()
