extends "res://tests/v1_closure/FacialPerformance8D.gd"
## Matched original model/pose/camera; only actual source morph weights differ.
func pixels_hash(image: Image) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256);context.update(image.get_data())
	return context.finish().hex_encode()

func pose_signature(model) -> String:
	var bones: Array=[]
	var skeleton: Skeleton3D=model._visible_skeleton
	for index in range(skeleton.get_bone_count()):bones.append(str(skeleton.get_bone_global_pose(index)))
	return str(bones)+str(model._camera.global_transform)+str(model._model_root.global_transform)

func freeze_fixture(node: Node, previous: Array) -> void:
	previous.append([node,node.process_mode])
	node.process_mode=Node.PROCESS_MODE_DISABLED
	for child in node.get_children():freeze_fixture(child,previous)
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.stage_id="training-grid";gs.items_enabled=false;gs.hazards_enabled=false;gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0;gs.match_type="stock_untimed"
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2
	for body in ["male","female"]:
		var sheet:=Image.create(384,1728,false,Image.FORMAT_RGBA8)
		for row in range(9):
			await configure(p,d,IDs[row],body,1)
			var model=p.model_3d
			var face=model._expression_controller
			var target: String=p.get_forms_doc().form_ladder[1]
			paused=true
			# This is a staged morphology comparison, not a gameplay pause test.
			# Freeze explicit ALWAYS-processing descendants as well; otherwise
			# idle state selection can replace this manually sampled source pose.
			var previous_modes: Array=[]
			freeze_fixture(p,previous_modes)
			model.begin_form_sequence(target)
			model.set_transform_progress(.60)
			var skeleton: Skeleton3D=model._visible_skeleton
			var head: Vector3=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin)
			var center: Vector2=model._camera.unproject_position(head)
			var size: Vector2i=model._viewport.size
			var crop:=Rect2i(Vector2i(clampi(int(center.x)-96,0,size.x-192),clampi(int(center.y)-96,0,size.y-192)),Vector2i(192,192))
			var source: Array=[]
			for column in range(2):
				if column==0:face.set_expression("neutral",true)
				else:face.sample_form_performance(target,.60)
				# Let deferred skin/shape upload settle; do not compare a stale
				# previous pose against the newly sampled body pose.
				skeleton.force_update_all_bone_transforms()
				for settle in range(2):await process_frame;await RenderingServer.frame_post_draw
				var image: Image=model._viewport.get_texture().get_image().get_region(crop)
				sheet.blit_rect(image,Rect2i(0,0,192,192),Vector2i(column*192,row*192))
				source.append({"kind":"old_neutral" if column==0 else "8D_original_morph_score","evidence":face.evidence(),"pixels_sha256":pixels_hash(image),"body_pose_camera_signature":pose_signature(model)})
			check(source[0].body_pose_camera_signature==source[1].body_pose_camera_signature,IDs[row]+body+":matched_pose_and_camera")
			check(source[0].pixels_sha256!=source[1].pixels_sha256,IDs[row]+body+":actual_render_changed")
			rows.append({"fighter":IDs[row],"body":body,"facing":1,"form_target":target,"pose_phase":.60,"crop":crop,"samples":source,"scope":"Matched staged face close-up in actual Godot; same original mesh/body pose/camera, only source morph weights change; not CPU/earned/owner acceptance"})
			model.end_form_sequence()
			for prior in previous_modes:
				if is_instance_valid(prior[0]):prior[0].process_mode=prior[1]
			paused=false
		check(sheet.save_png(output.path_join("face_"+body+"_old_vs_8d.png"))==OK,body+":sheet_saved")
	var f=FileAccess.open(output.path_join("facial_native_8d.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"human_approved":false},"\t"));f.close()
	release();quit(0 if failures.is_empty() else 1)
