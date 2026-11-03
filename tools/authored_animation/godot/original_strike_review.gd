extends SceneTree
## Offline original-art clip review. No gameplay event or balance authority.
const EPS := 0.00005
var out := ""
var bundle: Dictionary
var clips: Array = []
var segments: Array = []
var phase: Label
var elapsed := 0
var current_segment := -1
var current_skin := {}
var failures: Array = []
var joint_samples := 0
var skin_samples := 0
var max_joint_error := 0.0
var max_skin_error := 0.0
var rows: Array = []
func _initialize() -> void: call_deferred("setup")
func gather(node: Node, found_players: Array, found_skeletons: Array, meshes: Dictionary) -> void:
	if node is AnimationPlayer: found_players.append(node)
	if node is Skeleton3D: found_skeletons.append(node)
	if node is MeshInstance3D: meshes[str(node.name)]=node
	for child in node.get_children(): gather(child,found_players,found_skeletons,meshes)
func xyz(v: Array) -> Vector3: return Vector3(float(v[0]),float(v[1]),float(v[2]))
func stop_failure(message: String) -> void:
	push_error(message);failures.append(message);save_report();quit(1)
func save_report() -> void:
	var file := FileAccess.open(out.path_join("NATIVE_STRIKE_PLAYBACK.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"source_sha":bundle.get("producer_sha"),"joint_samples":joint_samples,"skin_samples":skin_samples,"max_joint_error_m":max_joint_error,"max_skin_error_m":max_skin_error,"failures":failures,"completed_segments":rows,"fps_requested":60,"fixed_recording_not_sustained_device_measurement":true,"native_BattleScene_verified":false,"runtime_move_clock_verified":false,"HUMAN_ART_APPROVED":false,"RUNTIME_PAIRED_CONTACT_VERIFIED":false,"scope":"Actual AnimationPlayer and renderer-skin source comparison; original jab/heavy OFFLINE clips, both rigid facings; not combat"},"\t"));file.close()
func setup() -> void:
	var path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bundle="): path=arg.trim_prefix("--bundle=")
		if arg.begins_with("--output="): out=arg.trim_prefix("--output=")
	if not path.is_absolute_path() or not out.is_absolute_path(): quit(2);return
	bundle=JSON.parse_string(FileAccess.get_file_as_string(path))
	root.size=Vector2i(1440,760)
	var bg:=ColorRect.new();bg.color=Color("151b24");bg.size=Vector2(1440,760);root.add_child(bg)
	var h:=Label.new();h.text=str(bundle.fighter)+" / "+str(bundle.body)+" — original jab + heavy";h.position=Vector2(20,10);h.add_theme_font_size_override("font_size",24);root.add_child(h)
	phase=Label.new();phase.position=Vector2(20,690);phase.add_theme_font_size_override("font_size",19);root.add_child(phase)
	var note:=Label.new();note.text="1× original source clock • both facings • no gameplay/audio • runtime timing and final acting unapproved";note.position=Vector2(20,728);note.add_theme_font_size_override("font_size",16);root.add_child(note)
	var worlds: Array=[]
	var cameras: Array=[]
	for index in range(3):
		var viewport:=SubViewport.new();viewport.size=Vector2i(464,600);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var tex:=TextureRect.new();tex.position=Vector2(8+index*480,70);tex.size=Vector2(464,600);tex.texture=viewport.get_texture();root.add_child(tex)
		var world:=Node3D.new();viewport.add_child(world);worlds.append(world)
		var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("252d38");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d6e2ec");env.environment.ambient_light_energy=.42;world.add_child(env)
		for v in [Vector3(-35,-30,.75),Vector3(-20,135,.34)]:
			var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(v.x,v.y,0);light.light_energy=v.z;world.add_child(light)
		var grid:=ImmediateMesh.new();var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(.48,.57,.63,1);grid.surface_begin(Mesh.PRIMITIVE_LINES,mat)
		for tick in range(-12,13):
			var t:=tick*.1;grid.surface_add_vertex(Vector3(-1.2,0,t));grid.surface_add_vertex(Vector3(1.2,0,t));grid.surface_add_vertex(Vector3(t,0,-1.2));grid.surface_add_vertex(Vector3(t,0,1.2))
		grid.surface_end();var ground:=MeshInstance3D.new();ground.mesh=grid;world.add_child(ground)
		var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.13;world.add_child(cam);cam.current=true;cameras.append(cam)
		if not cam.is_inside_tree() or viewport.get_camera_3d()!=cam: stop_failure("camera_not_attached_current");return
		var label:=Label.new();label.text=["WORLD PROFILE (+X)","WORLD FRONT (+Z)","THREE-QUARTER"][index];label.position=Vector2(12+index*480,48);label.add_theme_font_size_override("font_size",16);root.add_child(label)
	for definition in bundle.clips:
		var mp:=str(definition.manifest);var m:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(mp));var entry:Dictionary=m.rows[0].animated_reference
		var asset:=mp.get_base_dir().path_join(str(entry.resource)).simplify_path()
		if not asset.begins_with(mp.get_base_dir()+"/") or FileAccess.get_sha256(asset)!=entry.sha256: stop_failure("asset_path_or_hash");return
		var document:=GLTFDocument.new();var state:=GLTFState.new()
		if document.append_from_file(asset,state)!=OK:stop_failure("GLTF_import");return
		var data:={"definition":definition,"manifest":m,"entry":entry,"models":[],"players":[],"skeleton":null,"meshes":{},"skin_frames":{},"cameras":cameras}
		var sd:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(mp.get_base_dir().path_join(str(m.scoped_skin_resource))))
		for f in sd.frames: data.skin_frames[int(f.frame)]=f.meshes
		for i in range(3):
			var model:=document.generate_scene(state,60.0);worlds[i].add_child(model);model.visible=false;data.models.append(model)
			var pp:Array=[];var ss:Array=[];var meshes:={};gather(model,pp,ss,meshes)
			if pp.size()!=1 or ss.size()!=1:stop_failure("owned_player_skeleton");return
			var player:AnimationPlayer=pp[0];player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var clip_name:=""
			for k in player.get_animation_list():
				if String(k).get_file()==str(entry.clip):clip_name=k
			if clip_name.is_empty():stop_failure("missing_clip");return
			player.play(clip_name);player.seek(0,true);player.advance(0);data.players.append(player)
			if i==0:data.skeleton=ss[0];data.meshes=meshes
		clips.append(data)
	for facing in [1,-1]:
		for i in range(clips.size()):segments.append({"clip_index":i,"facing":facing,"frames":int(clips[i].entry.source_frame_count)+18})
	await process_frame
	process_frame.connect(tick)
