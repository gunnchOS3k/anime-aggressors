extends SceneTree
## PRIVATE source-art playback only. No combat, audio, shipped root calibration or human approval.
var manifest_path := ""
var out := ""
var manifest: Dictionary
var players: Array[AnimationPlayer] = []
var frame := 0
var phase: Label
var display: Node3D
var skin_by_frame := {}
var skin_nodes := {}
var skin_failures: Array = []
var skin_maximum := 0.0
var skin_samples := 0
const SKIN_EPSILON := 0.00005 # Existing saved-source/FK serialization bound; static1e-5 check stays unchanged.
func collect_skin(node: Node) -> void:
	if node is MeshInstance3D: skin_nodes[str(node.name)] = node
	for child in node.get_children(): collect_skin(child)
func validate_skin(f: int) -> void:
	if not skin_by_frame.has(f): return
	for definition in skin_by_frame[f]:
		var source_name := str(definition.name)
		if not skin_nodes.has(source_name):
			skin_failures.append("missing_original_mesh:"+source_name)
			continue
		var instance: MeshInstance3D = skin_nodes[source_name]
		# These six original meshes have no morphs. The actual renderer's skin
		# snapshot deliberately ignores unrelated facial morphs; no full-body
		# skin-equivalence claim follows. Official MeshInstance3D API.
		var baked := instance.bake_mesh_from_current_skeleton_pose()
		if baked == null:
			skin_failures.append("native_skin_bake_failed:"+source_name)
			continue
		var buckets := {}
		for surface in baked.get_surface_count():
			var arrays := baked.surface_get_arrays(surface)
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var point := instance.global_transform * vertex
				var key := Vector3i((point/SKIN_EPSILON).round())
				if not buckets.has(key): buckets[key]=[]
				buckets[key].append(point)
		for vertex in definition.vertices_stage_m:
			var p := Vector3(vertex[0],vertex[1],vertex[2])
			var key := Vector3i((p/SKIN_EPSILON).round())
			var nearest := INF
			for x in range(-1,2):
				for y in range(-1,2):
					for z in range(-1,2):
						for point in buckets.get(key+Vector3i(x,y,z),[]): nearest=minf(nearest,p.distance_to(point))
			skin_samples+=1
			skin_maximum=maxf(skin_maximum,nearest)
			if nearest>SKIN_EPSILON and skin_failures.size()<20: skin_failures.append("source_skin:"+source_name+":"+str(f)+":"+str(nearest))

var FRAMES := 0
var TOTAL := 0
func _initialize() -> void:
	call_deferred("setup")
