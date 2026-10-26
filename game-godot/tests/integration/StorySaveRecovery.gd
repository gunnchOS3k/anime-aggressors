extends "res://tests/integration/TrainingLifecycle.gd"
## Real runtime/save APIs with a declared closed-BattleScene result boundary.
## Deliberately a nonqualifying LOSS fixture, never an earned battle or unlock.
var saved_scope: Dictionary = {}

func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	if output.is_empty() or not OS.get_user_data_dir().get_file().begins_with("aa-native-"):
		push_error("Refusing owner profile")
		quit(2)
		return
	var campaign = root.get_node("CampaignRuntime")
	var gs = root.get_node("GameState")
	campaign.save_path = "user://story_loss_recovery_fixture.json"
	check(campaign.reset_campaign(), "isolated_signed_profile_created")
	gs.battle_eval_mode = true # Mark the declared fixture nonqualifying.
	check(campaign.begin_encounter(), "ordinary_story_start_API")
	check(not campaign.active_encounter.get("qualifying", true), "declared_fixture_cannot_qualify")
	# Evaluation scenes auto-start combat. Use the real inactive narrative /
	# countdown for the ownership boundary instead, without changing _active.
	gs.battle_eval_mode = false
	var token: String = campaign.active_encounter.token
	var node: String = campaign.active_encounter.node_id
	root.get_node("SceneRouter").go("battle")
	if not await wait_route("BattleScene.tscn"):
		check(false, "actual_story_battle_scene_loaded")
		finish()
		return
	var producer = current_scene
	check(campaign._battle_producer == producer, "actual_BattleScene_binds_result_owner")
	check(not producer._active, "declared_closed_countdown_boundary_not_played_match")
	var good_path: String = campaign.save_path
	var memory_before := JSON.stringify(campaign.progress)
	var disk_before := FileAccess.get_file_as_bytes(good_path)
	campaign.save_path = "user://intentionally_missing_directory/checkpoint.json"
	check(not campaign.record_battle_result(2, token, {}, producer), "failed_loss_save_is_rejected")
	check(campaign.last_error == "Could not write Story progress.", "failure_is_actual_write_error_not_owner_rejection")
	check(JSON.stringify(campaign.progress) == memory_before, "failed_loss_write_rolls_back_memory")
	check(FileAccess.get_file_as_bytes(good_path) == disk_before, "failed_loss_write_preserves_prior_signed_save")
	check(campaign.active_encounter.get("token", "") == token and campaign.last_result.is_empty(), "failed_write_keeps_retryable_result_owner")
	campaign.save_path = good_path
	check(campaign.record_battle_result(2, token, {}, producer), "same_owner_can_retry_after_storage_failure")
	check(not campaign.record_battle_result(2, token, {}, producer), "duplicate_result_is_rejected")
	check(not campaign.last_result.get("advanced", true) and not campaign.last_result.get("qualifying", true), "technical_loss_does_not_advance_or_qualify")
	var checkpoint: Dictionary = campaign.progress.checkpoint.duplicate(true)
	campaign.load_progress()
	check(campaign.current_node().id == node, "signed_restore_keeps_current_encounter")
	check(campaign.progress.checkpoint == checkpoint, "signed_restore_keeps_saved_combat_checkpoint")
	check(campaign.progress.routes["kaia-windrow"].completed.is_empty(), "retry_does_not_award_story_nodes")
	check(campaign.progress.gray_routes.is_empty() and not campaign.progress.yin_unlocked and not campaign.progress.yang_unlocked, "retry_does_not_award_unlocks")
	saved_scope = {"node": node, "checkpoint": checkpoint, "earned_battles": 0,
		"fixture": "declared nonqualifying closed-BattleScene loss boundary; no combat completion claim"}
	root.get_node("SceneRouter").go("story")
	await frames(6)
	# Real Story settings handler plus filesystem fault: rollback must be
	# visible, and Resume Save must reload the existing signed checkpoint.
	var scene = current_scene
	var presentation: OptionButton
	for control in scene._chapter_controls:
		if control is OptionButton and control.item_count == 2 and control.get_item_text(0) == "Female presentation":
			presentation = control
	check(presentation != null, "actual_Story_body_selector_present")
	if presentation != null:
		var saved_body: String = campaign.progress.presentation
		var settings_disk_before := FileAccess.get_file_as_bytes(good_path)
		var saved_index := 1 if saved_body == "male" else 0
		campaign.save_path = "user://intentionally_missing_directory/settings.json"
		presentation.select(1 - saved_index)
		presentation.item_selected.emit(1 - saved_index) # Declared UI selection.
		check(campaign.last_error == "Could not write Story progress.", "settings_failure_is_real_write_error")
		check(campaign.progress.presentation == saved_body, "failed_body_save_keeps_authoritative_presentation")
		check(presentation.selected == saved_index, "failed_body_save_restores_visible_selection")
		check(FileAccess.get_file_as_bytes(good_path) == settings_disk_before, "failed_settings_write_preserves_signed_profile")
		campaign.save_path = good_path
		var resumed := false
		for button in scene.find_children("*", "Button", true, false):
			if button.text == "Resume Save":
				await click(button)
				resumed = true
				break
		check(resumed, "actual_Resume_Save_button_used")
		check(campaign.current_node().id == node and campaign.progress.checkpoint == checkpoint, "Resume_Save_restores_signed_node_and_checkpoint")
		check(presentation.selected == saved_index and campaign.last_error.is_empty(), "Resume_Save_restores_presentation_and_clears_stale_error")
	finish()

func finish() -> void:
	keys([])
	paused = false
	var file := FileAccess.open(output.path_join("STORY_SAVE_RECOVERY.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS": failures.is_empty(), "checks": checks,
		"failures": failures, "observations": saved_scope,
		"scope": "Real Godot scene ownership and signed save fault/retry/restore APIs. Declared loss boundary, no earned-route/KO/native acceptance."}, "  "))
	file.close()
	quit(0 if failures.is_empty() else 1)
