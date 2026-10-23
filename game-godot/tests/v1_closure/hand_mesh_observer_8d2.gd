extends RefCounted
## Read-only observer using the existing roster skin/bind projection convention.
## Convex projected mesh silhouettes are NOT proof of3D pressure/occlusion/art.
var cache: Dictionary={}
var issues: Array=[]

func meshes(model) -> Array:
	var rig: Skeleton3D=model.get_animation_controller().get_skeleton()
	var key:=rig.get_instance_id()
	if cache.has(key):return cache[key]
	var result: Array=[]
	for node in model._proxy_model.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null or node.skin==null or not node.is_visible_in_tree():continue
		var binds: Array=[]
		for i in range(node.skin.get_bind_count()):
			var bone: int=rig.find_bone(node.skin.get_bind_name(i)) if not str(node.skin.get_bind_name(i)).is_empty()else node.skin.get_bind_bone(i)
			if bone<0:issues.append("missing_skin_bind:"+str(node.name));return []
			binds.append({"bone":bone,"name":rig.get_bone_name(bone),"inverse_bind":node.skin.get_bind_pose(i)})
		for index in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(index)
			if arrays[Mesh.ARRAY_BONES]==null:continue
			result.append({"name":str(node.name),"vertices":arrays[Mesh.ARRAY_VERTEX],"bones":arrays[Mesh.ARRAY_BONES],"weights":arrays[Mesh.ARRAY_WEIGHTS],"binds":binds})
	cache[key]=result
	return result

func hull(model,kind: String,side: String="") -> PackedVector2Array:
	var result:=PackedVector2Array();var rig: Skeleton3D=model.get_animation_controller().get_skeleton()
	rig.force_update_all_bone_transforms()
	for part in meshes(model):
		var poses: Array=[]
		for bind in part.binds:poses.append(rig.get_bone_global_pose(bind.bone)*bind.inverse_bind)
		var influences: int=part.bones.size()/part.vertices.size()
		for index in range(part.vertices.size()):
			var local:=Vector3.ZERO;var maximum:=0.;var dominant:=""
			for j in range(influences):
				var weight: float=part.weights[index*influences+j]
				if weight<=0:continue
				var bind: int=part.bones[index*influences+j]
				local+=(poses[bind]*part.vertices[index])*weight
				if weight>maximum:maximum=weight;dominant=part.binds[bind].name
			var selected:=false
			if kind=="hand":selected=dominant=="Hand_"+side or dominant.begins_with("D8_Finger_"+side+"_")
			elif kind=="arm":selected=dominant=="UpperArm_"+side or dominant=="LowerArm_"+side
			elif kind=="sole":selected=dominant=="Foot_"+side or dominant=="Toes_"+side
			if not selected:continue
			var pixel: Vector2=model._camera.unproject_position(rig.to_global(local))
			result.append(model._display.to_global(pixel-Vector2(model._viewport.size)*.5+model._display.offset))
	return Geometry2D.convex_hull(result)

func gap(a: PackedVector2Array,b: PackedVector2Array) -> float:
	if a.size()<3 or b.size()<3:return -1
	if not Geometry2D.intersect_polygons(a,b).is_empty():return 0
	var closest:=INF
	for pair in [[a,b],[b,a]]:
		for point in pair[0]:
			for i in range(pair[1].size()):closest=minf(closest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,pair[1][i],pair[1][(i+1)%pair[1].size()])))
	return closest

func points(values: PackedVector2Array) -> Array:
	var result: Array=[]
	for p in values:result.append([p.x,p.y])
	return result

func projection(model) -> Dictionary:
	var rig: Skeleton3D=model.get_animation_controller().get_skeleton()
	var screen: Array=[]
	for local in [Vector3.ZERO,Vector3.BACK,Vector3.UP,Vector3.RIGHT]:
		var pixel: Vector2=model._camera.unproject_position(rig.to_global(local))
		screen.append(model._display.to_global(pixel-Vector2(model._viewport.size)*.5+model._display.offset))
	return {"projection_version":2,"origin":[screen[0].x,screen[0].y],"source_forward_delta_px":[screen[1].x-screen[0].x,screen[1].y-screen[0].y],"source_up_delta_px":[screen[2].x-screen[0].x,screen[2].y-screen[0].y],"source_right_delta_px":[screen[3].x-screen[0].x,screen[3].y-screen[0].y],"camera_projection":model._camera.projection,"camera_size":model._camera.size,"display_scale":str(model._display.scale),"model_basis":str(model._proxy_model.global_basis),"scope":"Actual affine basis sampled in each rig's independent viewport. Blender axes map x,y,z to Godot x,z,-y. Do not substitute one shared pixels-per-metre scale."}
