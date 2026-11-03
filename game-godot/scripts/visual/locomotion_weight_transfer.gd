extends RefCounted
## Authored transient weight mechanics over distance-driven gait. No root/physics authority.
var profile: Dictionary = {}
var kind := ""
var elapsed := 0.0
var duration := 0.0
var support_error_m := 0.0
var load := 0.0
func setup(fighter_id: String) -> void:
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/locomotion_transitions.json"))
	profile=doc.fighters.get(fighter_id,{})
func begin(action: String) -> void:
	kind=action;elapsed=0
	duration=float(profile.get("duration",[.2,.2,.2])[["start","stop","pivot"].find(action)])
func clear() -> void:kind="";elapsed=0;load=0;support_error_m=0
func envelope(t: float) -> float:
	var curve: Array=profile.get("curve",[[0,0],[.5,1],[1,0]])
	for i in range(1,curve.size()):
		if t<=float(curve[i][0]):
			var phase:=clampf((t-float(curve[i-1][0]))/(float(curve[i][0])-float(curve[i-1][0])),0,1)
			return lerpf(float(curve[i-1][1]),float(curve[i][1]),phase*phase*(3-2*phase))
	return 0
func arc_rotation(a: Vector3,b: Vector3) -> Basis:
	# Quaternion(from,to) treats almost-parallel directions as identity.
	# Small settle corrections still matter to a planted support foot.
	var left:=a.normalized();var right:=b.normalized();var cross:=left.cross(right)
	if cross.length_squared()<1e-18:return Basis.IDENTITY
	return Basis(Quaternion(cross.normalized(),atan2(cross.length(),left.dot(right))))
func turn_world(sk: Skeleton3D,index: int,delta: Basis) -> void:
	var parent:=sk.get_bone_parent(index)
	var parent_basis:=sk.get_bone_global_pose(parent).basis if parent>=0 else Basis.IDENTITY
	var desired:=delta*sk.get_bone_global_pose(index).basis
	sk.set_bone_pose_rotation(index,(parent_basis.inverse()*desired).orthonormalized().get_rotation_quaternion())
	sk.force_update_all_bone_transforms()
func hold_foot(sk: Skeleton3D,side: String,target: Vector3,bend_hint := Vector3.ZERO) -> float:
	var a:=sk.find_bone("UpperLeg_"+side);var b:=sk.find_bone("LowerLeg_"+side);var c:=sk.find_bone("Foot_"+side)
	var ap:=sk.get_bone_global_pose(a).origin;var bp:=sk.get_bone_global_pose(b).origin;var cp:=sk.get_bone_global_pose(c).origin
	var foot_basis:=sk.get_bone_global_pose(c).basis
	var l1:=ap.distance_to(bp);var l2:=bp.distance_to(cp);var v:=target-ap
	var distance:=clampf(v.length(),absf(l1-l2)+.000001,l1+l2-.000001);var axis:=v.normalized()
	var bend:=bp-ap-axis*(bp-ap).dot(axis)
	if bend_hint.length_squared()>.000001:bend=bend_hint-axis*bend_hint.dot(axis)
	if bend.length_squared()<.000001:bend=Vector3.FORWARD-axis*Vector3.FORWARD.dot(axis)
	bend=bend.normalized()
	var along: float=(l1*l1-l2*l2+distance*distance)/(2*distance)
	var knee:=ap+axis*along+bend*sqrt(maxf(0,l1*l1-along*along))
	turn_world(sk,a,arc_rotation(bp-ap,knee-ap))
	bp=sk.get_bone_global_pose(b).origin;cp=sk.get_bone_global_pose(c).origin
	turn_world(sk,b,arc_rotation(cp-bp,target-bp))
	var parent_basis:=sk.get_bone_global_pose(sk.get_bone_parent(c)).basis
	sk.set_bone_pose_rotation(c,(parent_basis.inverse()*foot_basis).orthonormalized().get_rotation_quaternion())
	sk.force_update_all_bone_transforms()
	return sk.get_bone_global_pose(c).origin.distance_to(target)
func apply(sk: Skeleton3D,delta: float,facing: int) -> void:
	if kind.is_empty():return
	elapsed+=delta
	if elapsed>=duration:clear();return
	load=envelope(elapsed/duration);support_error_m=0
	sk.force_update_all_bone_transforms()
	var targets: Dictionary={}
	for side in ["L","R"]:targets[side]=sk.get_bone_global_pose(sk.find_bone("Foot_"+side)).origin
	var scale: float=sk.get_bone_global_pose(sk.find_bone("Head")).origin.y/.85
	var hips:=sk.find_bone("Hips")
	var forward: float=float(profile.drive)*load*(-.75 if kind=="stop" else .25 if kind=="pivot" else 1)
	var lateral: float=float(profile.balance)*load*facing*(1.4 if kind=="pivot" else 1)
	sk.set_bone_pose_position(hips,sk.get_bone_pose_position(hips)+Vector3(lateral,-float(profile.depth)*load,forward)*scale)
	var twist: float=float(profile.turn)*load*facing*(1 if kind=="pivot" else .35)
	for name in ["Hips","Spine","Chest","Head"]:
		var index:=sk.find_bone(name)
		var pitch: float=float(profile.pitch)*load*(-.6 if kind=="stop" else 1)
		var angles:=Vector3(pitch*(.2 if name=="Hips" else -.25 if name=="Head" else 1),twist*(-.65 if name=="Chest" else -.2 if name=="Head" else 1),lateral*2)
		sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index)*Quaternion.from_euler(angles))
	sk.force_update_all_bone_transforms()
	for side in ["L","R"]:support_error_m=maxf(support_error_m,hold_foot(sk,side,targets[side]))
func evidence() -> Dictionary:
	return {"kind":kind,"elapsed_s":elapsed,"duration_s":duration,"load":load,"support_error_m":support_error_m,"direction":profile.get("direction","")}
