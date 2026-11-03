extends SceneTree

## Real existing character models/actions through their presentation API.
## No synthetic skeleton, combat outcome, new art or paired-contact acceptance.
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
var output := ""
var rows: Array = []
var failures: Array = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func pose(skeleton: Skeleton3D) -> Array:
	var result: Array = []
	for i in skeleton.get_bone_count(): result.append(skeleton.get_bone_pose_rotation(i))
	return result

func run() -> void:
	create_timer(35).timeout.connect(func(): push_error("existing clip playback watchdog"); quit(2))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.trim_prefix("--ordinary-output=")
	await process_frame
	for fid in ["kaia-windrow", "rook-ironside"]:
		for body in ["male", "female"]:
			var model = Model.new()
			root.add_child(model)
			model.configure(Data.load_fighter(fid), body)
			await process_frame
			var controller = model.get_animation_controller()
			var player: AnimationPlayer = controller.get_animation_player()
			var skeleton: Skeleton3D = controller.get_skeleton()
			check(model.is_model_loaded(), fid + body + ":existing_model_loaded")
			for clip in ["aura_charge", "grab_recovery", "throw_forward"]:
				var label: String = fid + ":" + body + ":" + clip
				model.play_clip("idle")
				check(controller.get_active_clip() == "idle_primary", label + ":canonical_idle_guard_preserved")
				model.play_clip(clip)
				var selected: String = controller.get_active_clip()
				var before := pose(skeleton)
				for i in range(12): controller._process(1.0 / 60.0)
				var after := pose(skeleton)
				var rotation_travel := 0.0
				for i in before.size(): rotation_travel = maxf(rotation_travel, before[i].angle_to(after[i]))
				var clock: float = player.current_animation_position
				check(selected == clip, label + ":requested_clip_selected")
				check(clock >= .19, label + ":independent_clock_advances")
				check(rotation_travel > .001, label + ":existing_body_acting_advances")
				controller.presentation_frozen = true
				controller._process(.1)
				check(is_equal_approx(player.current_animation_position, clock), label + ":freeze_holds")
				controller.presentation_frozen = false
				rows.append({"fighter":fid, "body":body, "requested":clip, "selected":selected,
					"time_after_twelve_steps_s":clock, "max_bone_rotation_change_radians":rotation_travel,
					"saved_source_action":controller._grab_acting_sources.get(clip, {}),
					"model_source":model.get("_current_model_source")})
			# Returning to an actual move must immediately restore its authority.
			var move := {"move_id":"jab_1", "startup_frames":6, "active_frames":3, "recovery_frames":12}
			model.play_for_state("attack_startup", move)
			var active_clock: float = player.current_animation_position
			controller._process(.1)
			check(is_equal_approx(player.current_animation_position, active_clock), fid + body + ":gameplay_clock_not_replaced")
			controller.synchronize_move(3, move)
			check(player.current_animation_position > active_clock, fid + body + ":resolved_move_clock_still_owned")
			model.play_for_state("shield_hold")
			check(controller.get_active_clip() == "shield_hold", fid + body + ":state_selection_restored")
			model.queue_free()
			await process_frame
	var file := FileAccess.open(output.path_join("existing_clip_playback.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"PASS":failures.is_empty(), "rows":rows, "failures":failures,
		"synthetic_character":false, "new_source_art":false, "native_visual_verified":false,
		"paired_contact_verified":false, "human_approved":false,
		"scope":"Existing character meshes and source actions through real Godot presentation API; headless, not gameplay or paired acting acceptance."}, "\t"))
	file.close()
	print("EXISTING_CLIP_PLAYBACK ", "PASS" if failures.is_empty() else "FAIL", " cases=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
