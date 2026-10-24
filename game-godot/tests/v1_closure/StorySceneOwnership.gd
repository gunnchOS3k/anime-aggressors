extends SceneTree
## Explicit chapter-position/UI fixtures. No battle receipts or ordinary-route proof.
var output := ""
var failures: Array=[]
var rows: Array=[]
var capture_ui := false
func _init() -> void:call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func button(scene: Node,text: String):
	for item in scene.find_children("*","Button",true,false):
		if item.text==text:return item
	return null
func frames(n: int) -> void:
	for i in n:await physics_frame
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg=="--story-ui-screenshot":capture_ui=true
	var c=root.get_node("CampaignRuntime");var router=root.get_node("SceneRouter");var dialogue=root.get_node("StoryDialogue")
	c.save_path="user://scene_ownership_fixture.json"
	OS.set_environment("AA_V1_ROUTE_REVIEW","1")
	for route in c.campaign.routes:
		var fid: String=route.id
		var scene_node: Dictionary={}
		for chapter in route.nodes:
			if chapter.kind=="INTERACTIVE_DIALOGUE":scene_node=chapter;break
		c.progress=c.new_progress();c.active_encounter.clear();c.last_result.clear()
		c.progress.selected_route=fid;c.progress.routes[fid].cursor=scene_node.id
		var other: String="ember-vale" if fid=="kaia-windrow" else "kaia-windrow"
		c.progress.routes[other].cursor=other+":accord"
		check(c.save_progress(),fid+":fixture_save")
		router.go("story");await frames(6)
		var menu=current_scene
		menu._action.pressed.emit();await frames(1)
		if capture_ui and fid=="kaia-windrow" and DisplayServer.get_name()!="headless":
			root.always_on_top=true;root.move_to_foreground()
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("kaia_story_stop_ui.png"))
		check(dialogue.is_busy(),fid+":actual_scene_cues")
		check(menu._route_picker.disabled,fid+":route_locked_while_reading")
		var resume=button(menu,"Resume Save")
		check(resume!=null and resume.disabled,fid+":resume_locked_while_reading")
		# Exercise only enabled controls, matching an ordinary user's UI access.
		if not menu._route_picker.disabled:
			for i in menu._route_picker.item_count:
				if menu._route_picker.get_item_metadata(i)==other:
					menu._route_picker.select(i);menu._route_picker.item_selected.emit(i);break
		dialogue.skip_all();await frames(1)
		check(c.progress.routes[other].completed.is_empty(),fid+":unread_other_route_not_advanced")
		check(scene_node.id in c.progress.routes[fid].completed,fid+":only_owned_scene_acknowledged")
		# Reset only this declared fixture, then test stop/restart ownership.
		c.progress=c.new_progress();c.progress.selected_route=fid;c.progress.routes[fid].cursor=scene_node.id;c.save_progress()
		router.go("story");await frames(6);menu=current_scene
		var snapshot:=JSON.stringify(c.progress);var saved:=FileAccess.get_file_as_bytes(c.save_path)
		var waiters: int=dialogue.get_signal_connection_list("sequence_finished").size()
		menu._action.pressed.emit();await frames(1)
		var stop=button(menu,"Stop Scene")
		check(stop!=null and stop.visible and not stop.disabled,fid+":stop_scene_available")
		if stop!=null:
			stop.pressed.emit();await frames(1)
			check(not dialogue.is_busy() and not menu._action.disabled,fid+":stopped_scene_returns_control")
			check(snapshot==JSON.stringify(c.progress) and saved==FileAccess.get_file_as_bytes(c.save_path),fid+":stop_does_not_write_or_advance")
			check(dialogue.get_signal_connection_list("sequence_finished").size()==waiters,fid+":stop_retires_old_scene_waiter")
			menu._action.pressed.emit();await frames(1);dialogue.skip_all();await frames(1)
			check(c.progress.routes[fid].completed==[scene_node.id],fid+":restarted_scene_completes_once")
			var following: String=c.current_node().get("id","")
			check(following!=scene_node.id,fid+":next_story_event_reachable")
		# Leaving an unfinished scene must stop its audio/subtitles and preserve cursor.
		c.progress=c.new_progress();c.progress.selected_route=fid;c.progress.routes[fid].cursor=scene_node.id;c.save_progress()
		router.go("story");await frames(6);menu=current_scene
		menu._action.pressed.emit();await frames(1)
		button(menu,"Back").pressed.emit();await frames(6)
		check(not dialogue.is_busy(),fid+":back_stops_presentation")
		check(c.progress.routes[fid].completed.is_empty() and c.current_node().id==scene_node.id,fid+":back_preserves_unfinished_scene")
		rows.append({"route":fid,"scene":scene_node.id,"setup":"explicit chapter cursor positions and route-review visibility; no battle/receipt/ordinary-play acceptance"})
	OS.unset_environment("AA_V1_ROUTE_REVIEW")
	var f=FileAccess.open(output.path_join("story_scene_ownership.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"Eight route UI ownership/stop/restart fixtures with explicit cursor setup. Not earned campaign progression."},"  "));f.close()
	print("STORY_SCENE_OWNERSHIP ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," failures=",failures.size());quit(0 if failures.is_empty() else 1)
