extends SceneTree

## Actual GLB skeletal/action sampling. No BattleScene, gameplay or art approval.
const SERIALIZATION_EPSILON_M := 0.00005 # Same saved-source float/FK bound as8D4.
const CLIP := "ANI08D4_REFERENCE_HOLD_PAIR"
var failures: Array = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func skeletons(node: Node, found: Array) -> void:
	if node is Skeleton3D: found.append(node)
	for child in node.get_children(): skeletons(child, found)

func players(node: Node, found: Array) -> void:
	if node is AnimationPlayer: found.append(node)
	for child in node.get_children(): players(child, found)

func skinned_meshes(node: Node) -> int:
	var count := int(node is MeshInstance3D and node.skin != null)
	for child in node.get_children(): count += skinned_meshes(child)
	return count

func xyz(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

func transform_error(actual: Transform3D, expected: Array) -> float:
	var error := actual.origin.distance_to(Vector3(expected[0][3],expected[1][3],expected[2][3]))
	for column in range(3):
		error = maxf(error, actual.basis[column].distance_to(Vector3(expected[0][column],expected[1][column],expected[2][column])))
	return error

func run() -> void:
	var manifest_path := ""
	var output := ""
	var synthetic := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--animation-manifest="): manifest_path = arg.trim_prefix("--animation-manifest=")
		if arg.begins_with("--test-output="): output = arg.trim_prefix("--test-output=")
		if arg == "--synthetic-fixture": synthetic = true
	if not manifest_path.is_absolute_path() or not output.is_absolute_path():
		push_error("Explicit private manifest/output paths required")
		quit(2)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var entries: Array = manifest.get("rows",[])
	check(entries.size() == 1, "one_explicit_pilot")
	if entries.size() != 1:
		quit(1)
		return
	var entry: Dictionary = entries[0].get("animated_reference",{})
	var asset := manifest_path.get_base_dir().path_join(str(entry.get("resource",""))).simplify_path()
	check(asset.begins_with(manifest_path.get_base_dir().simplify_path()+"/"), "private_export_path")
	check(FileAccess.get_sha256(asset) == entry.get("sha256",""), "actual_export_hash")
	check(entry.get("source_frame_count") == 25 and entry.get("FPS") == 60, "source_clock_unchanged")
	check(entry.get("actors",[]).size() == 2 and entry.get("pose_frames",[]).size() == 25, "two_actors_25_source_frames")
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	check(document.append_from_file(asset,state) == OK, "actual_binary_GLTF_import")
	var scene := document.generate_scene(state)
	check(scene is Node3D, "actual_animated_scene")
	if not failures.is_empty():
		if scene != null: scene.free()
		quit(1)
		return
	root.add_child(scene)
	await process_frame
	check(skinned_meshes(scene) >= 2, "actual_skinned_meshes")
	var imported_players: Array = []
	players(scene,imported_players)
	check(imported_players.size() == 1, "single_synchronized_animation_player")
	var player: AnimationPlayer = imported_players[0] if imported_players.size() == 1 else null
	var clip := ""
	if player != null:
		for name in player.get_animation_list():
			if String(name).get_file() == CLIP: clip = name
	check(not clip.is_empty(), "original_combined_clip_imported")
	var rigs := {}
	var anchors := {}
	for definition: Dictionary in entry.actors:
		var anchor := scene.find_child(str(definition.anchor),true,false) as Node3D
		check(anchor != null, "actor_anchor:"+str(definition.role))
		if anchor == null: continue
		anchors[definition.role] = anchor
		var found: Array = []
		skeletons(anchor,found)
		check(found.size() == 1, "one_owned_skeleton:"+str(definition.role))
		if found.size() != 1: continue
		var rig: Skeleton3D = found[0]
		rigs[definition.role] = rig
		check(rig.get_bone_count() == definition.bone_names.size(), "preserved_bone_count:"+str(definition.role))
		for bone in definition.bone_names:
			check(rig.find_bone(str(bone)) >= 0, "original_bone_id:"+str(definition.role)+":"+str(bone))
	if failures.is_empty():
		var animation := player.get_animation(clip)
		check(absf(animation.length-0.4) <= 0.000001, "native_clip_duration")
		for track in range(animation.get_track_count()):
			check(animation.track_get_type(track) in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D,Animation.TYPE_BLEND_SHAPE], "no_gameplay_method_audio_or_callback_tracks")
	var maximum_error := 0.0
	var joint_samples := 0
	if failures.is_empty():
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.play(clip)
		for frame: Dictionary in entry.pose_frames:
			# Real AnimationPlayer seek/advance, not a parallel pose evaluator.
			player.seek(float(frame.frame)/60.0,true)
			player.advance(0.0)
			await process_frame
			for actor: Dictionary in frame.actors:
				var rig: Skeleton3D = rigs[actor.role]
				var anchor: Node3D = anchors[actor.role]
				var anchor_error := transform_error(anchor.global_transform,actor.anchor_transform_stage_m)
				maximum_error = maxf(maximum_error,anchor_error)
				check(anchor_error <= SERIALIZATION_EPSILON_M, "frozen_source_actor_placement")
				rig.force_update_all_bone_transforms()
				for bone in actor.bones_stage_m:
					var index := rig.find_bone(str(bone))
					var actual := rig.global_transform * rig.get_bone_global_pose(index).origin
					var error := actual.distance_to(xyz(actor.bones_stage_m[bone]))
					maximum_error = maxf(maximum_error,error)
					joint_samples += 1
					check(error <= SERIALIZATION_EPSILON_M, "native_source_joint:"+str(actor.role)+":"+str(bone)+":"+str(frame.frame))
	var report := {"PASS":failures.is_empty(),"checks":checks,"failures":failures,"source_export_sha256":entry.get("sha256"),"joint_samples":joint_samples,"max_source_joint_error_m":maximum_error,"source_frames":25,"actors":rigs.size(),"synthetic_fixture":synthetic,"skeletal_pose_equivalence_verified":failures.is_empty(),"skinned_surface_equivalence_verified":false,"release_acting_verified":false,"visual_review_verified":false,"RUNTIME_PAIRED_CONTACT_VERIFIED":false,"human_approved":false,"scope":"Native imported skeletal AnimationPlayer sampling only; not skin-surface contact, release acting, shipping gameplay, visual taste or device acceptance"}
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output.path_join("paired_animation_playback.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
