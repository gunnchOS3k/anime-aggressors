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
var _authored_transition = preload("res://scripts/visual/authored_locomotion_transition.gd").new()
var _previous_motion_strength:=0.0
var _previous_gait_clip:=""
var _previous_motion_facing := 1
var _previous_motion_speed := 0.0
var _motion_moving := false
var _reaction_clip := ""
var _reaction_age := 0.0
var _reaction_fresh := false
var _form_sources: Dictionary = {}
var _form_sequence := ""
var _form_progress := 0.0
var _form_overlay_status := "missing"
var _grab_acting_sources: Dictionary = {}
var _grab_acting_report: Dictionary = {}
var _grab_overlay_status := "missing"
var _grab_escape_clip := ""
var _grab_escape_age := 0.0
var _grab_escape_buttons: Dictionary = {}
var _grab_recovery_active := false
var _throw_reaction_pending := false
var _throw_landing_active := false
const GRAB_ACTING_CLIPS := ["grab", "grab_whiff", "grab_hold_attacker", "grab_hold_victim", "grab_escape", "throw_forward", "throw_back", "throw_up", "throw_down", "throw_reaction_forward", "throw_reaction_back", "throw_reaction_up", "throw_reaction_down", "throw_landing", "grab_recovery", "grab_interrupted"]
var _neutral_return_pose:Array=[]
var _neutral_return_age:=0.0
const NEUTRAL_RETURN_SECONDS:=.075
var _grounded_return = preload("res://scripts/visual/grounded_recovery_blend.gd").new()
var _attack_support_exchange = preload("res://scripts/visual/grounded_recovery_blend.gd").new()
var _support_solver = preload("res://scripts/visual/locomotion_weight_transfer.gd").new()
var support_knee_corrections := 0
var support_knee_anchor_error_m := 0.0
var _strike_posture = preload("res://scripts/visual/grounded_strike_posture.gd").new()
const _PrivateArt = preload("res://scripts/visual/private_battle_art.gd")
var _private_moves: Dictionary = {}
var _private_clip_failures: Array = []

func uses_original_source_clip() -> bool:
	return is_instance_valid(_player) and _private_moves.has(str(_player.current_animation).trim_prefix("combat_choreography/"))

func original_art_report() -> Dictionary:
	return {"moves":_private_moves.duplicate(true), "failures":_private_clip_failures.duplicate(), "active":uses_original_source_clip(), "human_approved":false}

func _install_private_moves(model: Node3D) -> void:
	if not model.has_meta("private_original_art"): return
	var row: Dictionary = model.get_meta("private_original_art")
	var library := _player.get_animation_library("combat_choreography")
	for move_id in row.get("moves", {}):
		var definition: Dictionary = row.moves[move_id]
		var clip: Animation = _PrivateArt.load_clip(definition, _player, _skeleton)
		if clip == null:
			_private_clip_failures.append(str(move_id)+":bind_or_import_rejected")
			push_error("Private original clip rejected: "+str(move_id))
			continue
		for suffix in ["", "_left"]:
			var key := str(move_id)+str(suffix)
			if library.has_animation(key): library.remove_animation(key)
			library.add_animation(key, clip)
			_loaded_clips[key] = true
			_private_moves[key] = {"sha256":definition.sha256, "source_clip":definition.clip, "contact":definition.contact, "active_end":definition.active_end, "last":definition.last}

func _correct_support_knees() -> void:
	if uses_original_source_clip(): return # Saved whole-body acting owns its original knees/feet.
	if not is_instance_valid(_runtime_fighter) or not _runtime_fighter.is_on_floor() or not is_instance_valid(_skeleton): return
	# Existing authored tracks used a -Z knee pole while these rigs face +Z.
	# Reflect only the backward bend component, retaining authored lateral
	# turnout, hip/ankle anchors, foot orientation and both segment lengths.
	_skeleton.force_update_all_bone_transforms()
	for side in ["L","R"]:
		var hip := _skeleton.find_bone("UpperLeg_"+side)
		var knee := _skeleton.find_bone("LowerLeg_"+side)
		var foot := _skeleton.find_bone("Foot_"+side)
		if mini(hip,mini(knee,foot))<0: continue
		var a := _skeleton.get_bone_global_pose(hip).origin
		var b := _skeleton.get_bone_global_pose(knee).origin
		var c := _skeleton.get_bone_global_pose(foot).origin
		var axis := (c-a).normalized()
		var forward := (Vector3.BACK-axis*Vector3.BACK.dot(axis)).normalized()
		var bend := b-a-axis*(b-a).dot(axis)
		if bend.dot(forward)>=-.000001: continue
		var corrected := bend-2.0*bend.dot(forward)*forward
		support_knee_anchor_error_m=maxf(support_knee_anchor_error_m,_support_solver.hold_foot(_skeleton,side,c,corrected))
		support_knee_corrections+=1

