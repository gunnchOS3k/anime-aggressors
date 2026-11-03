extends "res://tests/v1_closure/SourceControlsRuntime8D.gd"
## Matched original8D/new8D2 skinned mesh details. Staged, not ordinary gameplay.
## Native viewport aspect retained. No root, mesh, scale or costume manipulation.
const TILE:=Vector2i(192,240)
var comparisons: Array=[]

func capture_hands(p,sheet: Image,row: int,version: int) -> Dictionary:
	var model=p.model_3d;var control=model._source_controls_8d;var rig: Skeleton3D=model._visible_skeleton
	var modes: Array=[];paused=true;freeze(p,modes)
	# Same saved8B canonical acting, same exact authored phase in both versions.
	var player: AnimationPlayer=model.get_animation_controller().get_animation_player()
	player.play("combat_choreography/grab_hold_attacker",0);player.seek(0,true)
	rig.force_update_all_bone_transforms()
	var fixed:=canonical_pose(rig,model._controls_document_8d.canonical_bones)
	var original: Transform3D=model._camera.global_transform;var size: float=model._camera.size
	var evidence: Array=[]
	for side in ["R","L"]:
		var hand: int=rig.find_bone("Hand_"+side)
		var focus: Vector3=rig.to_global(rig.get_bone_global_pose(hand).origin)
		# Include the whole dense hand and actual forearm/cuff interface.
		model._camera.global_transform=original
		model._camera.global_position=focus+original.basis.z*3.0
		model._camera.size=.40
		for phase in [0.0,.5,1.0]:
			control.sample("fist",phase);control.sample("idle",0,false)
			rig.force_update_all_bone_transforms()
			for i in range(2):await process_frame;await RenderingServer.frame_post_draw
			var image: Image=model._viewport.get_texture().get_image()
			check(image.get_width()*TILE.y==image.get_height()*TILE.x,"preserved_viewport_aspect")
			image.resize(TILE.x,TILE.y,Image.INTERPOLATE_LANCZOS)
			var col: int=(0 if side=="R"else 6)+version*3+int(round(phase*2))
			sheet.blit_rect(image,Rect2i(Vector2i.ZERO,TILE),Vector2i(col*TILE.x,row*TILE.y))
			check(canonical_pose(rig,model._controls_document_8d.canonical_bones)==fixed,"fixed_source_canonical_pose")
			evidence.append({"side":side,"phase":phase,"column":col,"pixels_sha256":pixels(image),"camera":str(model._camera.global_transform),"camera_size":model._camera.size,"hand_world_transform":str(rig.get_bone_global_pose(hand))})
	model._camera.global_transform=original;model._camera.size=size
	for m in modes:
		if is_instance_valid(m[0]):m[0].process_mode=m[1]
	paused=false
	return {"samples":evidence,"source":control.evidence(),"canonical_pose":fixed,"scope":"Matched staged real skinned saved models; not active opponents, actual victim contact, human approval or device performance"}

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	check(DisplayServer.get_name()!="headless","native_renderer_required")
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.items_enabled=false;gs.hazards_enabled=false;gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(200)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for body in ["male","female"]:
		var sheet:=Image.create(TILE.x*12,TILE.y*9,false,Image.FORMAT_RGBA8)
		for fid in IDs:
			var paired: Array=[]
			for version in [0,1]:
				lane="controls_8d"if version==0 else"hands_8d2"
				gs.set_meta("source_controls_8d",version==0);gs.set_meta("source_hands_8d2",version==1)
				await configure(p,d,fid,body,1)
				check(is_instance_valid(p.model_3d._source_controls_8d),fid+body+lane+":saved_model")
				if not is_instance_valid(p.model_3d._source_controls_8d):continue
				paired.append(await capture_hands(p,sheet,IDs.find(fid),version))
			comparisons.append({"fighter":fid,"body":body,"versions":paired})
		check(sheet.save_png(output.path_join("hands_before_after_"+body+".png"))==OK,"native_sheet_saved:"+body)
	release()
	var file:=FileAccess.open(output.path_join("hands_comparison_8d2.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":comparisons,"failures":failures,"observer_sha":OS.get_environment("GITHUB_SHA"),"renderer":RenderingServer.get_current_rendering_method(),"scope":"Staged18-rig exact8D before / saved8D2 after, fixed8B hold body, original materials, open/partial/fist bothhands; native source comparison only","human_approved":false},"\t"));file.close()
	quit(0 if failures.is_empty()else 1)
