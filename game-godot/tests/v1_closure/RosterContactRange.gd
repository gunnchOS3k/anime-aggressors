extends "res://tests/v1_closure/RosterContactAlignment.gd"
## Geometry-only public-control fixtures. Idle targets are never combo acceptance.
## CPU skin projection uses actual bind matrices/weights, without GPU readback.
var pilot := false
var mesh_cache: Dictionary={}
func release_inputs() -> void:
	for slot in [1,2]:
		for key in ["attack","special","left","right","up","down","shield","jump","grab","dodge"]:Input.action_release("p%d_%s"%[slot,key])
func cache_meshes(model) -> Array:
	var result: Array=[]
	var sk=model.get_animation_controller().get_skeleton()
	for node in model._proxy_model.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null or node.skin==null or not node.visible:continue
		var transforms: Array=[];var names: Array=[]
		for bind in range(node.skin.get_bind_count()):
			var bone: int=sk.find_bone(node.skin.get_bind_name(bind)) if not str(node.skin.get_bind_name(bind)).is_empty() else node.skin.get_bind_bone(bind)
			check(bone>=0,"valid_skin_bind:"+str(node.name))
			transforms.append({"bone":bone,"inverse_bind":node.skin.get_bind_pose(bind)})
			names.append(sk.get_bone_name(bone) if bone>=0 else "MISSING")
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_BONES]==null:continue
			result.append({"name":str(node.name),"vertices":arrays[Mesh.ARRAY_VERTEX],"bones":arrays[Mesh.ARRAY_BONES],"weights":arrays[Mesh.ARRAY_WEIGHTS],"binds":transforms,"bone_names":names})
	return result
func projected_surface(model,selected_bone: String,body_surface: bool=false) -> PackedVector2Array:
	var points:=PackedVector2Array();var sk=model.get_animation_controller().get_skeleton();sk.force_update_all_bone_transforms()
	for part in mesh_cache.get(model.get_instance_id(),[]):
		if body_surface and not (part.name.begins_with("Articulated") or part.name.begins_with("Hip costume") or part.name=="Face"):continue
		var per_vertex: int=part.bones.size()/part.vertices.size()
		var poses: Array=[]
		for bind in part.binds:poses.append(sk.get_bone_global_pose(bind.bone)*bind.inverse_bind)
		for i in range(part.vertices.size()):
			var largest_weight:=0.;var dominant: String="";var local:=Vector3.ZERO
			for j in range(per_vertex):
				var weight: float=part.weights[i*per_vertex+j]
				if weight<=0:continue
				var bind: int=part.bones[i*per_vertex+j]
				local+=(poses[bind]*part.vertices[i])*weight
				if weight>largest_weight:largest_weight=weight;dominant=part.bone_names[bind]
			if not body_surface and dominant!=selected_bone:continue
			var pixel: Vector2=model._camera.unproject_position(sk.to_global(local))
			points.append(model._display.to_global(pixel-Vector2(model._viewport.size)*.5+model._display.offset))
	check(points.size()>3,"projected_mesh_vertices:"+selected_bone+":"+str(body_surface))
	return Geometry2D.convex_hull(points)
func polygon_gap(a: PackedVector2Array,b: PackedVector2Array) -> float:
	if a.size()<3 or b.size()<3:return -1
	if not Geometry2D.intersect_polygons(a,b).is_empty():return 0
	var minimum:=INF
	for v in a:
		for i in range(b.size()):minimum=minf(minimum,v.distance_to(Geometry2D.get_closest_point_to_segment(v,b[i],b[(i+1)%b.size()])))
	for v in b:
		for i in range(a.size()):minimum=minf(minimum,v.distance_to(Geometry2D.get_closest_point_to_segment(v,a[i],a[(i+1)%a.size()])))
	return minimum
func rect_polygon(rect: Rect2) -> PackedVector2Array:return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
func points_json(points: PackedVector2Array) -> Array:
	var out: Array=[]
	for v in points:out.append([v.x,v.y])
	return out
func measure(info: Dictionary,context: Dictionary) -> void:
	super.measure(info,context)
	check(effect_frame_valid(info),"contact_effect_frame:"+str(context))
	var row: Dictionary=rows[-1]
	var hand: PackedVector2Array=projected_surface(p.model_3d,row.intended_striking_limb)
	var torso: PackedVector2Array=projected_surface(d.model_3d,"",true)
	var overlap: Rect2=info.attack_bounds.intersection(info.hurt_bounds)
	var renderer=current_scene.get_node("SpectralFeedback")
	var effect=renderer.history.filter(func(e):return str(e.get("event_id",""))==str(info.combat_event_id))
	row.merge({"projected_hand_hull":points_json(hand),"projected_defender_torso_head_hip_hull":points_json(torso),"hand_mesh_to_overlap_px":polygon_gap(hand,rect_polygon(overlap)),"hand_mesh_to_visible_body_hull_px":polygon_gap(hand,torso),"defender_model_path":d.model_3d._proxy_model.scene_file_path,"attacker_airborne":not p.is_on_floor(),"attacker_velocity":[p.velocity.x,p.velocity.y],"defender_airborne":not d.is_on_floor(),"defender_state_at_contact":d.state_machine.current_state,"defender_velocity":[d.velocity.x,d.velocity.y],"defender_hitstun_s":d.hitstun_remaining,"contact_frame":Engine.get_physics_frames(),"vfx_matching_events":effect.size(),"vfx_event_frame":effect[0].get("physics_frame",-1) if not effect.is_empty() else -1,"played_audio_path":info.get("played_audio",{}).get("path",""),"measurement_scope":"CPU weighted skin at synchronous contact; projected convex silhouette of hand-bound vertices and torso/head/hip; no occlusion/3D surface or artistic acceptance"})
	rows[-1]=row
