extends Node
class_name FighterAnimationController

## Single canonical animation controller — observes Fighter state, does not author gameplay.

const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")

var _fighter
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _skeleton_path: NodePath = NodePath()
var _loaded_clips: Dictionary = {}
var _fighter_id: String = ""
var _active_clip: String = ""
var _throw_dir: String = "forward"
var _move_synchronized := false
var presentation_frozen := false


func setup(fighter, model_root: Node3D) -> void:
	_fighter = fighter
	_fighter_id = ""
	if fighter != null:
		if "fighter_id" in fighter:
			_fighter_id = str(fighter.fighter_id)
		elif fighter.has_method("get"):
			_fighter_id = str(fighter.get("fighter_id"))
	_skeleton = _find_skeleton(model_root)
	if _skeleton == null:
		return
	_skeleton_path = model_root.get_path_to(_skeleton)
	if _should_use_embedded_candidate(model_root):
		var embedded := _find_embedded_player(model_root)
		if embedded != null:
			_player = embedded
			_player.active = true
			_player.process_mode = Node.PROCESS_MODE_INHERIT
			_ingest_embedded_clips()
			# Staging GLBs often only embed idle. Combat clips still come from V3 procedural JSON.
			_load_procedural_clips(model_root)
			_load_authored_studies()
			return
	_disable_embedded_players(model_root)
	_player = AnimationPlayer.new()
	_player.name = "CanonicalProceduralAnimationPlayer"
	model_root.add_child(_player)
	_load_procedural_clips(model_root)


func play_for_state(state: String, move: Dictionary = {}) -> void:
	_move_synchronized = state.begins_with("attack") or state.begins_with("special") or state.begins_with("aura_burst") or state.begins_with("throw")
	if _player == null or not is_instance_valid(_player):
		return
	if _skeleton == null or not is_instance_valid(_skeleton):
		return
	if move.has("throw_direction"):
		_throw_dir = str(move.get("throw_direction", "forward"))
	var move_id := str(move.get("move_id", ""))
	var resolved: Dictionary = _MoveResolver.resolve_clip(state, move_id, _loaded_clips)
	var clip := str(resolved.get("clip", ""))
	if clip.is_empty() or not _loaded_clips.has(clip):
		clip = _fallback_clip(state, move_id)
	var play_key := _animation_play_key(clip)
	if clip.is_empty() or play_key.is_empty() or not _player.has_animation(play_key):
		return
	var should_loop := clip in [
		"idle", "idle_primary", "idle_secondary", "run", "run_loop", "walk", "walk_loop",
		"fall", "fast_fall", "shield", "shield_hold", "aura_charge", "aura_ready", "charged_idle",
		"ledge_hang", "crouch_hold",
	]
	var anim := _player.get_animation(play_key)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	if _player.current_animation != play_key and _player.current_animation != clip:
		_player.play(play_key, 0.08)
	elif not should_loop and not _player.is_playing():
		_player.play(play_key, 0.08)
	_active_clip = clip


func get_active_clip() -> String:
	return _active_clip


func get_skeleton() -> Skeleton3D:
	return _skeleton


func get_animation_player() -> AnimationPlayer:
	return _player


func get_loaded_clip_names() -> Array:
	return _loaded_clips.keys()


func _animation_play_key(clip: String) -> String:
	if _player != null and _player.has_animation("authored_studies/"+clip): return "authored_studies/"+clip
	if clip.is_empty() or _player == null:
		return ""
	if _player.has_animation(clip):
		return clip
	for lib_name in ["procedural_runtime", "candidate_aliases"]:
		var keyed := "%s/%s" % [lib_name, clip]
		if _player.has_animation(keyed):
			return keyed
	return ""


func _fallback_clip(state: String, move_id: String) -> String:
	if state in [_FighterStates.THROW_STARTUP, _FighterStates.THROW_RELEASE]:
		var dir_clip := "throw_%s" % _throw_dir
		if _loaded_clips.has(dir_clip):
			return dir_clip
	return str(_FighterStates.animation_for_state(state))


