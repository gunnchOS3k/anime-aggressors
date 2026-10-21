extends RefCounted
## Saved Blender source deltas over the existing distance gait. The existing
## support constraint preserves its feet; this layer never moves a model/root.
var clips:Dictionary={}
var kind:=""
var elapsed:=0.0
var support_error_m:=0.0
var source_action:=""
var _solver=preload("res://scripts/visual/locomotion_weight_transfer.gd").new()

func register(name:String,clip:Dictionary)->void:
	if clip.has("transition_kind"):clips[name]=clip
func enabled()->bool:return not clips.is_empty()
func begin(action:String)->void:
	kind=action;elapsed=0;support_error_m=0;source_action=""
func clear()->void:kind="";elapsed=0;support_error_m=0;source_action=""
func vector(a:Array)->Vector3:return Vector3(a[0],a[1],a[2])
func rotation(a:Array)->Quaternion:return Quaternion(a[0],a[1],a[2],a[3]).normalized()
func apply(sk:Skeleton3D,delta:float,facing:int)->void:
	sample(sk,elapsed+delta,facing)
func sample(sk:Skeleton3D,time:float,facing:int)->void:
	if kind.is_empty():return
	var name:="transition_"+kind+("_left" if facing==-1 else "")
	if not clips.has(name):clear();return
	var clip:Dictionary=clips[name]
	elapsed=time
	if elapsed>=float(clip.duration_frames)/60.0:clear();return
	source_action=str(clip.source_action);support_error_m=0
	sk.force_update_all_bone_transforms()
	var feet:Dictionary={}
	for side in ["L","R"]:feet[side]=sk.get_bone_global_pose(sk.find_bone("Foot_"+side))
	# These are evaluated source-action keys, not runtime-generated body poses.
	for bone in clip.transition_mask:
		var index:=sk.find_bone(str(bone))
		var keys:Array=clip.bone_tracks[bone]
		var f:float=clampf(elapsed*60,0,keys.size()-1)
		var i:=int(f);var j:=mini(i+1,keys.size()-1)
		var base:Quaternion=rotation(keys[0].rotation_quat)
		var target:Quaternion=rotation(keys[i].rotation_quat).slerp(rotation(keys[j].rotation_quat),f-i)
		sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index)*(base.inverse()*target))
		if bone=="Hips":
			var offset:Vector3=vector(keys[i].position_m).lerp(vector(keys[j].position_m),f-i)-vector(keys[0].position_m)
			sk.set_bone_pose_position(index,sk.get_bone_pose_position(index)+offset)
	sk.force_update_all_bone_transforms()
	for side in ["L","R"]:
		var foot:Transform3D=feet[side]
		support_error_m=maxf(support_error_m,_solver.hold_foot(sk,side,foot.origin,Vector3.BACK))
		var index:=sk.find_bone("Foot_"+side)
		var parent_basis:=sk.get_bone_global_pose(sk.get_bone_parent(index)).basis
		sk.set_bone_pose_rotation(index,(parent_basis.inverse()*foot.basis).orthonormalized().get_rotation_quaternion())
	sk.force_update_all_bone_transforms()
func evidence()->Dictionary:
	return {"kind":kind,"elapsed_s":elapsed,"source_action":source_action,"support_error_m":support_error_m,"authority":"saved Blender transition; existing gait/support constraint","human_approved":false}
