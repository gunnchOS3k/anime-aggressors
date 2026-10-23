extends SceneTree

## Isolated, explicitly watch-only review. Never starts an earned encounter,
## issues results, seeds completion or edits a saved campaign.
func _initialize() -> void:
	call_deferred("_open_review")

func _open_review() -> void:
	await process_frame
	var route := "kaia-windrow"
	var body := "female"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--camera-review-route="): route = argument.trim_prefix("--camera-review-route=")
		if argument.begins_with("--camera-review-body="): body = argument.trim_prefix("--camera-review-body=")
	var campaign = root.get_node("CampaignRuntime")
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