func skin_check(data: Dictionary, frame: int, facing: Transform3D) -> void:
	if not data.skin_frames.has(frame):return
	for definition in data.skin_frames[frame]:
		var instance:MeshInstance3D=data.meshes.get(str(definition.name))
		if instance==null:failures.append("missing_mesh:"+str(definition.name));continue
		var baked:=instance.bake_mesh_from_current_skeleton_pose()
		if baked==null:failures.append("skin_bake_failed");continue
		var buckets:={}
		for surface in range(baked.get_surface_count()):
			var arrays:=baked.surface_get_arrays(surface)
			for vertex:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var p:=facing.affine_inverse()*instance.global_transform*vertex;var key:=Vector3i((p/EPS).round())
				if not buckets.has(key):buckets[key]=[]
				buckets[key].append(p)
		for vertex in definition.vertices_stage_m:
			var p:=xyz(vertex);var key:=Vector3i((p/EPS).round());var nearest:=INF
			for x in range(-1,2):
				for y in range(-1,2):
					for z in range(-1,2):
						for point in buckets.get(key+Vector3i(x,y,z),[]):nearest=minf(nearest,p.distance_to(point))
			skin_samples+=1;max_skin_error=maxf(max_skin_error,nearest)
			if nearest>EPS and failures.size()<20:failures.append("actual_source_skin:"+str(frame)+":"+str(definition.name))
func tick() -> void:
	var index:=0;var local:=elapsed
	while index<segments.size() and local>=int(segments[index].frames):local-=int(segments[index].frames);index+=1
	if index>=segments.size():save_report();quit(0 if failures.is_empty() else 1);return
	var segment:Dictionary=segments[index];var data:Dictionary=clips[int(segment.clip_index)];var facing:=Transform3D(Basis(Vector3.UP,PI if int(segment.facing)==-1 else 0.0),Vector3.ZERO)
	if index!=current_segment:
		for clip in clips:
			for model in clip.models:model.visible=false
		for model in data.models:model.visible=true;model.transform=facing
		var lower:=Vector3(INF,INF,INF);var upper:=-lower
		for snap in data.manifest.rows[0].snapshots:
			for bounds in snap.bounds:lower=lower.min(xyz(bounds.minimum_m));upper=upper.max(xyz(bounds.maximum_m))
		var center:=facing*((lower+upper)*.5)
		for i in range(3):
			var direction:Vector3=[Vector3(1,.10,0),Vector3(0,.10,1),Vector3(.65,.16,1)][i].normalized();var camera:Camera3D=data.cameras[i];camera.position=center+direction*6;camera.look_at(center,Vector3.UP)
		current_segment=index
	var frame:=mini(local,int(data.entry.source_frame_count)-1)
	for player in data.players:player.seek(frame/60.0,true);player.advance(0)
	phase.text="%s • facing %d • frame %03d/%03d • own original body + new strike arms / digits"%[data.manifest.move_id,segment.facing,frame,int(data.entry.source_frame_count)-1]
	await RenderingServer.frame_post_draw
	if local<int(data.entry.source_frame_count):
		var rig:Skeleton3D=data.skeleton;rig.force_update_all_bone_transforms();var expected:Dictionary=data.entry.pose_frames[frame].actors[0].bones_stage_m
		for bone in expected:
			var bi:=rig.find_bone(str(bone))
			if bi<0:stop_failure("missing_original_bone:"+str(bone));return
			var p:=facing.affine_inverse()*rig.global_transform*rig.get_bone_global_pose(bi).origin;var error:=p.distance_to(xyz(expected[bone]));joint_samples+=1;max_joint_error=maxf(max_joint_error,error)
			if error>EPS and failures.size()<20:failures.append("actual_native_joint:"+str(bone)+":"+str(frame))
		skin_check(data,frame,facing)
		if data.skin_frames.has(frame) or frame==int(data.definition.contact_frame):root.get_texture().get_image().save_png(out.path_join(str(data.manifest.move_id)+"_facing"+str(segment.facing)+"_frame%03d.png"%frame))
	if local==int(segment.frames)-1:rows.append({"move_id":data.manifest.move_id,"facing":segment.facing,"source_frames":data.entry.source_frame_count,"asset_sha256":data.entry.sha256})
	elapsed+=1
