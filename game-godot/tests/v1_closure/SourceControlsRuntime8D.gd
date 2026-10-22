extends SceneTree
## Actual saved18-rig imports, isolated BattleScene, public attacks.
## Staged open/closed sheets are not CPU, earned Story or final art acceptance.
const IDs=preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS
var output:=""
var rows: Array=[]
var failures: Array=[]
var native:=false
func _init() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label);push_error(label)
func release() -> void:
	for slot in [1,2]:
		for key in ["left","right","up","down","jump","attack","special","shield","grab","dodge","taunt"]:Input.action_release("p%d_%s"%[slot,key])
func canonical_pose(rig: Skeleton3D,names: Array) -> String:
	var values: Array=[]
	for name in names:values.append(str(rig.get_bone_pose(rig.find_bone(name))))
	return str(values)
func freeze(node: Node,modes: Array) -> void:
	modes.append([node,node.process_mode]);node.process_mode=Node.PROCESS_MODE_DISABLED
	for child in node.get_children():freeze(child,modes)
func pixels(image: Image) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(image.get_data());return h.finish().hex_encode()
func configure(p,d,fid: String,body: String,face: int) -> void:
	release();var gs=root.get_node("GameState");gs.p1_body_variant=body;gs.p2_body_variant=body
	p.configure(fid,1,false,9,Vector2(-120,240));d.configure(IDs[(IDs.find(fid)+1)%9],2,false,9,Vector2(120,240))
	for actor in [p,d]:
		actor.global_position=actor.spawn_point;actor.state_machine.enter("idle");actor.move_runner.cancel();actor.controls_enabled=true;actor.invincible=false;actor._hitstop=0;actor.velocity=Vector2.ZERO;actor._input_edge_held.clear();actor.shielding=false
	p.facing=face;d.facing=-face;p.model_3d.set_facing(face);d.model_3d.set_facing(-face)
	await frames(8)
func examine(p,label: String) -> Dictionary:
	var model=p.model_3d;var control=model._source_controls_8d
	check(is_instance_valid(control),label+":actual_candidate_layer")
	if not is_instance_valid(control):return {}
	var report: Dictionary=control.evidence();check(report.status=="actual_saved_GLTF_tracks",label+":saved_GLTF_tracks")
	var doc: Dictionary=model._controls_document_8d;var rig: Skeleton3D=model._visible_skeleton
	check(doc.body==p.data.body_variant and doc.fighter==p.fighter_id,label+":actual_body_resource")
	check(model.get_current_model_path()==doc.resource if model.has_method("get_current_model_path") else model._proxy_model.name.begins_with("CollectibleV1_"),label+":real_model_loaded")
	for name in doc.canonical_bones:check(rig.find_bone(name)>=0,label+":canonical_bone:"+name)
	var fingers: Array=[];var secondary_bones: Array=[]
	for chain in doc.chains:
		for name in chain.bones:
			check(rig.find_bone(name)>=0,label+":new_source_joint:"+name)
			if chain.kind=="finger":fingers.append(name)
			else:secondary_bones.append(name)
	check(fingers.size()==20 and secondary_bones.size()>0,label+":real_articulation_counts")
	var signature:=canonical_pose(rig,doc.canonical_bones)
	control.sample("fist",0);control.sample("idle",0,false)
	var before:=rig.get_bone_pose_rotation(rig.find_bone(fingers[0]))
	control.sample("fist",1);control.sample("idle",.25,false)
	check(rig.get_bone_pose_rotation(rig.find_bone(fingers[0])).angle_to(before)>.1,label+":actual_imported_finger_rotation")
	check(canonical_pose(rig,doc.canonical_bones)==signature,label+":original_body_tracks_untouched")
	for player in [control.hands,control.secondary]:
		for name in player.get_animation_list():
			var clip: Animation=player.get_animation(name)
			for index in range(clip.get_track_count()):check(str(clip.track_get_path(index).get_subname(0)).begins_with("D8_"),label+":no_original_tracks_in_layer")
	control.sample("fist",0);control.sample("idle",0,false)
	return report
func native_sheet(p,sheet: Image,row: int) -> Dictionary:
	var model=p.model_3d;var control=model._source_controls_8d;var rig: Skeleton3D=model._visible_skeleton
	var modes: Array=[];paused=true;freeze(p,modes)
	var fixed:=canonical_pose(rig,model._controls_document_8d.canonical_bones)
	var samples: Array=[]
	for kind in ["hand","hair"]:
		var bone: String="Hand_R" if kind=="hand" else "Head"
		var center: Vector2=model._camera.unproject_position(rig.to_global(rig.get_bone_global_pose(rig.find_bone(bone)).origin))
		var size: Vector2i=model._viewport.size
		var crop:=Rect2i(Vector2i(clampi(int(center.x)-64,0,size.x-128),clampi(int(center.y)-64,0,size.y-128)),Vector2i(128,128))
		var hashes: Array=[]
		for phase in [0.0,1.0]:
			control.sample("fist",phase);control.sample("idle",phase*.25,false)
			rig.force_update_all_bone_transforms()
			for settle in range(2):await process_frame;await RenderingServer.frame_post_draw
			var image: Image=model._viewport.get_texture().get_image().get_region(crop)
			var column:=int(phase)+(0 if kind=="hand" else 2)
			sheet.blit_rect(image,Rect2i(0,0,128,128),Vector2i(column*128,row*128))
			hashes.append(pixels(image));check(canonical_pose(rig,model._controls_document_8d.canonical_bones)==fixed,p.fighter_id+":native_canonical_pose_fixed")
		samples.append({"crop":crop,"kind":kind,"pixels":hashes,"changed":hashes[0]!=hashes[1]})
	for mode in modes:
		if is_instance_valid(mode[0]):mode[0].process_mode=mode[1]
	paused=false
	return {"samples":samples,"scope":"staged native saved-mesh open/fist and hair quarter-cycle; canonical pose/camera fixed; no final art approval"}
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	native=DisplayServer.get_name()!="headless"
	var gs=root.get_node("GameState");gs.set_meta("source_controls_8d",true);gs.mode="versus";gs.stage_id="training-grid";gs.items_enabled=false;gs.hazards_enabled=false;gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	var campaign=root.get_node("CampaignRuntime");var saved_before:=JSON.stringify(campaign.progress)
	root.get_node("SceneRouter").go("battle");await frames(200)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for body in ["male","female"]:
		var sheet:=Image.create(512,1152,false,Image.FORMAT_RGBA8)if native else null
		for fid in IDs:
			for face in [1,-1]:
				await configure(p,d,fid,body,face)
				var label: String=fid+body+str(face);var report:=examine(p,label)
				var native_row: Dictionary={}
				if native and face==1 and not report.is_empty():native_row=await native_sheet(p,sheet,IDs.find(fid))
				Input.action_press("p1_attack");await frames(2);release()
				check(not p._current_move.is_empty(),label+":public_attack_started")
				await frames(35)
				rows.append({"fighter":fid,"body":body,"facing":face,"source":report,"native":native_row,"scope":"isolated real BattleScene, initial spacing/stocks fixtures, public attack; no CPU/combo/earned acceptance"})
		if native:check(sheet.save_png(output.path_join("controls_"+body+"_open_closed.png"))==OK,body+":native_saved")
	check(saved_before==JSON.stringify(campaign.progress),"Story state unchanged")
	release()
	var f:=FileAccess.open(output.path_join("source_controls_runtime_8d.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"native_rendered":native,"renderer":RenderingServer.get_current_rendering_method(),"human_approved":false},"\t"));f.close();quit(0 if failures.is_empty() else 1)