func _begin_neutral_return(state: String) -> void:
	_neutral_return_pose.clear();_neutral_return_age=0.0
	_grounded_return.clear()
	# Settle only stationary grounded neutral. Distance gait, landing and a new
	# command retain their own foot mechanics without any input delay.
	if state == _FighterStates.IDLE and is_instance_valid(_runtime_fighter) and _runtime_fighter.is_on_floor() and absf(_runtime_fighter._read_axis()) < .001:
		_grounded_return.begin(_skeleton,_gait_phase,0,_active_clip in ["walk_loop","run_loop","dash_loop"])
	for name in ["Spine","Chest","Neck","Head","UpperArm_L","LowerArm_L","Hand_L","UpperArm_R","LowerArm_R","Hand_R"]:
		var index:=_skeleton.find_bone(name)
		if index>=0:_neutral_return_pose.append({"bone":index,"rotation":_skeleton.get_bone_pose_rotation(index)})

func _blend_neutral_return(delta:float) -> void:
	if presentation_frozen or not is_instance_valid(_skeleton):return
	if _grounded_return.active:
		if not is_instance_valid(_runtime_fighter) or not _runtime_fighter.is_on_floor() or absf(_runtime_fighter._read_axis()) > .001:
			_grounded_return.clear()
		else:
			_grounded_return.apply(_skeleton, delta)
	if _neutral_return_pose.is_empty():return
	_neutral_return_age+=delta
	var weight:=smoothstep(0.0,NEUTRAL_RETURN_SECONDS,_neutral_return_age)
	for pose in _neutral_return_pose:
		var target:=_skeleton.get_bone_pose_rotation(int(pose.bone))
		var initial:Quaternion=pose.rotation
		_skeleton.set_bone_pose_rotation(int(pose.bone),initial.slerp(target,weight))
	if _neutral_return_age>=NEUTRAL_RETURN_SECONDS:_neutral_return_pose.clear()

func begin_hit_reaction(reaction: Dictionary) -> void:
	_clear_grab_escape("body_hit")
	_grab_recovery_active = false
	_reaction_clip=str(reaction.get("performance_clip","reaction_light"))
	_throw_reaction_pending = false
	if str(reaction.get("move_id", "")).begins_with("throw_"):
		var launch: Vector2 = reaction.get("incoming", Vector2.ZERO)
		var direction := "up" if launch.y < 0 else "down"
		if absf(launch.x) >= absf(launch.y):direction = "forward" if launch.x * _visual_facing >= 0 else "back"
		var authored := _grab_acting_clip("throw_reaction_"+direction)
		if not authored.is_empty():_reaction_clip = authored;_throw_reaction_pending = true
	_reaction_age=0.0
	_reaction_fresh=true
	# receive_hit has already assigned real hitstop. Freeze now, before this
	# frame's render callback; waiting for the next combat tick slipped a frame.
	if is_instance_valid(_runtime_fighter):presentation_frozen=_runtime_fighter._hitstop>0.0


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
	_grounded_return.configure(_fighter_id)
	_attack_support_exchange.configure(_fighter_id)
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
			_install_private_moves(model_root)
			return
	_disable_embedded_players(model_root)
	_player = AnimationPlayer.new()
	_player.name = "CanonicalProceduralAnimationPlayer"
	model_root.add_child(_player)
	_load_procedural_clips(model_root)


func bind_runtime_fighter(fighter: Node) -> void:
	_runtime_fighter = fighter
	_load_form_acting_overlay()


func _reciprocal_grab_role() -> String:
	if not is_instance_valid(_runtime_fighter):return ""
	var target = _runtime_fighter.grabbed_target
	var owner = _runtime_fighter.grabbed_by
	if is_instance_valid(target) and target.grabbed_by == _runtime_fighter:return "attacker"
	if is_instance_valid(owner) and owner.grabbed_target == _runtime_fighter:return "victim"
	return ""


func _grab_acting_clip(base: String) -> String:
	var name := base + ("_left" if _visual_facing == -1 else "")
	if _grab_acting_sources.has(name) and is_instance_valid(_player) and _player.has_animation("combat_choreography/"+name):return name
	return ""


func get_grab_acting_report() -> Dictionary:
	var result := _grab_acting_report.duplicate(true)
	result["escape_active"] = not _grab_escape_clip.is_empty()
	result["overlay_status"] = _grab_overlay_status
	result["source"] = _grab_acting_sources.get(str(result.get("selected", "")), {}).duplicate(true)
	result["human_approved"] = false
	result["throw_reaction_clip"] = _reaction_clip if _throw_reaction_pending else ""
	result["throw_landing_active"] = _throw_landing_active
	return result


