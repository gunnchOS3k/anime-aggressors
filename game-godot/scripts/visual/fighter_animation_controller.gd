extends Node
class_name FighterAnimationController

## Single canonical animation controller — observes Fighter state, does not author gameplay.

const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")
const _Charged = preload("res://scripts/visual/charged_animation_layer.gd")
const _Provenance = preload("res://scripts/visual/animation_provenance.gd")
const _Authored = preload("res://scripts/visual/authored_clip_loader.gd")

var _fighter
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _skeleton_path: NodePath = NodePath()
var _loaded_clips: Dictionary = {}
var _clip_provenance: Dictionary = {}
var _fighter_id: String = ""
var _active_clip: String = ""
var _throw_dir: String = "forward"
var _charge_pct: float = 0.0
var _prev_state: String = ""


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
	_disable_embedded_players(model_root)
	_player = AnimationPlayer.new()
	_player.name = "CanonicalProceduralAnimationPlayer"
	model_root.add_child(_player)
	_load_procedural_clips(model_root)
	_load_authored_proof()


func set_charge_pct(pct: float) -> void:
	_charge_pct = pct


func play_for_state(state: String, move: Dictionary = {}) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _skeleton == null or not is_instance_valid(_skeleton):
		return
	if move.has("throw_direction"):
		_throw_dir = str(move.get("throw_direction", "forward"))
	if move.has("attacker_aura"):
		_charge_pct = float(move.get("attacker_aura", _charge_pct))
	var move_id := str(move.get("move_id", ""))
	var reaction_clip := str(move.get("reaction_clip", ""))
	if reaction_clip != "" and _loaded_clips.has(reaction_clip) and _player.has_animation(reaction_clip):
		_play_named(reaction_clip, false)
		_prev_state = state
		return
	var resolved: Dictionary = _MoveResolver.resolve_clip(state, move_id, _loaded_clips)
	var clip := str(resolved.get("clip", ""))
	if clip == "special":
		# No silent generic special. Prefer explicit move clip or projectile_full.
		clip = ""
	if clip.is_empty() or not _loaded_clips.has(clip):
		clip = _fallback_clip(state, move_id)
	if clip == "special":
		if _loaded_clips.has("projectile_full"):
			clip = "projectile_full"
		else:
			return
	clip = _loco_transition_clip(state, clip)
	if _Charged.should_apply(_fighter_id, move) or _charge_pct >= 25.0:
		clip = _Charged.overlay_clip(clip, move, _charge_pct, _loaded_clips)
	if clip.is_empty() or not _player.has_animation(clip):
		return
	_play_named(clip, clip in ["idle", "idle_personality", "run", "walk", "fall", "shield", "aura_charge", "charged_idle", "charged_walk", "charged_run", "charge_low", "charge_mid", "charge_high", "charge_full"])
	_prev_state = state


func _play_named(clip: String, should_loop: bool) -> void:
	var anim := _player.get_animation(clip)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	if _player.current_animation != clip or (not should_loop and not _player.is_playing()):
		_player.play(clip, 0.08)
	_active_clip = clip


func get_active_clip() -> String:
	return _active_clip


func get_skeleton() -> Skeleton3D:
	return _skeleton


func get_animation_player() -> AnimationPlayer:
	return _player


func get_loaded_clip_names() -> Array:
	return _loaded_clips.keys()


func get_clip_provenance(clip: String = "") -> String:
	var name := clip if not clip.is_empty() else _active_clip
	if _clip_provenance.has(name):
		return str(_clip_provenance[name])
	return _Provenance.status_for(_fighter_id, name)


func get_provenance_debug() -> String:
	return _Provenance.debug_line(_fighter_id, _active_clip)


