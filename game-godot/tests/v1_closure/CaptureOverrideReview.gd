extends SceneTree
const Data = preload("res://scripts/data/data_loader.gd")
const Model = preload("res://scripts/fighters/fighter_model_3d.gd")
const SFX = preload("res://scripts/audio/v1_candidate_sfx.gd")
const Acting = preload("res://scripts/visual/collectible_expression_controller.gd")
var output := "res://../artifacts/v1_closure/review/owner_override"
var evidence: Array = []
var audio_events: Array = []
var video_frame := 0
func _init() -> void: call_deferred("_run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func capture_root(path: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	root.get_texture().get_image().save_png(path)
func _run() -> void:
	var state = root.get_node("GameState")
	var router = root.get_node("SceneRouter")
	var campaign = root.get_node("CampaignRuntime")
	for fid in Data.roster_ids():
		for variant in ["male", "female"]:
			var model = Model.new()
			root.add_child(model)
			var data: Dictionary = Data.load_fighter(fid).duplicate(true)
			data["body_variant"] = variant
			model.configure(data)
			model.set_presentation_context("showcase")
			model.get("_loaded_model").rotation_degrees.y = 0
			model.get("_model_root").scale = Vector3.ONE
			var camera = model.get("_camera")
			camera.size = 0.82
			camera.position = Vector3(0, 1.15, 5)
			camera.look_at(Vector3(0, 1.15, 0))
			for expression in ["neutral"] + Acting.EXPRESSIONS:
				model.set_cinematic_expression(expression)
				model.get("_expression_controller").set_expression(expression, true)
				await frames(2)
				await RenderingServer.frame_post_draw
				var dest: String = output + "/expressions/" + fid + "/" + variant + "/" + expression + ".png"
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest.get_base_dir()))
				model.get("_viewport").get_texture().get_image().save_png(dest)
			model.queue_free()
			await process_frame
		print("CAPTURE_FACES ",fid)
	campaign.watch_route_id = "kaia-windrow"
	campaign.watch_presentation = "female"
	router.go("ova")
	await frames(20)
	var watch = current_scene
	# Record the real continuous opening preview at 8 fps; the actual watch clock runs at 60 Hz.
	for i in range(1200):
		if not watch.playing:
			break
		video_frame = i
		if watch._battle != null:
			for actor in watch._battle.fighters_root.get_children():
				if not actor.has_meta("capture_sfx"):
					actor.set_meta("capture_sfx", true)
					actor.move_runner.move_started.connect(func(mid: String):
						audio_events.append({"frame":video_frame, "fighter_id":actor.fighter_id, "event":"super_startup" if mid == "aura_burst" else "whiff"}))
					actor.hit_resolver.hit_confirmed.connect(func(attacker: Node, _defender: Node, info: Dictionary):
						var move: Dictionary = Data.find_move(attacker.move_manifest, str(info.get("move_id", "")))
						audio_events.append({"frame":video_frame, "fighter_id":attacker.fighter_id, "event":"block" if info.get("blocked", false) else SFX.impact_event(move)}))
		await capture_root(output + "/ova/frames/%04d.png" % i)
		await frames(8)
	await watch.seek(8)
	await frames(12)
	await capture_root(output + "/ova/catastrophe.png")
	await watch.seek(9)
	await frames(24)
	await capture_root(output + "/ova/cosmic_encounter.png")
	await watch.seek(10)
	await frames(12)
	await capture_root(output + "/ova/first_loss.png")
	router.go("story")
	await frames(12)
	await capture_root(output + "/ova/variation_selector.png")
	var file := FileAccess.open(output + "/capture_manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"mode":"real Godot Compatibility renderer", "source_sha":root.get_node("BuildIdentity").git_sha(), "expressions":18*11, "audio_events":audio_events, "video_capture_fps":7.5, "movie_audio":"Candidate WAVs aligned to actual move-start/contact events; final OVA voice/music/mix unfinished", "ova_scope":"continuous opening through two-boss encounter, canonical Rook loss, then technical stop; preview only", "owner_approved":false}, "  ")+"\n");file.close()
	print("CAPTURE_OVERRIDE_COMPLETE")
	quit()