func _grab_escape_allowed(state: String) -> bool:
	if not is_instance_valid(_runtime_fighter) or state not in [_FighterStates.IDLE, _FighterStates.FALL]:return false
	if _runtime_fighter._transform_match_closed or not _reciprocal_grab_role().is_empty() or absf(_runtime_fighter._read_axis()) > .001:return false
	for suffix in ["attack", "special", "jump", "grab", "shield", "dodge", "taunt"]:
		var held := Input.is_action_pressed("p%d_%s" % [_runtime_fighter.slot, suffix]) or TouchInputManager.is_touch_pressed(_runtime_fighter.slot, suffix)
		var was := bool(_grab_escape_buttons.get(suffix, false))
		_grab_escape_buttons[suffix] = held
		if held and not was:return false
	return true


func _clear_grab_escape(reason: String) -> void:
	_grab_escape_clip = ""
	_grab_escape_age = 0.0
	_grab_escape_buttons.clear()
	if _grab_acting_report.get("role", "") == "escape":
		_grab_acting_report["active"] = false
		_grab_acting_report["ended_by"] = reason


func cancel_grab_acting(reason: String) -> void:
	var was_escape := not _grab_escape_clip.is_empty()
	_clear_grab_escape(reason)
	_throw_reaction_pending = false;_throw_landing_active = false
	_grab_recovery_active = false
	_grab_acting_report["active"] = false
	if was_escape and is_instance_valid(_runtime_fighter):play_for_state(str(_runtime_fighter.state_machine.current_state))


func begin_grab_escape() -> void:
	_clear_grab_escape("replaced")
	var clip := _grab_acting_clip("grab_escape")
	_grab_acting_report = {"role":"escape", "requested":"grab_escape"+("_left" if _visual_facing == -1 else ""), "selected":clip, "status":"fallback" if clip.is_empty() else "fixture_only" if bool(_grab_acting_sources[clip].get("fixture_only", false)) else "authored", "active":false}
	if clip.is_empty() or not is_instance_valid(_runtime_fighter):return
	# Snapshot the final mash press without consuming its input edge. Only a new
	# action interrupts the presentation; the existing escape impulse is retained.
	for suffix in ["attack", "special", "jump", "grab", "shield", "dodge", "taunt"]:
		_grab_escape_buttons[suffix] = Input.is_action_pressed("p%d_%s" % [_runtime_fighter.slot, suffix]) or TouchInputManager.is_touch_pressed(_runtime_fighter.slot, suffix)
	var state := str(_runtime_fighter.state_machine.current_state)
	if not _grab_escape_allowed(state):_clear_grab_escape("new_action_or_movement");return
	_grab_escape_clip = clip
	_grab_acting_report["active"] = true
	play_for_state(state)