func all_players(node: Node, found: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer: found.append(node)
	for child in node.get_children(): all_players(child,found)
func setup() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--manifest="): manifest_path=arg.trim_prefix("--manifest=")
		if arg.begins_with("--output="): out=arg.trim_prefix("--output=")
	if not manifest_path.is_absolute_path() or not out.is_absolute_path(): quit(2); return
	manifest=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var skin_path := manifest_path.get_base_dir().path_join("SCOPED_SKIN_SOURCE.json")
	var skin_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(skin_path))
	for item in skin_data.frames: skin_by_frame[int(item.frame)] = item.meshes
	var entry: Dictionary=manifest.rows[0].animated_reference
	FRAMES=int(entry.source_frame_count);TOTAL=FRAMES+60
	var asset := manifest_path.get_base_dir().path_join(str(entry.resource))
	if FileAccess.get_sha256(asset)!=entry.sha256 or entry.source_frame_count!=FRAMES: quit(3); return
	root.size=Vector2i(1440,760)
	var background := ColorRect.new(); background.color=Color("151b24");background.size=Vector2(1440,760);root.add_child(background)
	var heading:=Label.new();heading.text="ORIGINAL ROSTER — corrected source-arm reference";heading.text=str(manifest.fighter)+" / "+str(manifest.body)+" — original arm reference";heading.position=Vector2(20,10);heading.add_theme_font_size_override("font_size",24);root.add_child(heading)
	phase=Label.new();phase.position=Vector2(20,690);phase.add_theme_font_size_override("font_size",21);root.add_child(phase)
	var warning:=Label.new();warning.text="1× source timing • one arm-reference action • no combat/audio • offline art stage • artistic approval pending";warning.position=Vector2(20,728);warning.add_theme_font_size_override("font_size",16);root.add_child(warning)
	var lower:=Vector3(INF,INF,INF);var upper:=-lower
	for snapshot in manifest.rows[0].snapshots:
		for bound in snapshot.bounds:
			lower=lower.min(Vector3(bound.minimum_m[0],bound.minimum_m[1],bound.minimum_m[2]));upper=upper.max(Vector3(bound.maximum_m[0],bound.maximum_m[1],bound.maximum_m[2]))
	var center:=(lower+upper)*0.5
	for index in range(3):
		var viewport:=SubViewport.new();viewport.size=Vector2i(464,600);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var texture:=TextureRect.new();texture.position=Vector2(8+index*480,70);texture.size=Vector2(464,600);texture.texture=viewport.get_texture();root.add_child(texture)
		var world:=Node3D.new();viewport.add_child(world)
		var document:=GLTFDocument.new();var state:=GLTFState.new()
		if document.append_from_file(asset,state)!=OK:quit(4);return
		var model:=document.generate_scene(state,60.0);world.add_child(model)
		if index==0: collect_skin(model)
		var found: Array[AnimationPlayer]=[];all_players(model,found)
		if found.size()!=1:quit(5);return
		var player:=found[0];player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var clip:=""
		for key in player.get_animation_list():
			if String(key).get_file()==entry.clip:clip=key
		if clip.is_empty():quit(6);return
		player.play(clip);player.seek(0,true);player.advance(0);players.append(player)
		var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("252d38");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d6e2ec");env.environment.ambient_light_energy=0.42;world.add_child(env)
		var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=0.75;world.add_child(light)
		var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,135,0);fill.light_energy=0.34;world.add_child(fill)
		var grid:=ImmediateMesh.new();var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(0.48,0.57,0.63,1);grid.surface_begin(Mesh.PRIMITIVE_LINES,mat)
		for tick in range(-12,13):
			var t:=tick*0.1;grid.surface_add_vertex(Vector3(center.x-1.2,0,t));grid.surface_add_vertex(Vector3(center.x+1.2,0,t));grid.surface_add_vertex(Vector3(center.x+t,0,-1.2));grid.surface_add_vertex(Vector3(center.x+t,0,1.2))
		grid.surface_end();var ground:=MeshInstance3D.new();ground.mesh=grid;world.add_child(ground)
		var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.13;world.add_child(camera)
		var direction:Vector3=[Vector3(1,.10,0),Vector3(0,.10,1),Vector3(.65,.16,1)][index].normalized()
		var view_label:=Label.new();view_label.text=["PROFILE (+X)","FRONT (+Z)","THREE-QUARTER"][index];view_label.position=Vector2(12+index*480,48);view_label.add_theme_font_size_override("font_size",16);root.add_child(view_label)
		camera.position=center+direction*6;camera.look_at(center,Vector3.UP);camera.current=true
		if not camera.is_inside_tree() or viewport.get_camera_3d()!=camera:
			push_error("Private review camera not attached/active");quit(7);return
	var stamp:=Label.new();stamp.text="Source "+str(manifest.producer_sha).left(12)+" • "+str(entry.sha256).left(12);stamp.position=Vector2(900,20);stamp.add_theme_font_size_override("font_size",16);root.add_child(stamp)
	await process_frame
	process_frame.connect(tick)
func tick() -> void:
	var source_frame:=mini(frame,FRAMES-1)
	for player in players: player.seek(source_frame/60.0,true);player.advance(0)
	var beat:="Neutral"
	if source_frame>=1:beat="Preparation / weight transfer"
	if source_frame>=40:beat="Forearm restraint / resistance"
	if source_frame>=101:beat="Release / counter-rotation"
	if source_frame>=124:beat="Recovery / return to guard"
	phase.text="Frame %03d / %03d  •  own original body + corrected arms  •  native source reference"%[source_frame,FRAMES-1]
	await RenderingServer.frame_post_draw
	if frame<FRAMES: validate_skin(source_frame)
	if frame<FRAMES and skin_by_frame.has(source_frame):
		root.get_texture().get_image().save_png(out.path_join("frame_%03d.png"%source_frame))
	frame+=1
	if frame>=TOTAL:
		var file:=FileAccess.open(out.path_join("PLAYBACK_STATUS.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"PASS":true,"source_frames":FRAMES,"rendered_timeline_frames":TOTAL,"animation_players":players.size(),"source_sha":manifest.producer_sha,"source_export_sha256":manifest.rows[0].animated_reference.sha256,"fps_requested":60,"offline_camera_size_m":2.13,"camera_scope":"Fixed provisional offline framing; no shipping pixel/metre calibration","scoped_skin_samples":skin_samples,"scoped_skin_maximum_error_m":skin_maximum,"scoped_skin_failures":skin_failures,"scoped_skin_equivalence_pass":skin_failures.is_empty(),"scoped_skin_scope":"Both palms, forearms and boots at7phaseframes; no paired contact, fullbody or facial equivalence claim","audio":"NONE — technical art playback","real_gameplay":false,"RUNTIME_PAIRED_CONTACT_VERIFIED":false,"human_approved":false},"\t"));file.close();quit(0)
