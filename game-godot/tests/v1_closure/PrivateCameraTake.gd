extends SceneTree

## Lightweight native text-resource tests; no models, battle, saves or render.
const TAKE := preload("res://scripts/story/ova_private_camera_take.gd")
var failures: Array = []
var checks := 0
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

func _run() -> void:
	var private_manifest := ""
	var canonical_nodes_path := ""
	var canonical_cues_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--test-output="): output = argument.trim_prefix("--test-output=")
		if argument.begins_with("--private-camera-library="): private_manifest = argument.trim_prefix("--private-camera-library=")
		if argument.begins_with("--canonical-nodes="): canonical_nodes_path = argument.trim_prefix("--canonical-nodes=")
		if argument.begins_with("--canonical-cues="): canonical_cues_path = argument.trim_prefix("--canonical-cues=")
	if not output.is_absolute_path():
		push_error("Provide an isolated absolute --test-output directory")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var animation := Animation.new()
	animation.length = 2.0
	for name in ["focus_mix", "zoom", "offset"]:
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("Camera:" + name))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
		var values: Array = [0.2, 0.4, 0.8] if name == "focus_mix" else [1.0, 1.5, 1.5] if name == "zoom" else [Vector2(0, -50), Vector2(0, -60), Vector2(0, -60)]
		for key in range(3): animation.track_insert_key(track, float(key), values[key])
	var take_path := output.path_join("synthetic_camera.tres")
	ResourceSaver.save(animation, take_path)
	var original := FileAccess.get_file_as_bytes(take_path)
	var node := "SYNTHETIC:first_loss"
	var ids := ["SYNTHETIC_001", "SYNTHETIC_002"]
	var canonical := {node: {"ordered_cues": ids}}
	var manifest := {"schema": TAKE.SCHEMA, "candidate_only": true, "public_disclosure_authorized": false, "frame_domain": "DIALOGUE_CUE_ORDINAL", "gameplay_authority": false, "canonical_cues_sha256": "SYNTHETIC_HASH", "nodes": {node: {"path": "synthetic_camera.tres", "sha256": FileAccess.get_sha256(take_path), "ordered_cues": ids}}}
	var path := output.path_join("synthetic_manifest.json")
	_write(path, JSON.stringify(manifest))
	var reader = TAKE.new()
	_check(reader.load_library(path, "SYNTHETIC_HASH", canonical), "Valid isolated manifest loads")
	_check(reader.select_node(node), "Native Animation text resource imports")
	reader.begin_cue(ids[0], 10.0)
	var beginning: Dictionary = reader.sample(10.0)
	var middle: Dictionary = reader.sample(5.0)
	_check(is_equal_approx(beginning.zoom, 1.0) and middle.zoom > beginning.zoom, "Editable camera curve advances inside actual cue")
	_check(reader.sample(5.0) == middle, "Paused cue clock produces no camera drift")
	_check(float(reader.sample(-100.0).focus_mix) < 0.4, "Long hold cannot enter next cue's shot")
	reader.begin_cue(ids[1], 25.0)
	_check(float(reader.sample(25.0).focus_mix) >= 0.4, "Actual cue advance selects the next authored shot")
	reader.begin_cue("UNKNOWN", 10.0)
	_check(reader.sample(0.0).is_empty(), "Foreign cue cannot play a stale shot")
	reader.clear_node()
	_check(reader.sample(0.0).is_empty(), "Seek/cancel clears selected camera source")
	_check(not reader.select_node("UNAUTHORED"), "Unauthored nodes retain established fallback")
	reader.select_node(node)
	reader.begin_cue(ids[0], 10.0)
	var held: Dictionary = reader.presentation_sample(5.0)
	reader.begin_cue(ids[1], 25.0)
	_check(reader.presentation_sample(25.0) == held, "Cue advance begins at last displayed framing, without a zoom snap")
	var transitioning: Dictionary = reader.presentation_sample(24.85)
	_check(transitioning.zoom > held.zoom and transitioning.zoom < float(reader.sample(24.85).zoom), "Cue transition eases between valid authored frames")
	_check(reader.presentation_sample(24.85) == transitioning, "Paused transition has no wall-clock drift")
	_check(reader.presentation_sample(24.0) == reader.sample(24.0), "Transition converges to the actual native curve")
	reader.begin_cue(ids[0], 10.0)
	var rapid_advance: Dictionary = reader.presentation_sample(10.0)
	_check(rapid_advance == reader.presentation_sample(10.0), "Rapid advance retains a deterministic transition origin")
	reader.clear_node()
	reader.select_node(node)
	reader.begin_cue(ids[0], 10.0)
	var reduced: Dictionary = reader.presentation_sample(10.0, true)
	_check(reader.presentation_sample(1.0, true) == reduced, "Reduced-motion presentation holds cue framing instead of intra-line pan/zoom")
	_check(reader.sample(1.0) != reduced, "Accessibility does not rewrite the original editable curve")
	reader.begin_cue(ids[1], 10.0)
	_check(reader.presentation_sample(10.0, true) == reduced, "Reduced-motion cue transition remains continuous")
	var reduced_next: Dictionary = reader.presentation_sample(9.0, true)
	_check(reduced_next == reader.sample(10.0), "Reduced motion still reaches the next cue's distinct framing")
	reader.clear_node()
	_check(reader.presentation_sample(0.0).is_empty(), "Cancel clears displayed camera and transition state")
	reader.select_node(node)
	reader.begin_cue(ids[0], 10.0)
	_check(reader.presentation_sample(10.0) == reader.sample(10.0), "Chapter selection cannot blend a canceled chapter into a new take")
	_check(not reader.load_library("res://synthetic_manifest.json", "SYNTHETIC_HASH", canonical), "Private source cannot be a packaged res path")
	_check(not reader.load_library(path, "WRONG_HASH", canonical), "Canonical source drift fails closed")
	reader.load_library(path, "SYNTHETIC_HASH", canonical)
	_write(take_path, FileAccess.get_file_as_string(take_path) + "\n; tamper\n")
	_check(not reader.select_node(node), "Edited resource must have renewed provenance hash")
	var restore := FileAccess.open(take_path, FileAccess.WRITE)
	restore.store_buffer(original)
	restore.close()
	var wrong := canonical.duplicate(true)
	wrong[node]["ordered_cues"].reverse()
	reader.load_library(path, "SYNTHETIC_HASH", wrong)
	_check(not reader.select_node(node), "Cue reordering cannot alter canonical dialogue")
	var callbacks := animation.add_track(Animation.TYPE_METHOD)
	animation.track_set_path(callbacks, NodePath("Forbidden"))
	animation.track_insert_key(callbacks, 0.0, {"method": "queue_free", "args": []})
	ResourceSaver.save(animation, take_path)
	manifest["nodes"][node]["sha256"] = FileAccess.get_sha256(take_path)
	_write(path, JSON.stringify(manifest))
	reader.load_library(path, "SYNTHETIC_HASH", canonical)
	_check(not reader.select_node(node), "Method/callback tracks cannot execute from private camera source")
	var imported := 0
	var actual_cues := 0
	if not private_manifest.is_empty():
		var nodes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(canonical_nodes_path))["nodes"]
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(private_manifest))
		_check(reader.load_library(private_manifest, FileAccess.get_sha256(canonical_cues_path), nodes), "Actual private library canonical hash")
		for id in data["nodes"]:
			_check(reader.select_node(id), "Actual native camera resource: " + str(id))
			imported += 1
			for cue_id in nodes[id]["ordered_cues"]:
				reader.begin_cue(str(cue_id), 15.0)
				_check(not reader.sample(15.0).is_empty() and not reader.sample(0.0).is_empty(), "Actual canonical cue camera values")
				actual_cues += 1
	var result := {"PASS": failures.is_empty(), "checks": checks, "failures": failures, "actual_camera_animations_imported": imported, "actual_canonical_cue_bindings_sampled": actual_cues, "native_scope": "Headless native Animation import/sampling only; no fighter models, rendering, body acting, native audio or gameplay", "rendered_motion_verified": false, "human_approved": false}
	_write(output.path_join("native_camera_source_results.json"), JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