func play_for_state(state: String, move: Dictionary = {}, standalone_preview := false) -> void:
	if not _form_sequence.is_empty():
		if state == _FighterStates.AURA_BURST_STARTUP:return
		end_form_sequence()
	# The unchanged mash-release rule uses GRAB_WHIFF for holder recovery.
	# A released grip needs its authored support exchange, not a fresh reach.
	_grab_recovery_active = state == _FighterStates.GRAB_WHIFF and (_grab_recovery_active or (bool(_grab_acting_report.get("active", false)) and _grab_acting_report.get("role", "") == "attacker"))
	var neutral_state:=not standalone_preview and state in [_FighterStates.IDLE,_FighterStates.WALK,_FighterStates.RUN,_FighterStates.DASH,_FighterStates.FALL,_FighterStates.FAST_FALL]
	if standalone_preview:
		# Watch/move-list clips have no MoveRunner. Their saved body actions use
		# the presentation clock, without inheriting an old gameplay handoff.
		_locomotion_synchronized = false
		_authored_transition.clear(); _neutral_return_pose.clear(); _grounded_return.clear()
		_attack_support_exchange.clear(); _weight_transfer.clear()
	if not state.begins_with("attack"):_attack_support_exchange.clear()
	if not neutral_state:_neutral_return_pose.clear()
	if state != _FighterStates.IDLE: _grounded_return.clear()
	if state not in [_FighterStates.IDLE,_FighterStates.WALK,_FighterStates.RUN,_FighterStates.DASH]:
		_weight_transfer.clear()
	_move_synchronized = not standalone_preview and (state.begins_with("attack") or state.begins_with("special") or state.begins_with("aura_burst") or state.begins_with("throw"))
	if not _move_synchronized: _strike_posture.last.clear()
	if _player == null or not is_instance_valid(_player):
		return
	if _skeleton == null or not is_instance_valid(_skeleton):
		return
	if move.has("throw_direction"):
		_throw_dir = str(move.get("throw_direction", "forward"))
	var action_state := standalone_preview or _move_synchronized or state in ["grab_startup","grab_active"]
	var move_id := str(move.get("move_id", "")) if action_state else ""
	var resolved: Dictionary = _MoveResolver.resolve_clip(state, move_id, _loaded_clips)
	var clip := str(resolved.get("clip", ""))
	if not standalone_preview and state == _FighterStates.IDLE and is_instance_valid(_runtime_fighter):
		var form_idle := _form_clip(str(_runtime_fighter.get_current_form_id()), "idle_clip")
		if not form_idle.is_empty():clip = form_idle
	var grab_presentation := false
	if not _grab_escape_clip.is_empty():
		if _grab_escape_allowed(state):clip = _grab_escape_clip;grab_presentation = true
		else:_clear_grab_escape("new_action_or_movement")
	if state == _FighterStates.GRAB_HOLD:
		var role := _reciprocal_grab_role()
		var requested := "grab_hold_"+role+("_left" if _visual_facing == -1 else "")
		var authored := _grab_acting_clip("grab_hold_"+role) if not role.is_empty() else ""
		if not authored.is_empty():clip = authored
		grab_presentation = true
		_grab_acting_report = {"role":role, "metadata_role":str(move.get("grab_role", "")), "requested":requested, "selected":clip, "status":"fallback" if authored.is_empty() else "fixture_only" if bool(_grab_acting_sources[authored].get("fixture_only", false)) else "authored", "active":true}
	elif _grab_acting_report.get("role", "") != "escape":_grab_acting_report["active"] = false
	if _grab_recovery_active:
		var recovery := _grab_acting_clip("grab_recovery")
		if not recovery.is_empty():
			clip = recovery;grab_presentation = true
			_grab_acting_report = {"role":"holder_recovery", "requested":recovery, "selected":recovery, "status":"fixture_only" if bool(_grab_acting_sources[recovery].get("fixture_only", false)) else "authored", "active":true}
	if grab_presentation:
		_neutral_return_pose.clear();_grounded_return.clear();_authored_transition.clear();_weight_transfer.clear()
		_locomotion_synchronized = false
	var reacting:=state in [_FighterStates.HURT_LIGHT,_FighterStates.HURT_HEAVY,_FighterStates.HITSTUN,_FighterStates.LAUNCHED,_FighterStates.TUMBLE]
	if reacting and not _reaction_clip.is_empty() and _player.has_animation("combat_choreography/"+_reaction_clip):
		var reaction_length:=_player.get_animation("combat_choreography/"+_reaction_clip).length
		if _reaction_age<reaction_length:clip=_reaction_clip
	elif not reacting:
		_reaction_clip=""
		_reaction_fresh=false
	if state == _FighterStates.LAND and is_instance_valid(_runtime_fighter) and _runtime_fighter._fast_falling and _loaded_clips.has("land_hard"):
		clip = "land_hard"
	_throw_landing_active = false
	if state == _FighterStates.LAND and _throw_reaction_pending:
		var landing := _grab_acting_clip("throw_landing")
		if not landing.is_empty():clip = landing;_throw_landing_active = true
	elif not reacting and state not in [_FighterStates.FALL, _FighterStates.FAST_FALL]:_throw_reaction_pending = false
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
		"ledge_hang", "crouch_hold", "grab_hold", "grab_hold_attacker", "grab_hold_attacker_left", "grab_hold_victim", "grab_hold_victim_left",
	]
	should_loop = should_loop or clip.begins_with("form_idle_")
	var anim := _player.get_animation(play_key)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	if (_player.current_animation != play_key and _player.current_animation != clip) or (reacting and _reaction_fresh):
		# Authored per-fighter sole exchange from the actual last gait pose.
		# Lower-body only, and fully retired BEFORE the authoritative active pose.
		if not standalone_preview and action_state and _motion_moving and move_id in ["jab_1","forward_tilt","dash_attack","heavy_attack"] and is_instance_valid(_runtime_fighter) and _runtime_fighter.is_on_floor():
			_attack_support_exchange.begin(_skeleton,_gait_phase,maxi(1,int(move.get("startup_frames",1))-1),true)
		if not standalone_preview and not grab_presentation and _authored_transition.enabled():
			if action_state and _motion_moving and move_id in ["jab_1","forward_tilt","dash_attack","heavy_attack"]:
				_authored_transition.begin("move_heavy" if move_id=="heavy_attack" else "move_light",_visual_facing)
			elif state==_FighterStates.IDLE and not _active_clip.is_empty() and _move_synchronized==false and not _motion_moving:
				_authored_transition.begin("guard",_visual_facing)
			elif not neutral_state and not action_state:
				_authored_transition.clear()
		# A finished non-looping clip clears current_animation but leaves its
		# final skeleton pose visible. That pose still needs a recovery blend.
		if not grab_presentation and neutral_state and not _active_clip.is_empty():_begin_neutral_return(state)
		_player.play(play_key, 0.0 if play_key.begins_with("combat_choreography/") else 0.08)
		if play_key.begins_with("combat_choreography/"):
			# State callbacks must show the authored first pose in this frame,
			# including a real victim reaction before hitstop freezes playback.
			_player.seek(0.0,true)
			_blend_neutral_return(0.0)
			_correct_support_knees()
			_locomotion_synchronized = false
		_reaction_fresh=false
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
	if _player != null and _player.has_animation("form_acting_8c/"+clip):return "form_acting_8c/"+clip
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
	if not _form_sequence.is_empty():return # Owned progress is sampled by the existing transform pipeline.
	if not presentation_frozen:_reaction_age+=delta
	if not _grab_escape_clip.is_empty():
		var state := str(_runtime_fighter.state_machine.current_state) if is_instance_valid(_runtime_fighter) else ""
		if not presentation_frozen:_grab_escape_age+=delta
		var key := "combat_choreography/"+_grab_escape_clip
		if not _grab_escape_allowed(state) or not is_instance_valid(_player) or not _player.has_animation(key) or _grab_escape_age >= _player.get_animation(key).length:
			_clear_grab_escape("completed_or_interrupted")
			if not state.is_empty():play_for_state(state)
	if _synchronize_landing(): return
	if _player != null and is_instance_valid(_player) and _player.has_animation_library("authored_studies") and not _move_synchronized and not _locomotion_synchronized and not presentation_frozen:
		_player.advance(delta)
	_blend_neutral_return(delta)
	_correct_support_knees()

