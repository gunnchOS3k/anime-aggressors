extends SceneTree
## Real loaded rigs and animation libraries; declared transition fixture only.
## Ordinary opponent/contact acceptance is recorded separately.
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const Data = preload("res://scripts/data/data_loader.gd")
const Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func pose(sk: Skeleton3D) -> Dictionary:
	sk.force_update_all_bone_transforms()
	var result: Dictionary = {}
	for name in ["Hips", "Chest", "Head", "Hand_L", "Hand_R", "Foot_L", "Foot_R"]:
		result[name] = sk.get_bone_global_pose(sk.find_bone(name))
	return result
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	for fid in Renderer.IDS:
		for body in ["male", "female"]:
			var model = Model.new(); root.add_child(model)
			model.configure(Data.load_fighter(fid), body); await process_frame
			var c = model.get_animation_controller(); var player = c.get_animation_player()
			var sk: Skeleton3D = c.get_skeleton()
			for facing in [1, -1]:
				model.set_facing(facing)
				player.play("combat_choreography/idle_primary", 0); player.seek(0, true)
				var neutral := pose(sk)
				for mid in ["jab_1", "heavy_attack"]:
					var move: Dictionary = Data.find_move(Data.load_moves(fid), mid)
					var entry_error := 0.0; var exit_error := 0.0; var support_error := 0.0
					var key: String = mid + ("_left" if facing == -1 else "")
					var duration: int = c._choreography_timing[key].duration_frames
					var support: String = "Foot_" + str(c._choreography_timing[key].support_foot)
					for f in range(duration + 1):
						c.synchronize_move(f, move)
						var now := pose(sk)
						for name in neutral:
							var error: float = neutral[name].origin.distance_to(now[name].origin)
							if f == 0: entry_error = maxf(entry_error, error)
							if f == duration: exit_error = maxf(exit_error, error)
						# Existing authored support-foot contract, numerical solver tolerance.
						support_error = maxf(support_error, neutral[support].origin.distance_to(now[support].origin))
					var label: String = fid + ":" + body + ":" + str(facing) + ":" + mid
					check(entry_error < .00001, label + ":authored_guard_entry")
					check(exit_error < .00001, label + ":authored_guard_return")
					check(support_error < .001, label + ":existing_support_contract")
					rows.append({"fighter": fid, "body": body, "facing": facing, "move": mid, "model_path": model._proxy_model.scene_file_path, "entry_error_m": entry_error, "exit_error_m": exit_error, "support_error_m": support_error})
			model.queue_free(); await process_frame
	var f = FileAccess.open(output.path_join("melee_guard_continuity.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS": failures.is_empty(), "rows": rows, "failures": failures, "scope": "live rig authored pose boundaries and original support tolerance; not absolute floor fit, active CPU gameplay or human art approval"}, "  ")); f.close()
	print("MELEE_GUARD_CONTINUITY ", "PASS" if failures.is_empty() else "FAIL", " cases=", rows.size())
	quit(0 if failures.is_empty() else 1)
