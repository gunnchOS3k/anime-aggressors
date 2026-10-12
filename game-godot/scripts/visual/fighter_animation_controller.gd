extends Node
class_name FighterAnimationController

## Single canonical animation controller — observes Fighter state, does not author gameplay.

const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")

var _fighter
var _runtime_fighter: Node
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _skeleton_path: NodePath = NodePath()
var _loaded_clips: Dictionary = {}
var _fighter_id: String = ""
var _active_clip: String = ""
var _throw_dir: String = "forward"
var _move_synchronized := false
var presentation_frozen := false
var _body_variant := "male"
var _visual_facing := 1
var secondary_follow: Node
var _choreography_timing: Dictionary = {}
var _gait_half_stride: Dictionary = {}
var _locomotion_synchronized := false
var _last_world_position := Vector2.ZERO
var _world_position_valid := false
var _gait_phase := 0.0
var gait_period_px := 0.0
var _weight_transfer = preload("res://scripts/visual/locomotion_weight_transfer.gd").new()
var _previous_motion_facing := 1
var _previous_motion_speed := 0.0
var _motion_moving := false


func setup(fighter, model_root: Node3D) -> void:
	_fighter = fighter
	_fighter_id = ""
	if fighter != null:
		if "fighter_id" in fighter:
			_fighter_id = str(fighter.fighter_id)
		elif fighter.has_method("get"):
			_fighter_id = str(fighter.get("fighter_id"))
	if fighter != null and "body_variant" in fighter: _body_variant = str(fighter.body_variant)
	_weight_transfer.setup(_fighter_id)
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
			_load_combat_choreography(model_root)
			return
	_disable_embedded_players(model_root)
	_player = AnimationPlayer.new()
	_player.name = "CanonicalProceduralAnimationPlayer"
	model_root.add_child(_player)
	_load_procedural_clips(model_root)


func bind_runtime_fighter(fighter: Node) -> void:
	_runtime_fighter = fighter

func play_for_state(state: String, move: Dictionary = {}) -> void:
	if state not in [_FighterStates.IDLE,_FighterStates.WALK,_FighterStates.RUN,_FighterStates.DASH]:
		_weight_transfer.clear()
	_move_synchronized = state.begins_with("attack") or state.begins_with("special") or state.begins_with("aura_burst") or state.begins_with("throw")
	if _player == null or not is_instance_valid(_player):
		return
	if _skeleton == null or not is_instance_valid(_skeleton):
		return
	if move.has("throw_direction"):
		_throw_dir = str(move.get("throw_direction", "forward"))
	var action_state := _move_synchronized or state in ["grab_startup","grab_active"]
	var move_id := str(move.get("move_id", "")) if action_state else ""
	var resolved: Dictionary = _MoveResolver.resolve_clip(state, move_id, _loaded_clips)
	var clip := str(resolved.get("clip", ""))
	if state == _FighterStates.LAND and is_instance_valid(_runtime_fighter) and _runtime_fighter._fast_falling and _loaded_clips.has("land_hard"):
		clip = "land_hard"
	var directional_id := move_id+("_left" if _visual_facing==-1 else "")
	if action_state and _player.has_animation("combat_choreography/"+directional_id): clip=directional_id
	if clip.is_empty() or not _loaded_clips.has(clip):
		clip = _fallback_clip(state, move_id)
	var play_key := _animation_play_key(clip)
	if clip.is_empty() or play_key.is_empty() or not _player.has_animation(play_key):
		return
	var should_loop := clip in [
		"idle", "idle_primary", "idle_secondary", "run", "run_loop", "dash_loop", "walk", "walk_loop",
		"fall", "fast_fall", "shield", "shield_hold", "aura_charge", "aura_ready", "charged_idle",
		"ledge_hang", "crouch_hold",
	]
	var anim := _player.get_animation(play_key)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	if _player.current_animation != play_key and _player.current_animation != clip:
		_player.play(play_key, 0.0 if play_key.begins_with("combat_choreography/") else 0.08)
		if play_key.begins_with("combat_choreography/"):
			# State callbacks must show the authored first pose in this frame,
			# including a real victim reaction before hitstop freezes playback.
			_player.seek(0.0,true)
			_locomotion_synchronized = false
	elif not should_loop and not _player.is_playing():
		_player.play(play_key, 0.0 if play_key.begins_with("combat_choreography/") else 0.08)
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
	if _player != null and _player.has_animation("combat_choreography/"+clip): return "combat_choreography/"+clip
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
			if key.has("rotation_quat"):
				var q: Array = key.rotation_quat
				quat = Quaternion(float(q[0]),float(q[1]),float(q[2]),float(q[3])).normalized()
			if bool(data.get("relative_to_rest",false)):
				quat = _skeleton.get_bone_rest(_skeleton.find_bone(glb_bone)).basis.get_rotation_quaternion() * quat
			anim.track_insert_key(track_idx, float(key.get("time_s", 0.0)), quat)

		if keys[0].has("position_m"):
			var position_idx := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(position_idx, NodePath("%s:%s" % [_skeleton_path, glb_bone]))
			for key in keys:
				var v: Array = key.position_m
				anim.track_insert_key(position_idx,float(key.time_s),Vector3(float(v[0]),float(v[1]),float(v[2])))
	# Older clips must restore the pelvis when interrupting a translated authored pose.
	if tracks.has("Hips") and not tracks.Hips[0].has("position_m"):
		var hips := _BoneMap.resolve_on_skeleton(_skeleton,"Hips")
		var index := _skeleton.find_bone(hips)
		var reset := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(reset,NodePath("%s:%s" % [_skeleton_path,hips]))
		anim.track_insert_key(reset,0.0,_skeleton.get_bone_rest(index).origin)
		anim.track_insert_key(reset,anim.length,_skeleton.get_bone_rest(index).origin)
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
	if _synchronize_landing(): return
	if _player != null and is_instance_valid(_player) and _player.has_animation_library("authored_studies") and not _move_synchronized and not _locomotion_synchronized and not presentation_frozen:
		_player.advance(delta)