func _synchronize_landing() -> bool:
	if not is_instance_valid(_runtime_fighter) or _player == null or not is_instance_valid(_player): return false
	if _runtime_fighter.state_machine.current_state != _FighterStates.LAND or (not _player.current_animation.begins_with("combat_choreography/land_") and not _throw_landing_active): return false
	if not presentation_frozen:
		# Recovery remains gameplay-owned. Complete absorption and stabilization
		# within its resolved duration, including fast-fall/aerial overrides.
		var phase := clampf(_runtime_fighter.state_machine.state_time / maxf(.001,_runtime_fighter.state_machine.landing_lag),0,1)
		_player.seek(phase * _player.current_animation_length,true)
		_correct_support_knees()
	return true

func synchronize_move(frame: int,move: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player): return
	# The successful grab's runner may finish its existing recovery, while hold
	# presentation belongs to the reciprocal pair rather than that old action.
	if is_instance_valid(_runtime_fighter) and _runtime_fighter.state_machine.current_state == _FighterStates.GRAB_HOLD and not _reciprocal_grab_role().is_empty():return
	if is_instance_valid(_runtime_fighter) and _runtime_fighter.state_machine.current_state == _FighterStates.GRAB_WHIFF and str(move.get("move_id", "")) == "grab":return
	var directional_id := str(move.get("move_id",""))+("_left" if _visual_facing==-1 else "")
	var key := "combat_choreography/"+directional_id
	if not _player.has_animation(key): key = "authored_studies/"+str(move.get("move_id",""))
	if not _player.has_animation(key): return
	_move_synchronized = true
	if _player.current_animation != key: _player.play(key,0)
	if _private_moves.has(directional_id):
		# Exactly one saved full-body pose; no older arm/posture/support overlays.
		_attack_support_exchange.clear(); _authored_transition.clear()
		_neutral_return_pose.clear(); _grounded_return.clear()
		_player.seek(_PrivateArt.source_frame(frame, move, _private_moves[directional_id])/60.0, true)
		return
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
	var support_end:=maxi(1,int(move.get("startup_frames",1))-1)
	if _attack_support_exchange.active:
		if frame>=support_end:_attack_support_exchange.clear()
		else:
			# Use the resolved move clock once, not render/animation callback count.
			_attack_support_exchange.elapsed=0
			_attack_support_exchange.apply(_skeleton,float(frame)/60.0)
	_correct_support_knees()
	# Directed clips own their complete keyed body chain. Applying the older
	# projection-preserving posture pass would overwrite that authored acting.
	if _choreography_timing.get(mid,{}).get("posture_authority","") == "source_clip":
		_strike_posture.last = {"admitted":false,"reason":"directed_source_clip"}
	else:
		_strike_posture.apply(_runtime_fighter,_skeleton,frame,move)
	# Movement anticipation may blend only inside existing startup. Its source
	# duration is fitted before activation; the authored contact is unchanged.
	if _authored_transition.kind in ["move_light","move_heavy"]:
		var startup:=maxi(1,int(move.get("startup_frames",1)))
		if frame>=startup-1:_authored_transition.clear()
		else:
			var source_name:String="transition_"+str(_authored_transition.kind)+("_left" if _visual_facing==-1 else "")
			var duration:float=float(_authored_transition.clips[source_name].duration_frames)/60.0
			_authored_transition.sample(_skeleton,float(frame)/maxi(1,startup-1)*duration,_visual_facing)

