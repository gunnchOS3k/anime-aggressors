extends SceneTree
## Rosamere tenth-fighter Story presentation + choreography stubs.
## Does not rewrite HitResolver/rollback. choreography ≠ HUMAN_ART.

var output := ""
var checks: Array = []
var failures: Array = []


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	checks.append({"check": label, "pass": value})
	if not value:
		failures.append(label)


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Isolated profile required")
		quit(2)
		return

	var Presentation = load("res://scripts/visual/rosamere_form_presentation.gd")
	check(Presentation != null, "presentation_loads")
	var prod: Dictionary = Presentation.validate_production()
	check(bool(prod.get("ok", false)), "validate_production")
	for f in prod.get("failures", []):
		check(false, "prod_fail:" + str(f))
	check(int(prod.get("story_hooks", 0)) == 3, "three_story_hooks")
	check(int(prod.get("choreography_stubs", 0)) == 3, "three_choreography_stubs")
	check(not bool(prod.get("HUMAN_ART_APPROVED", true)), "human_art_false")
	check(not bool(prod.get("choreography_is_human_art", true)), "choreo_not_human_art")

	for fid in ["FAMILIAR_ROSE", "FIRST_BLOOM", "EVERLASTING_ORIGIN"]:
		var hook: Dictionary = Presentation.story_hook_for_form(fid)
		check(str(hook.get("form_id", "")) == fid, "hook_form:" + fid)
		check(not bool(hook.get("HUMAN_ART_APPROVED", true)), "hook_art_false:" + fid)
		var stub: Dictionary = Presentation.choreography_stub_for_form(fid)
		check(str(stub.get("form_id", "")) == fid, "stub_form:" + fid)
		check(not bool(stub.get("choreography_is_human_art", true)), "stub_not_art:" + fid)
		check(str(stub.get("camera_beat", "")) != "", "stub_camera:" + fid)

	var pink_node := {
		"id": "kaia-windrow:pink_revelation",
		"fighter_hint": "rosamere",
		"pink_working_identity": true,
		"kind": "INTERACTIVE_DIALOGUE",
	}
	var contract: Dictionary = Presentation.story_integration_contract(pink_node)
	check(bool(contract.get("story_surface", false)), "pink_story_surface")
	check(bool(contract.get("HitResolver_untouched", false)), "hitresolver_untouched")
	check((contract.get("forms", []) as Array).size() == 3, "contract_three_forms")

	## Campaign scene surfaces the hook when cursor is on pink revelation.
	var campaign = root.get_node("CampaignRuntime")
	var router = root.get_node("SceneRouter")
	campaign.save_path = "user://rosamere_story_presentation_integration.json"
	check(campaign.reset_campaign(), "reset")
	campaign.progress.routes["kaia-windrow"].cursor = "kaia-windrow:pink_revelation"
	check(campaign.save_progress(), "fixture_pink_cursor")
	router.go("story")
	var landed := false
	for _i in range(180):
		await process_frame
		var scene = current_scene
		if scene != null and str(scene.scene_file_path).ends_with("StoryCampaignScene.tscn"):
			landed = true
			break
	check(landed, "story_scene_loaded")
	if landed:
		var scene = current_scene
		var hook_label = scene.get_node_or_null("RosamereStoryPresentationHook")
		## Label may be nested under host VBox — search children.
		if hook_label == null:
			for c in scene.find_children("*", "Label", true, false):
				if str(c.name) == "RosamereStoryPresentationHook":
					hook_label = c
					break
		check(hook_label != null, "hook_label_present")
		if hook_label != null:
			## Refresh may need one frame after route fixture.
			if scene.has_method("_refresh"):
				scene._refresh()
			await process_frame
			check(hook_label.visible, "hook_label_visible_on_pink")
			check(str(hook_label.text).find("≠ HUMAN_ART") >= 0 or str(hook_label.text).find("HUMAN_ART") >= 0, "hook_honesty_text")
			check(str(hook_label.text).find("HitResolver") >= 0, "hook_mentions_hitresolver_untouched")

	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "Rosamere Story presentation hooks + choreography stubs; ≠ HUMAN_ART; HitResolver untouched",
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("ROSAMERE_STORY_PRESENTATION_INTEGRATION.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("ROSAMERE_STORY_PRESENTATION_INTEGRATION ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size())
	quit(0 if failures.is_empty() else 1)
