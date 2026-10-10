extends SceneTree
var output := ""
var route := "kaia-windrow"
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg.begins_with("--dialogue-route="):route=arg.get_slice("=",1)
	var c=root.get_node("CampaignRuntime");var d=root.get_node("StoryDialogue")
	var before:=JSON.stringify(c.progress)
	c.watch_route_id=route;c.watch_presentation="female"
	root.get_node("SceneRouter").go("ova")
	for i in range(10):await physics_frame
	var watch=current_scene
	await watch.seek(10)
	var id: String=watch.route.nodes[10].id
	var start_history: int=d.history.size()-1
	var seen: Dictionary={}
	for frame in range(9000):
		for i in range(maxi(0,start_history),d.history.size()):
			if d.history[i].node_id==id:seen[d.history[i].cue_id]=d.history[i]
		if frame%30==0:
			var file=FileAccess.open(output.path_join("dialogue_capture_events.json"),FileAccess.WRITE)
			file.store_string(JSON.stringify({"node_id":id,"events":seen,"expected_cues":d.nodes[id].ordered_cues.size(),"progress_unchanged":JSON.stringify(c.progress)==before,"presentation":"read-only current renderer, candidate facial/camera staging, local synthetic voices; no final OVA acting","story_unlocks_earned":false},"  ")+"\n");file.close()
		if seen.size()==d.nodes[id].ordered_cues.size() and not d.is_busy():break
		if watch.node_index!=10:break
		await physics_frame
	root.get_node("SceneRouter").go("story")
	for i in range(6):await physics_frame
	print("DIALOGUE_CAPTURE node=",id," cues=",seen.size()," unchanged=",JSON.stringify(c.progress)==before)
	quit()