func _load_combat_choreography(model_root: Node3D) -> void:
	var path := "res://data/animation/combat_choreography/%s_%s.json" % [_fighter_id,_body_variant]
	if not FileAccess.file_exists(path): return
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var library := AnimationLibrary.new()
	for clip in doc.clips:
		if doc.clips[clip].has("startup_frames"): _choreography_timing[clip]=_timing_metadata(doc.clips[clip])
		if float(doc.clips[clip].get("gait_half_stride_m",0))>0: _gait_half_stride[clip]=float(doc.clips[clip].gait_half_stride_m)
		var anim := _animation_from_data(doc.clips[clip])
		anim.loop_mode = Animation.LOOP_LINEAR if doc.clips[clip].get("loop",false) else Animation.LOOP_NONE
		library.add_animation(clip,anim); _loaded_clips[clip]=true
	# Small original performance amendments preserve the previous blocking data
	# and all gameplay frame authority. Both presentations use their actual rig.
	var performance_path:="res://data/animation/combat_performance/%s_%s.json" % [_fighter_id,_body_variant]
	if FileAccess.file_exists(performance_path):
		var performance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(performance_path))
		for clip in performance.clips:
			var authored: Dictionary=performance.clips[clip]
			_authored_transition.register(str(clip),authored)
			if authored.has("startup_frames"):_choreography_timing[clip]=_timing_metadata(authored)
			if library.has_animation(clip):library.remove_animation(clip)
			var animation := _animation_from_data(authored)
			animation.loop_mode = Animation.LOOP_LINEAR if authored.get("loop",false) else Animation.LOOP_NONE
			library.add_animation(clip,animation);_loaded_clips[clip]=true
	_load_grab_acting_overlay(library)
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


func _load_grab_acting_overlay(library: AnimationLibrary) -> void:
	_load_saved_grab_overlay(library,"grab_acting_8b","original_grab_acting_8b.v1","ANI08B_WIP_")
	var review:=get_node_or_null("/root/GameState")
	if review!=null and review.get_meta("source_paired_8d2",false):
		_load_saved_grab_overlay(library,"paired_grip_8d2","paired_mesh_grab_acting_8d2.v1","ANI08D2_PAIRED_")