func _load_procedural_clips(model_root: Node3D) -> void:
	var info: Dictionary = _AssetResolver.resolve_animation_root(_fighter_id)
	var root_path := str(info.get("root", ""))
	if root_path.is_empty():
		return
	var abs_root := ProjectSettings.globalize_path(root_path)
	if not DirAccess.dir_exists_absolute(abs_root):
		return
	var lib := AnimationLibrary.new()
	var dir := DirAccess.open(abs_root)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".anim.json") and not dir.current_is_dir():
			var clip_name := file_name.replace(".anim.json", "")
			var anim := _animation_from_json(abs_root.path_join(file_name))
			if anim:
				lib.add_animation(clip_name, anim)
				_loaded_clips[clip_name] = true
		file_name = dir.get_next()
	dir.list_dir_end()
	if lib.get_animation_list().size() > 0:
		var lib_name := "procedural_runtime"
		if _player.has_animation_library(lib_name):
			_player.remove_animation_library(lib_name)
		_player.add_animation_library(lib_name, lib)


func _animation_from_json(path: String) -> Animation:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return _animation_from_data(parsed)

func _animation_from_data(data: Dictionary) -> Animation:
	var anim := Animation.new()
	anim.length = maxf(float(data.get("duration_frames", 24)) / 60.0, 0.05)
	var tracks: Dictionary = data.get("bone_tracks", {})
	for bone in tracks.keys():
		var keys: Array = tracks[bone]
		if keys.is_empty():
			continue
		var glb_bone := _BoneMap.resolve_on_skeleton(_skeleton, str(bone))
		if glb_bone.is_empty():
			continue
		var track_idx := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track_idx, NodePath("%s:%s" % [_skeleton_path, glb_bone]))
		for key in keys:
			var rot: Array = key.get("rotation_rad", [0.0, 0.0, 0.0])
			var quat := Quaternion.from_euler(Vector3(float(rot[0]), float(rot[1]), float(rot[2])))
			if bool(data.get("relative_to_rest",false)):
				quat = _skeleton.get_bone_rest(_skeleton.find_bone(glb_bone)).basis.get_rotation_quaternion() * quat
			anim.track_insert_key(track_idx, float(key.get("time_s", 0.0)), quat)
	return anim


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _disable_embedded_players(node: Node) -> void:
	if node is AnimationPlayer and node.name != "CanonicalProceduralAnimationPlayer":
		node.active = false
		node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in node.get_children():
		_disable_embedded_players(child)


func _should_use_embedded_candidate(_model_root: Node3D) -> bool:
	if str(_model_root.name).begins_with("CollectibleV1_"):
		return true
	if not _AssetResolver.staging_review_enabled():
		return false
	var info: Dictionary = _AssetResolver.resolve_model_path(_fighter_id)
	return str(info.get("path", "")).contains("human_art_staging")


func _find_embedded_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_embedded_player(child)
		if found:
			return found
	return null


func _ingest_embedded_clips() -> void:
	if _player == null:
		return
	for lib_name in _player.get_animation_library_list():
		var lib: AnimationLibrary = _player.get_animation_library(lib_name)
		if lib == null:
			continue
		for clip in lib.get_animation_list():
			_loaded_clips[str(clip)] = true
	var aliases := {
		"charge": "charged_idle",
		"aura_charge": "charged_idle",
		"hurt": "hurt_heavy",
		"clash": "clash_lock",
		"launched": "launch",
	}
	var extra := AnimationLibrary.new()
	for alias in aliases.keys():
		var src := str(aliases[alias])
		if _player.has_animation(src) and not _player.has_animation(alias):
			extra.add_animation(alias, _player.get_animation(src))
			_loaded_clips[alias] = true
	if extra.get_animation_list().size() > 0:
		_player.add_animation_library("candidate_aliases", extra)

func _load_authored_studies() -> void:
	var path := "res://data/animation/authored_studies/%s.json" % _fighter_id
	if not FileAccess.file_exists(path): return
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var library := AnimationLibrary.new()
	for clip in doc.clips:
		var anim := _animation_from_data(doc.clips[clip])
		anim.loop_mode = Animation.LOOP_LINEAR if doc.clips[clip].get("loop",false) else Animation.LOOP_NONE
		library.add_animation(clip,anim);_loaded_clips[clip]=true
	_player.add_animation_library("authored_studies",library)
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _process(delta: float) -> void:
	if _player != null and is_instance_valid(_player) and _player.has_animation_library("authored_studies") and not _move_synchronized and not presentation_frozen:
		_player.advance(delta)

func synchronize_move(frame: int,move: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player): return
	var key := "authored_studies/"+str(move.get("move_id",""))
	if not _player.has_animation(key): return
	_move_synchronized = true
	if _player.current_animation != key: _player.play(key,0)
	_player.seek(float(frame)/60.0,true)
