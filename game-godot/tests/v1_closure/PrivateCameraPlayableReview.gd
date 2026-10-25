extends SceneTree

## Isolated, explicitly watch-only review. Never starts an earned encounter,
## issues results, seeds completion or edits a saved campaign.
func _initialize() -> void:
	call_deferred("_open_review")

func _open_review() -> void:
	await process_frame
	var route := "kaia-windrow"
	var body := "female"
	var smoke := false
	var output := ""
	var source_sha := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--camera-review-route="): route = argument.trim_prefix("--camera-review-route=")
		if argument.begins_with("--camera-review-body="): body = argument.trim_prefix("--camera-review-body=")
		if argument == "--camera-review-smoke": smoke = true
		if argument.begins_with("--ordinary-output="): output = argument.trim_prefix("--ordinary-output=")
		if argument.begins_with("--source-sha="): source_sha = argument.trim_prefix("--source-sha=")
	if smoke:
		create_timer(45.0).timeout.connect(func():
			push_error("Bounded private watch review exceeded45seconds; no gameplay acceptance")
			quit(1))
	var campaign = root.get_node("CampaignRuntime")
	var progress_before := JSON.stringify(campaign.progress)
	var data: Dictionary = campaign.route_data(route)
	var index := -1
	for i in range(data.get("nodes", []).size()):
		if data["nodes"][i].get("id") == route + ":first_loss": index = i
	if index < 0 or body not in ["male", "female"]:
		push_error("Review requires a canonical First Loss route and supported body")
		quit(2)
		return
	campaign.watch_route_id = route
	campaign.watch_presentation = body
	root.get_node("SceneRouter").go("ova")
	await process_frame
	await process_frame
	var watch = current_scene
	while watch != null and watch.get("_swap_busy") == true:
		await process_frame
	if watch == null or not watch.has_method("seek"):
		push_error("Watch scene did not open; no progression was modified")
		quit(2)
		return
	await watch.seek(index)
	print("PRIVATE_CAMERA_REVIEW: watch-only source candidate; not earned Story, paired-contact proof, final film or human approval")
	if smoke:
		await _smoke_review(watch,campaign,data,index,body,progress_before,output,source_sha)

func _smoke_review(watch, campaign, data: Dictionary, index: int, body: String, progress_before: String, output: String, source_sha: String) -> void:
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless":
		push_error("Bounded visual review needs a private absolute output and native renderer")
		quit(2)
		return
	var failures: Array = []
	var observations: Array = []
	var dialogue := root.get_node("StoryDialogue")
	await create_timer(0.4).timeout
	var expected_loss := str(data.nodes[index].first_loss)
	if watch._battle.fighter2.fighter_id != expected_loss: failures.append("canonical lost fighter missing")
	if not watch._private_camera_active: failures.append("actual private take not selected")
	for actor in [watch._battle.fighter1,watch._battle.fighter2]:
		var model = actor.model_3d
		var expected_body := body if actor == watch._battle.fighter1 else "male" if body == "female" else "female"
		if not actor.is_model_loaded() or str(model.get("_body_variant")) != expected_body:
			failures.append("visible body model unavailable: "+str(actor.fighter_id))
		observations.append({"fighter":actor.fighter_id,"body":model.get("_body_variant"),"model_loaded":actor.is_model_loaded(),"model_source":model.get("_current_model_source")})
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join("first_loss_private_camera.png")) != OK:
		failures.append("first native image not saved")
	watch._pause.pressed.emit()
	var clock: float = dialogue.remaining
	await create_timer(0.15).timeout
	if watch.playing or dialogue.remaining != clock: failures.append("native watch pause did not hold")
	# Exercise the real scene's existing chapter callback path with live models.
	await watch.seek(index+1)
	if watch.playing or not dialogue.get("_manual_pause"): failures.append("new native chapter resumed while paused")
	await watch.seek(index)
	if watch.playing or not watch._private_camera_active: failures.append("return to paused private take failed")
	watch._pause.pressed.emit()
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join("first_loss_after_pause_seek.png")) != OK:
		failures.append("second native image not saved")
	if JSON.stringify(campaign.progress) != progress_before: failures.append("watch mutated campaign progress")
	var result := {"PASS":failures.is_empty(),"failures":failures,"source_sha":source_sha,
		"route":data.get("id",data.get("anchor","")),"canonical_first_loss":expected_loss,"models":observations,
		"renderer":RenderingServer.get_current_rendering_method(),"native_watch_only":true,
		"automated_controls":true,"earned_gameplay":false,"audio_acceptance":false,
		"new_8d4_art":false,"human_approved":false,"RUNTIME_PAIRED_CONTACT_VERIFIED":false}
	var file := FileAccess.open(output.path_join("native_private_camera_smoke.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"));file.close()
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