func _synchronize_landing() -> bool:
	if not is_instance_valid(_runtime_fighter) or _player == null or not is_instance_valid(_player): return false
	if _runtime_fighter.state_machine.current_state != _FighterStates.LAND or not _player.current_animation.begins_with("combat_choreography/land_"): return false
	if not presentation_frozen:
		# Recovery remains gameplay-owned. Complete absorption and stabilization
		# within its resolved duration, including fast-fall/aerial overrides.
		var phase := clampf(_runtime_fighter.state_machine.state_time / maxf(.001,_runtime_fighter.state_machine.landing_lag),0,1)
		_player.seek(phase * _player.current_animation_length,true)
	return true

func synchronize_move(frame: int,move: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player): return
	var directional_id := str(move.get("move_id",""))+("_left" if _visual_facing==-1 else "")
	var key := "combat_choreography/"+directional_id
	if not _player.has_animation(key): key = "authored_studies/"+str(move.get("move_id",""))
	if not _player.has_animation(key): return
	_move_synchronized = true
	if _player.current_animation != key: _player.play(key,0)
	var visual_frame := float(frame)
	var mid := directional_id
	if key.begins_with("combat_choreography/") and _choreography_timing.has(mid):
		var clip: Dictionary = _choreography_timing[mid]
		var actual_start := maxi(1,int(move.get("startup_frames",clip.startup_frames)))
		var actual_active := maxi(1,int(move.get("active_frames",clip.active_frames)))
		var actual_recovery := maxi(1,int(move.get("recovery_frames",clip.recovery_frames)))
		if frame < actual_start:
			visual_frame = float(frame)*float(maxi(0,int(clip.startup_frames)-1))/float(maxi(1,actual_start-1))
		elif frame <= actual_start+actual_active:
			# Live overlap may confirm at active-phase entry (phase frame zero).
			# Sustain contact through the first active callback without changing combat.
			visual_frame = float(clip.startup_frames)+1.0+float(maxi(0,frame-actual_start-1))*float(maxi(0,int(clip.active_frames)-1))/float(maxi(1,actual_active-1))
		else:
			visual_frame = float(clip.startup_frames+clip.active_frames)+float(frame-actual_start-actual_active)*float(clip.recovery_frames)/float(actual_recovery)
	_player.seek(visual_frame/60.0,true)

