extends Node
## Only saved D8 joint tracks. Existing22 bones and gameplay clocks stay owned.
var actor
var rig: Skeleton3D
var hands: AnimationPlayer
var secondary: AnimationPlayer
var document: Dictionary = {}
var status := "missing"

static func candidate_document(fid: String, body: String, lane: String = "controls_8d") -> Dictionary:
	if lane not in ["controls_8d","hands_8d2","hands_8d3"]:return {}
	var schema:="saved_original_%s.v1"%lane
	var path:="res://data/animation/%s/%s_%s.json"%[lane,fid,body]
	if not FileAccess.file_exists(path):return {}
	var doc: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not doc is Dictionary or doc.get("schema","")!=schema or doc.get("fighter","")!=fid or doc.get("body","")!=body or doc.get("human_approved",true):return {}
	var resource:=str(doc.get("resource",""))
	if not resource.begins_with("res://assets/characters/"+lane+"/") or not FileAccess.file_exists(resource) or FileAccess.get_sha256(resource)!=str(doc.get("resource_sha256","")):return {}
	if lane=="hands_8d3" and (doc.get("paired_3d_verified",true) or doc.get("input_8d2_sha256","").length()!=64):return {}
	return doc

func setup(owner_actor, model: Node3D, skeleton: Skeleton3D, primary: AnimationPlayer, doc: Dictionary) -> void:
	actor=owner_actor;rig=skeleton;document=doc
	if doc.is_empty() or not is_instance_valid(primary):return
	for kind in ["hands","secondary"]:
		var library:=AnimationLibrary.new()
		for name in primary.get_animation_list():
			for category in doc.get("clips",{}):
				if not str(name).ends_with(str(doc.clips[category].source_action)):continue
				var clip:=primary.get_animation(name).duplicate(true) as Animation
				for index in range(clip.get_track_count()-1,-1,-1):
					var path:=clip.track_get_path(index)
					var bone:=str(path.get_subname(0)) if path.get_subname_count()>0 else ""
					var keep: bool=bone.begins_with("D8_") and (bone.begins_with("D8_Finger_")== (kind=="hands"))
					if not keep:clip.remove_track(index)
				if clip.get_track_count()>0:library.add_animation(category,clip)
		var player:=AnimationPlayer.new();player.name="Source8D_"+kind
		primary.get_parent().add_child(player);player.root_node=primary.root_node
		player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.add_animation_library("saved8d",library)
		if kind=="hands":hands=player
		else:secondary=player
	status="actual_saved_GLTF_tracks" if hands.has_animation("saved8d/grip")and secondary.has_animation("saved8d/idle")else"missing_exported_tracks"
	# Own players are children of the imported model and retire with that model.
	document=doc.duplicate(false);document.erase("clips")

func sample(category: String, phase: float, hand_layer: bool = true) -> void:
	var player:=hands if hand_layer else secondary
	if not is_instance_valid(player):return
	var name:="saved8d/"+category
	if not player.has_animation(name):return
	if player.current_animation!=name:player.play(name,0)
	player.seek(clampf(phase,0,1)*player.current_animation_length,true)

func _process(_delta: float) -> void:
	if status!="actual_saved_GLTF_tracks" or not is_instance_valid(actor) or actor.get_tree().paused or actor._hitstop>0:return
	var state:=str(actor.state_machine.current_state)
	var frame:=int(actor.state_machine.state_frame)
	if is_instance_valid(actor.grabbed_target):sample("grip",1)
	elif is_instance_valid(actor.move_runner) and actor.move_runner.active and str(actor.move_runner.current_move_id).begins_with("throw_") and hands.has_animation("saved8d/release"):
		var length:=maxf(.001,hands.get_animation("saved8d/release").length)
		sample("release",float(actor.move_runner.total_frame)/60.0/length)
	elif state.contains("startup") and not actor._current_move.is_empty():
		var frames:=maxf(1,float(actor._current_move.get("startup_frames",6)))
		sample("fist",float(frame)/frames)
	elif state.contains("active") or state.begins_with("shield"):sample("fist",1)
	elif state.contains("recovery"):
		sample("fist",1.0-float(frame)/maxf(1,float(actor._current_move.get("recovery_frames",18))))
	else:sample("fist",0)
	var time:=float(actor.state_machine.state_time)
	if state.begins_with("hurt") or state in ["hitstun","launched","land"]:sample("recoil",time/.8,false)
	else:
		var length:=secondary.get_animation("saved8d/idle").length
		sample("idle",fmod(time,maxf(.01,length))/maxf(.01,length),false)

func evidence() -> Dictionary:
	return {"status":status,"fighter":document.get("fighter",""),"body":document.get("body",""),"source_sha256":document.get("source_sha256",""),"resource":document.get("resource",""),"chains":document.get("chains",[]),"canonical_tracks_owned":false,"human_approved":false}
