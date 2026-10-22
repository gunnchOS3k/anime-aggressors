extends SceneTree
## Lightweight unit contract, NOT saved-source/native art acceptance.
var failures: Array=[]
func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	var model:=Node3D.new();root.add_child(model)
	var rig:=Skeleton3D.new();rig.name="Skeleton3D";model.add_child(rig)
	for name in ["Head","D8_Finger_L_0_0","D8_hair_0_0"]:rig.add_bone(name)
	var primary:=AnimationPlayer.new();model.add_child(primary)
	var library:=AnimationLibrary.new();var clips: Dictionary={}
	for category in ["grip","fist","recoil","idle"]:
		var anim:=Animation.new();anim.length=1.0
		for name in ["Head","D8_Finger_L_0_0","D8_hair_0_0"]:
			var index:=anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(index,NodePath("Skeleton3D:"+name))
			anim.track_insert_key(index,0.0,Quaternion.IDENTITY)
			anim.track_insert_key(index,1.0,Quaternion(Vector3.RIGHT,.35))
		library.add_animation("ANI08D_WIP_"+category,anim)
		clips[category]={"source_action":"ANI08D_WIP_"+category}
	primary.add_animation_library("",library)
	var control=preload("res://scripts/visual/source_controls_8d.gd").new();model.add_child(control)
	control.setup(null,model,rig,primary,{"clips":clips,"fighter":"unit","body":"male"})
	check(control.status=="actual_saved_GLTF_tracks","both source track groups detected")
	for player in [control.hands,control.secondary]:
		for name in player.get_animation_list():
			var anim: Animation=player.get_animation(name)
			for index in range(anim.get_track_count()):
				var bone:=str(anim.track_get_path(index).get_subname(0))
				check(bone.begins_with("D8_"),"no original body tracks")
				check(bone.begins_with("D8_Finger_")==(player==control.hands),"disjoint hand/accessory owners")
	var head:=rig.find_bone("Head");rig.set_bone_pose_rotation(head,Quaternion(Vector3.UP,.2));var original:=rig.get_bone_pose_rotation(head)
	control.sample("grip",1.0);control.sample("idle",1.0,false)
	check(rig.get_bone_pose_rotation(head).is_equal_approx(original),"canonical pose retained")
	check(rig.get_bone_pose_rotation(1).angle_to(Quaternion.IDENTITY)>.3,"finger actually posed")
	check(rig.get_bone_pose_rotation(2).angle_to(Quaternion.IDENTITY)>.3,"hair actually posed")
	control.sample("fist",0.0)
	check(rig.get_bone_pose_rotation(1).is_equal_approx(Quaternion.IDENTITY),"neutral hand resets")
	var f:=FileAccess.open("/private/tmp/aa8d_layer_result.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"scope":"synthetic track ownership unit only; no real-source/native acceptance"},"\t"));f.close()
	model.free();quit(0 if failures.is_empty() else 1)