func _load_combat_choreography(model_root: Node3D) -> void:
	var path := "res://data/animation/combat_choreography/%s_%s.json" % [_fighter_id,_body_variant]
	if not FileAccess.file_exists(path): return
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var library := AnimationLibrary.new()
	for clip in doc.clips:
		if doc.clips[clip].has("startup_frames"): _choreography_timing[clip]=doc.clips[clip]
		if float(doc.clips[clip].get("gait_half_stride_m",0))>0: _gait_half_stride[clip]=float(doc.clips[clip].gait_half_stride_m)
		var anim := _animation_from_data(doc.clips[clip])
		anim.loop_mode = Animation.LOOP_LINEAR if doc.clips[clip].get("loop",false) else Animation.LOOP_NONE
		library.add_animation(clip,anim); _loaded_clips[clip]=true
	for mid in _MoveResolver.move_id_to_clip_table():
		var alias: String = str(_MoveResolver.move_id_to_clip_table()[mid])
		if library.has_animation(mid) and not library.has_animation(alias): library.add_animation(alias,library.get_animation(mid)); _loaded_clips[alias]=true
	for alias in {"hurt_light_front":"hurt_light","hurt_light_back":"hurt_light","launch_horizontal":"launched","launch_vertical":"launched"}:
		var source: String = str({"hurt_light_front":"hurt_light","hurt_light_back":"hurt_light","launch_horizontal":"launched","launch_vertical":"launched"}[alias])
		if not library.has_animation(alias): library.add_animation(alias,library.get_animation(source)); _loaded_clips[alias]=true
	if library.has_animation("neutral_special_projectile"):
		for alias in ["projectile_tap","projectile_medium","projectile_full"]: library.add_animation(alias,library.get_animation("neutral_special_projectile")); _loaded_clips[alias]=true
	_player.add_animation_library("combat_choreography",library)
	secondary_follow=preload("res://scripts/visual/combat_secondary_follow.gd").new()
	add_child(secondary_follow); secondary_follow.setup(model_root,self)

func get_locomotion_transition_evidence() -> Dictionary:
	return _weight_transfer.evidence()

func synchronize_locomotion(world_position: Vector2, model, grounded: bool) -> void:
	var displacement := 0.0
	if _world_position_valid: displacement = absf(world_position.x-_last_world_position.x)
	_last_world_position = world_position; _world_position_valid = true
	_locomotion_synchronized = false
	if _player == null or model._camera == null or _skeleton == null: return
	if _synchronize_landing():
		_locomotion_synchronized = true
		return
	var state := str(_runtime_fighter.state_machine.current_state) if is_instance_valid(_runtime_fighter) else ""
	var neutral_motion := grounded and state in [_FighterStates.IDLE,_FighterStates.WALK,_FighterStates.RUN,_FighterStates.DASH] and not _move_synchronized
	var delta := get_physics_process_delta_time()
	var speed := displacement/maxf(delta,.001)
	if not neutral_motion:
		_weight_transfer.clear(); _motion_moving=false; _previous_motion_speed=0;_previous_motion_facing=_visual_facing
		return
	if presentation_frozen:return
	# Reversal braking is still requested locomotion. Do not replace its
	# authored pivot with a stop when velocity crosses zero under held input.
	var commanded := absf(_runtime_fighter._read_axis())>.001
	if displacement>128:
		_gait_phase=0;_weight_transfer.clear();_motion_moving=false
	elif commanded and _visual_facing!=_previous_motion_facing and _motion_moving:
		_weight_transfer.begin("pivot")
	elif commanded and not _motion_moving:
		_weight_transfer.begin("start")
	elif _motion_moving and not commanded:
		_weight_transfer.begin("stop")
	_motion_moving=commanded;_previous_motion_speed=speed;_previous_motion_facing=_visual_facing
	var clip := str(_player.current_animation).get_slice("/",1)
	if _gait_half_stride.has(clip):
		_locomotion_synchronized = true
		# Gameplay root displacement remains authoritative; preserve distance gait.
		var a: Vector2 = model._camera.unproject_position(_skeleton.to_global(Vector3.ZERO))
		var b: Vector2 = model._camera.unproject_position(_skeleton.to_global(Vector3(0,0,float(_gait_half_stride[clip]))))
		gait_period_px = 4*absf(b.x-a.x)*absf(model._display.scale.x)
		if gait_period_px>.01:
			_gait_phase=fposmod(_gait_phase+displacement/gait_period_px,1.0)
			_player.seek(_gait_phase*_player.current_animation_length,true)
	elif not _weight_transfer.kind.is_empty():
		# Reset the base pose each physics tick; never compound additive transforms.
		_locomotion_synchronized=true
		_player.advance(delta)
		_player.seek(_player.current_animation_position,true)
	if not _weight_transfer.kind.is_empty():_weight_transfer.apply(_skeleton,delta,_visual_facing)

func set_visual_facing(direction: int) -> void:
	_visual_facing = 1 if direction>=0 else -1
