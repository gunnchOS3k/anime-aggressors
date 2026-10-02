extends SceneTree

const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _Campaign = preload("res://scripts/story/green_between_campaign.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var reasons: Array[String] = []
	var progress := _Campaign.new_progress()
	for _i in range(4):
		progress = _Campaign.advance(progress)
	if not _Campaign.save_progress(progress):
		ok = false
		reasons.append("save_failed")
	var loaded := _Campaign.load_progress()
	if not bool(loaded.get("rook_first_loss_canonical", false)):
		ok = false
		reasons.append("rook_flag_missing")
	if _Campaign.yin_yang_story_unlocked(loaded):
		ok = false
		reasons.append("yin_yang_unlocked")
	for variant in ["male", "female"]:
		var model: Node = MODEL_SCRIPT.new()
		root.add_child(model)
		var data := _DataLoader.load_fighter("kaia-windrow")
		data["body_variant"] = variant
		if not model.configure(data):
			ok = false
			reasons.append("configure_failed_" + variant)
		else:
			var flags: Dictionary = model.truth_flags()
			print("KAIA_", variant, " ", JSON.stringify(flags))
			if str(flags.get("CURRENT_MODEL_SOURCE", "")) != "GOLDEN_SLICE_CANDIDATE":
				ok = false
				reasons.append("source_" + variant)
			if not bool(flags.get("VISIBLE_SKELETON_PRESENT", false)):
				ok = false
				reasons.append("skeleton_" + variant)
			if int(flags.get("VISIBLE_RUNTIME_ANIMATION_CONTROLLERS_PER_FIGHTER", 0)) != 1:
				ok = false
				reasons.append("controller_" + variant)
			if bool(flags.get("FINAL_CHARACTER_ART_PASS", true)):
				ok = false
				reasons.append("final_art_" + variant)
			var skeleton: Skeleton3D = model.get_visible_skeleton()
			if variant == "male" and skeleton != null:
				var listed: PackedStringArray = []
				for bone_index in skeleton.get_bone_count():
					listed.append(skeleton.get_bone_name(bone_index))
				print("KAIA_BONES ", " ".join(listed))
			for bone_name in ["Hips", "Chest", "Head", "Hand_L", "Hand_R", "Foot_L", "Foot_R"]:
				if skeleton == null or skeleton.find_bone(bone_name) < 0:
					ok = false
					reasons.append("bone_%s_%s" % [variant, bone_name])
			if variant == "male" and skeleton != null:
				var before: Vector3 = model.sample_bone_transform("Hand_R").origin
				model.play_for_state("idle", {"move_id": "idle"})
				for _frame in range(24):
					await process_frame
				var after: Vector3 = model.sample_bone_transform("Hand_R").origin
				print("KAIA_HAND_DELTA ", before.distance_to(after), " clip ", model.get_active_animation_clip())
		model.queue_free()
		await process_frame
	var story_scene := load("res://scenes/menus/StoryCampaignScene.tscn")
	if story_scene == null:
		ok = false
		reasons.append("story_scene_missing")
	else:
		var story := (story_scene as PackedScene).instantiate()
		root.add_child(story)
		await process_frame
		story.queue_free()
	print("KAIA_GOLDEN_SLICE_HEADLESS ", "PASS" if ok else "FAIL", " ".join(reasons))
	quit(0 if ok else 1)