func _fallback_clip(state: String, move_id: String) -> String:
	if state in [_FighterStates.THROW_STARTUP, _FighterStates.THROW_RELEASE]:
		var dir_clip := "throw_%s" % _throw_dir
		if _loaded_clips.has(dir_clip):
			return dir_clip
	var named := str(_FighterStates.animation_for_state(state))
	if named == "special":
		if _loaded_clips.has("projectile_full"):
			return "projectile_full"
		return ""
	if _loaded_clips.has(named):
		return named
	if named == "landing" and _loaded_clips.has("landing"):
		return "landing"
	if named == "land" and _loaded_clips.has("landing"):
		return "landing"
	return named


func _loco_transition_clip(state: String, clip: String) -> String:
	if state == _FighterStates.WALK and _prev_state == _FighterStates.IDLE and _loaded_clips.has("walk_start"):
		return "walk_start"
	if state == _FighterStates.IDLE and _prev_state == _FighterStates.WALK and _loaded_clips.has("walk_stop"):
		return "walk_stop"
	if state == _FighterStates.RUN and _prev_state in [_FighterStates.WALK, _FighterStates.IDLE] and _loaded_clips.has("run_start"):
		return "run_start"
	if state == _FighterStates.IDLE and _prev_state == _FighterStates.RUN and _loaded_clips.has("run_stop"):
		return "run_stop"
	if state == _FighterStates.IDLE and _prev_state == _FighterStates.DASH and _loaded_clips.has("dash_stop"):
		return "dash_stop"
	if state == _FighterStates.TURNAROUND and _loaded_clips.has("turn"):
		return "turn"
	return clip


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
		_player.add_animation_library("", lib)
	var generated_source := str(info.get("source", "")) == _AssetResolver.STATUS_GENERATED_ANIM
	for clip_name in _loaded_clips.keys():
		_clip_provenance[clip_name] = _Provenance.GENERATED_PRODUCTION if generated_source else _Provenance.PROCEDURAL_FALLBACK
	if generated_source:
		_fill_missing_from_procedural(lib)


func _load_authored_proof() -> void:
	if _player == null or _fighter_id.is_empty():
		return
	var result: Dictionary = _Authored.load_into(_player, _skeleton, _fighter_id, "pipeline_proof", _skeleton_path)
	if bool(result.get("ok", false)):
		_loaded_clips["pipeline_proof"] = true
		_clip_provenance["pipeline_proof"] = _Provenance.AUTHORED_WIP


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
			anim.track_insert_key(track_idx, float(key.get("time_s", 0.0)), quat)
	var loc_tracks: Dictionary = data.get("location_tracks", {})
	for bone in loc_tracks.keys():
		if str(bone) == "Root":
			continue
		var keys: Array = loc_tracks[bone]
		if keys.is_empty():
			continue
		var glb_bone := _BoneMap.resolve_on_skeleton(_skeleton, str(bone))
		if glb_bone.is_empty():
			continue
		var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(track_idx, NodePath("%s:%s" % [_skeleton_path, glb_bone]))
		for key in keys:
			var loc: Array = key.get("location_m", [0.0, 0.0, 0.0])
			anim.track_insert_key(track_idx, float(key.get("time_s", 0.0)), Vector3(float(loc[0]), float(loc[1]), float(loc[2])))
	return anim


func _fill_missing_from_procedural(lib: AnimationLibrary) -> void:
	var fallback := "res://content/fighters/%s/animations/procedural" % _fighter_id
	var abs_root := ProjectSettings.globalize_path(fallback)
	if not DirAccess.dir_exists_absolute(abs_root):
		return
	var dir := DirAccess.open(abs_root)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".anim.json") and not dir.current_is_dir():
			var clip_name := file_name.replace(".anim.json", "")
			if not _loaded_clips.has(clip_name):
				var anim := _animation_from_json(abs_root.path_join(file_name))
				if anim:
					lib.add_animation(clip_name, anim)
					_loaded_clips[clip_name] = true
					_clip_provenance[clip_name] = _Provenance.PROCEDURAL_FALLBACK
		file_name = dir.get_next()
	dir.list_dir_end()


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
