extends Node
class_name FighterAnimationController

## State-driven animation controller — observes Fighter state, does not author gameplay.

const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")

var _fighter
var _player: AnimationPlayer
var _tree: AnimationTree
var _state_machine: AnimationNodeStateMachinePlayback
var _loaded_clips: Dictionary = {}
var _fighter_id: String = ""


func setup(fighter, model_root: Node3D) -> void:
	_fighter = fighter
	_fighter_id = str(fighter.fighter_id if fighter else "")
	_player = AnimationPlayer.new()
	_player.name = "ProceduralAnimationPlayer"
	add_child(_player)
	_tree = AnimationTree.new()
	_tree.name = "ProceduralAnimationTree"
	_tree.tree_root = AnimationNodeBlendTree.new()
	_tree.anim_player = _player.get_path()
	add_child(_tree)
	_load_procedural_clips(model_root)
	_tree.active = true


func play_for_state(state: String, move: Dictionary = {}) -> void:
	var clip := _clip_for_state(state, str(move.get("move_id", "")))
	if clip.is_empty():
		return
	if _player.has_animation(clip):
		var should_loop := clip in ["idle", "run", "walk", "fall", "shield", "aura_charge"]
		var anim := _player.get_animation(clip)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
		if _player.current_animation != clip or (not should_loop and not _player.is_playing()):
			_player.play(clip)


func _load_procedural_clips(_model_root: Node3D) -> void:
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
		_player.add_animation_library("", lib)


func _animation_from_json(path: String) -> Animation:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = parsed
	var anim := Animation.new()
	anim.length = float(data.get("duration_frames", 24)) / 60.0
	var tracks: Dictionary = data.get("bone_tracks", {})
	for bone in tracks.keys():
		var keys: Array = tracks[bone]
		if keys.is_empty():
			continue
		var track_idx := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track_idx, NodePath("ModelRoot/%s" % bone))
		for key in keys:
			var rot: Array = key.get("rotation_rad", [0.0, 0.0, 0.0])
			var quat := Quaternion.from_euler(Vector3(float(rot[0]), float(rot[1]), float(rot[2])))
			anim.track_insert_key(track_idx, float(key.get("time_s", 0.0)), quat)
	return anim


func _clip_for_state(state: String, move_id: String) -> String:
	if move_id != "" and _loaded_clips.has(move_id):
		return move_id
	if move_id.begins_with("signature_") and _loaded_clips.has(move_id):
		return move_id
	return str(_FighterStates.animation_for_state(state))