func _load_saved_grab_overlay(library: AnimationLibrary, lane: String, schema: String, prefix: String) -> void:
	var path := "res://data/animation/%s/%s_%s.json" % [lane,_fighter_id,_body_variant]
	if not FileAccess.file_exists(path):
		if lane=="paired_grip_8d2":push_error("Requested paired source acting missing: "+path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_grab_overlay_status = "unverified"
	if not parsed is Dictionary:return
	var doc: Dictionary = parsed
	if doc.get("source_actions_saved", false) != true or doc.get("source_runtime_verified", false) != true:return
	if str(doc.get("schema",""))!=schema:return
	if str(doc.get("source_base_blend_sha256","")).length()!=64 or str(doc.get("source_saved_blend_sha256","")).length()!=64:return
	if str(doc.get("fighter_id", _fighter_id)) != _fighter_id or str(doc.get("body_variant", _body_variant)) != _body_variant:return
	if lane=="paired_grip_8d2":
		var candidate: Dictionary=preload("res://scripts/visual/source_controls_8d.gd").candidate_document(_fighter_id,_body_variant,"hands_8d2")
		if candidate.is_empty() or candidate.get("source_sha256","")!=doc.get("source_saved_blend_sha256",""):
			push_error("Paired source and hand mesh hashes differ: "+_fighter_id+"/"+_body_variant)
			return
	_grab_overlay_status = "verified_source_export"
	for name in doc.get("clips", {}):
		var base := str(name).trim_suffix("_left")
		if base not in GRAB_ACTING_CLIPS:continue
		var clip: Dictionary = doc.clips[name]
		if clip.get("bone_tracks", {}).is_empty():continue
		if not str(clip.get("source_action","")).begins_with(prefix) or str(clip.get("source_blend","")).is_empty():continue
		var animation := _animation_from_data(clip)
		if clip.has("startup_frames"):_choreography_timing[name] = _timing_metadata(clip)
		if library.has_animation(name):library.remove_animation(name)
		library.add_animation(name, animation);_loaded_clips[name]=true
		_grab_acting_sources[name] = {"source_action":clip.get("source_action", ""), "source_blend":clip.get("source_blend", doc.get("source_blend", "")), "fixture_only":bool(doc.get("fixture_only", false))}

func _timing_metadata(clip: Dictionary) -> Dictionary:
	# Animation tracks already own converted keys. Timing/limb observers need
	# metadata only; retaining the parsed pose arrays duplicates the whole bake.
	var metadata:=clip.duplicate(false)
	metadata.erase("bone_tracks")
	return metadata

func get_locomotion_transition_evidence() -> Dictionary:
	if _authored_transition.enabled():return _authored_transition.evidence()
	return _weight_transfer.evidence()

func synchronize_locomotion(world_position: Vector2, model, grounded: bool) -> void:
	var displacement := 0.0
	var signed_displacement:=0.0
	if _world_position_valid:
		signed_displacement=world_position.x-_last_world_position.x
		displacement=absf(signed_displacement)
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
		if not (_move_synchronized and _authored_transition.kind in ["move_light","move_heavy"]):_authored_transition.clear()
		_weight_transfer.clear(); _motion_moving=false; _previous_motion_speed=0;_previous_motion_facing=_visual_facing
		_previous_motion_strength=0
		# These light routes return to the authored neutral guard. Their next
		# walk cannot inherit the pre-attack run stride. Heavy/airborne travel
		# needs separate phase-specific source handoffs; retain that behavior.
		if is_instance_valid(_runtime_fighter) and str(_runtime_fighter._current_move.get("move_id","")) in ["jab_1","forward_tilt","dash_attack"]:
			_previous_gait_clip=""
		return
	if presentation_frozen:return
	# Reversal braking is still requested locomotion. Do not replace its
	# authored pivot with a stop when velocity crosses zero under held input.
	var strength:=absf(_runtime_fighter._read_axis())
	var commanded := strength>.001
	var transition:=""
	if displacement>128:
		_gait_phase=0;_weight_transfer.clear();_authored_transition.clear();_motion_moving=false
	elif commanded and _visual_facing!=_previous_motion_facing and _motion_moving:
		transition="reverse"
	elif commanded and not _motion_moving:
		transition="pivot" if _visual_facing!=_previous_motion_facing else "dash" if strength>.85 else "start"
	elif _motion_moving and not commanded:
		transition="stop"
	elif commanded and strength>.85 and _previous_motion_strength<=.85:
		transition="dash"
	elif commanded and strength>.55 and _previous_motion_strength<=.55:
		transition="accelerate"
	if not transition.is_empty():
		if _authored_transition.enabled():_weight_transfer.clear();_authored_transition.begin(transition,_visual_facing)
		elif transition=="reverse":_weight_transfer.begin("pivot")
		elif transition in ["start","dash","pivot"]:_weight_transfer.begin("start")
		elif transition=="stop":_weight_transfer.begin("stop")
	_previous_motion_strength=strength
	_motion_moving=commanded;_previous_motion_speed=speed;_previous_motion_facing=_visual_facing
	var clip := str(_player.current_animation).get_slice("/",1)
	if _gait_half_stride.has(clip):
		_locomotion_synchronized = true
		# Physical stride coordinates are shared by all nine distance gaits;
		# they do not depend on having Kaia/Juno's newer source overlay.
		if not _gait_half_stride.has(_previous_gait_clip):
			# Neutral soles begin at zero fore/aft offset. Quarter-cycle places
			# the first support sole there instead of teleporting it a stride.
			_gait_phase=.25
		elif clip!=_previous_gait_clip and _gait_half_stride.has(_previous_gait_clip):
			# Preserve planted sole distance across walk/run stride changes.
			# A cycle fraction is not a shared physical position.
			var left_support:=_gait_phase<.5
			var old_stride:float=_gait_half_stride[_previous_gait_clip]
			var old_sole_z:=old_stride*((1-4*_gait_phase) if left_support else (3-4*_gait_phase))
			var new_stride:float=_gait_half_stride[clip]
			_gait_phase=clampf(((1 if left_support else 3)-old_sole_z/new_stride)/4,.0 if left_support else .5,.5 if left_support else 1.0)
		_previous_gait_clip=clip
		# Gameplay root displacement remains authoritative; preserve distance gait.
		var a: Vector2 = model._camera.unproject_position(_skeleton.to_global(Vector3.ZERO))
		var b: Vector2 = model._camera.unproject_position(_skeleton.to_global(Vector3(0,0,float(_gait_half_stride[clip]))))
		gait_period_px = 4*absf(b.x-a.x)*absf(model._display.scale.x)
		if gait_period_px>.01:
			# Reversal braking can move opposite the new facing. Follow real
			# signed displacement; never invent forward steps while sliding back.
			var phase_distance:float=signed_displacement*signf(b.x-a.x)
			_gait_phase=fposmod(_gait_phase+phase_distance/gait_period_px,1.0)
			_player.seek(_gait_phase*_player.current_animation_length,true)
	elif not _weight_transfer.kind.is_empty() or not _authored_transition.kind.is_empty():
		_previous_gait_clip=""
		# Reset the base pose each physics tick; never compound additive transforms.
		_locomotion_synchronized=true
		_player.advance(delta)
		_player.seek(_player.current_animation_position,true)
	if not _weight_transfer.kind.is_empty():_weight_transfer.apply(_skeleton,delta,_visual_facing)
	if not _authored_transition.kind.is_empty():_authored_transition.apply(_skeleton,delta,_visual_facing)
	_correct_support_knees()

func set_visual_facing(direction: int) -> void:
	_visual_facing = 1 if direction>=0 else -1


func _load_form_acting_overlay() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_skeleton):return
	var path := "res://data/animation/form_acting_8c/%s_%s.json" % [_fighter_id,_body_variant]
	if not FileAccess.file_exists(path):return
	_form_overlay_status = "unverified"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return
	var doc: Dictionary = parsed
	if doc.get("schema", "") != "original_form_acting_8c.v1" or not doc.get("source_actions_saved",false) or not doc.get("source_runtime_verified",false):return
	if doc.get("fighter_id", "") != _fighter_id or doc.get("body_variant", "") != _body_variant:return
	if str(doc.get("source_saved_blend_sha256", "")).length()!=64 or doc.get("human_approved",true):return
	var library := AnimationLibrary.new()
	for name in doc.get("clips",{}):
		var clip: Dictionary = doc.clips[name]
		if not str(clip.get("source_action", "")).begins_with("ANI08C_WIP_") or str(clip.get("source_blend_sha256","")) != doc.source_saved_blend_sha256:return
		for bone in clip.get("bone_tracks",{}):
			if _BoneMap.resolve_on_skeleton(_skeleton,str(bone)).is_empty():return
		var animation := _animation_from_data(clip)
		animation.loop_mode = Animation.LOOP_LINEAR if clip.get("loop",false) else Animation.LOOP_NONE
		library.add_animation(str(name),animation)
	if library.get_animation_list().size()!=8:return
	if _player.has_animation_library("form_acting_8c"):_player.remove_animation_library("form_acting_8c")
	_player.add_animation_library("form_acting_8c",library)
	for name in library.get_animation_list():_loaded_clips[name]=true
	_form_sources = {"stages":doc.stages,"source_saved_blend_sha256":doc.source_saved_blend_sha256,"remote_run_id":doc.get("remote_run_id","")}
	_form_overlay_status = "verified_saved_export"

