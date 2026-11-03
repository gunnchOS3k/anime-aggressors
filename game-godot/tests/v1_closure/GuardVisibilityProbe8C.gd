extends "res://tests/v1_closure/ElementalGuard8C.gd"
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var gs=root.get_node("GameState");gs.mode="versus";gs.items_enabled=false;gs.stage_id="training-grid";gs.p2_is_cpu=false;gs.stocks=9;gs.match_timer_seconds=0
	root.get_node("SceneRouter").go("battle");await frames(220)
	var p=current_scene.fighter1;var d=current_scene.fighter2;await _ready_pair(p,d,"rook-ironside","female",1)
	Input.action_press("p2_shield");await frames(12)
	# BattleScene deliberately processes while paused. Freeze only these
	# presentation-test actors/camera explicitly for the A/B raster; this is
	# not active-opponent or combo/earned evidence.
	p.process_mode=Node.PROCESS_MODE_DISABLED;d.process_mode=Node.PROCESS_MODE_DISABLED
	current_scene._battle_camera.process_mode=Node.PROCESS_MODE_DISABLED
	d._guard_presentation.renderer.process_mode=Node.PROCESS_MODE_DISABLED
	paused=true
	var guard=d._guard_presentation;var report: Dictionary=guard.snapshot();var mesh: MeshInstance2D=guard.renderer.slots[int(report.guard_slot)].mesh
	var parameters: Dictionary={}
	for key in ["accent","family","cue","strain","warning_tier","phase"]:parameters[key]=mesh.material.get_shader_parameter(key)
	var f=FileAccess.open(output.path_join("visibility_probe.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"guard":report,"mesh_world":mesh.global_transform,"mesh_canvas":mesh.get_global_transform_with_canvas(),"mesh_visible_in_tree":mesh.is_visible_in_tree(),"parameters":parameters},"\t"));f.close()
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var on:=root.get_texture().get_image();on.save_png(output.path_join("guard_on.png"))
	mesh.hide()
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var off:=root.get_texture().get_image();off.save_png(output.path_join("guard_off.png"))
	var changed:=0;var maximum:=0.0
	for y in range(on.get_height()):
		for x in range(on.get_width()):
			var a:=on.get_pixel(x,y);var b:=off.get_pixel(x,y);var error:=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
			if error>.01:changed+=1
			maximum=maxf(maximum,error)
	f=FileAccess.open(output.path_join("visibility_result.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"changed_pixels":changed,"max_rgb_difference":maximum,"scope":"Controlled frozen presentation raster in actual BattleScene, only guard mesh toggled; not active CPU, combo or gameplay outcome evidence"},"\t"));f.close();paused=false;release();quit()
