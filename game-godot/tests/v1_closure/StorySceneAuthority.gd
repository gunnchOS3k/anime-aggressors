extends SceneTree
## Stale asynchronous acknowledgment guards only; explicit cursor fixtures.
var output := ""
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var c=root.get_node("CampaignRuntime");c.save_path="user://scene_authority_fixture.json"
	var failures: Array=[];var rows: Array=[]
	for route in c.campaign.routes:
		c.progress=c.new_progress();c.active_encounter.clear()
		var node_id := ""
		for node in route.nodes:
			if node.kind=="INTERACTIVE_DIALOGUE":node_id=node.id;break
		c.progress.selected_route=route.id;c.progress.routes[route.id].cursor=node_id
		c.save_progress()
		var before:=JSON.stringify(c.progress);var disk:=FileAccess.get_file_as_bytes(c.save_path)
		var wrong_node: bool=c.acknowledge_scene(node_id+":stale",route.id)
		var wrong_route: bool=c.acknowledge_scene(node_id,route.id+":stale")
		var unchanged: bool=before==JSON.stringify(c.progress) and disk==FileAccess.get_file_as_bytes(c.save_path)
		if wrong_node or wrong_route or not unchanged:failures.append(route.id+":stale_acknowledgment_changed_progress")
		rows.append({"route":route.id,"scene":node_id,"wrong_node_rejected":not wrong_node,"wrong_route_rejected":not wrong_route,"memory_and_signed_save_unchanged":unchanged})
	var f=FileAccess.open(output.path_join("story_scene_authority.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"rows":rows,"failures":failures,"scope":"16 stale asynchronous scene acknowledgments across8 declared chapter fixtures; no battle receipts or earned play claim."},"  "));f.close()
	print("STORY_SCENE_AUTHORITY ","PASS" if failures.is_empty() else "FAIL"," cases=",rows.size()*2);quit(0 if failures.is_empty() else 1)