func _form_clip(form_id: String, kind: String) -> String:
	var stage: Dictionary = _form_sources.get("stages",{}).get(form_id,{})
	var name := str(stage.get(kind,""))
	if name.is_empty():return ""
	if _visual_facing < 0:name += "_left"
	return name if _loaded_clips.has(name) else ""

func begin_form_sequence(target_id: String) -> bool:
	var clip := _form_clip(target_id,"transition_clip")
	if clip.is_empty():return false
	_form_sequence = clip;_form_progress = 0.0
	_neutral_return_pose.clear();_grounded_return.clear();_authored_transition.clear();_weight_transfer.clear()
	_move_synchronized = false;_locomotion_synchronized = false
	_player.play("form_acting_8c/"+clip,0.0);_player.seek(0.0,true)
	_active_clip = clip
	return true

func sample_form_sequence(progress: float) -> void:
	if _form_sequence.is_empty() or not is_instance_valid(_player):return
	_form_progress = clampf(progress,0,1)
	_player.seek(_player.current_animation_length*_form_progress,true)

func end_form_sequence() -> void:
	_form_sequence = "";_form_progress = 0.0

func get_form_acting_report() -> Dictionary:
	return {"status":_form_overlay_status,"source":_form_sources.duplicate(true),"sequence":_form_sequence,"progress":_form_progress,"active_clip":_active_clip,"human_approved":false}