func effect_frame_valid(info: Dictionary) -> bool:
	var effects=current_scene.get_node("SpectralFeedback").history.filter(func(e):return str(e.get("event_id",""))==str(info.combat_event_id))
	return effects.size()==1 and int(effects[0].get("physics_frame",-1))==Engine.get_physics_frames()
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--range-pilot":pilot=true
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.p1_fighter_id="ember-vale";gs.p2_fighter_id="juno-spark";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=1800
	root.get_node("SceneRouter").go("battle")
	for i in range(220):await physics_frame
	p=current_scene.fighter1;d=current_scene.fighter2;p.hit_resolver.hit_confirmed.connect(observe)
	for fid in Renderer.IDS:
		for body in (["male"] if pilot else ["male","female"]):
			gs.p1_body_variant=body;gs.p2_body_variant="female" if body=="male" else "male"
			p.configure(fid,1,false,9,Vector2(-80,240));d.configure(fid,2,false,9,Vector2(-38,240))
			for i in range(4):await physics_frame
			mesh_cache.clear();mesh_cache[p.model_3d.get_instance_id()]=cache_meshes(p.model_3d);mesh_cache[d.model_3d.get_instance_id()]=cache_meshes(d.model_3d)
			for facing in ([1] if pilot else [1,-1]):
				for kind in (["light"] if pilot else ["light","heavy","signature"]):
					var outer_distance:=42.0
					for spacing in (["typical"] if pilot else ["typical","close","outer"]):
						reset_case(facing,"light")
						var distance: float=32.0 if spacing=="close" else outer_distance if spacing=="outer" else 42.0
						d.position.x=p.position.x+facing*distance
						for i in range(30):await physics_frame
						p.controls_enabled=true;d.controls_enabled=true
						active_case={"fighter":fid,"body":body,"facing":facing,"case":kind,"range":spacing,"initial_spacing_px":distance}
						if kind=="signature":p.aura=100
						Input.action_press("p1_attack")
						if kind=="heavy":Input.action_press("p1_special")
						for frame in range(90):
							await physics_frame
							if frame==2:release_inputs()
						check(contacts.size()==1,str(active_case)+":one_contact")
						if not contacts.is_empty():
							var c: Dictionary=contacts[0];outer_distance=absf((c.attack_bounds.end.x if facing==1 else c.attack_bounds.position.x)-p.position.x)+c.hurt_bounds.size.x*.5-2.0
							rows[-1]["defender_recovery_state"]=d.state_machine.current_state;rows[-1]["defender_control_returned"]=d.state_machine.can_attack()
				for aerial in ["ascending","descending"]:
					reset_case(facing,"light")
					for i in range(30):await physics_frame
					p.controls_enabled=true;d.controls_enabled=true
					active_case={"fighter":fid,"body":body,"facing":facing,"case":"aerial","range":aerial,"initial_spacing_px":42}
					Input.action_press("p1_jump");Input.action_press("p2_jump")
					for i in range(10):await physics_frame
					release_inputs()
					if aerial=="descending":
						for i in range(90):
							if p.velocity.y>30 or p.is_on_floor():break
							await physics_frame
					check(not p.is_on_floor(),str(active_case)+":public_airborne")
					Input.action_press("p1_attack")
					for frame in range(90):
						await physics_frame
						if frame==2:release_inputs()
					check(contacts.size()==1,str(active_case)+":aerial_contact")
					if not contacts.is_empty():
						rows[-1]["defender_recovery_state"]=d.state_machine.current_state;rows[-1]["defender_control_returned"]=d.state_machine.can_attack();rows[-1]["attacker_landed"]=p.is_on_floor();rows[-1]["attacker_control_returned"]=p.state_machine.can_attack()
	var file=FileAccess.open(output.path_join("roster_contact_range.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"real contact geometry with public grounded/jump/attack controls and idle geometry targets, not CPU combo acceptance; unmodified collision/balance; weighted skin hull does not certify final physical choreography"},"  "));file.close()
	print("ROSTER_CONTACT_RANGE ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size());quit(0 if failures.is_empty() else 1)
