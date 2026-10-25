extends RefCounted
## Original compact strike posture over existing authored motion. No root,
## gameplay, scale or bone-length authority. Hands retain their combat-plane
## projection; camera-depth freedom is bounded by the existing forearm length.
const PITCH_DEGREES := {"ember-vale":22.0,"rook-ironside":16.0,"juno-spark":28.0,"kaia-windrow":26.0,"nix-calder":24.0,"orion-vell":22.0,"vesper-nyx":24.0,"yin":12.0,"yang":26.0}
const MOVES := ["jab_1","forward_tilt","heavy_attack"]
var solver = preload("res://scripts/visual/locomotion_weight_transfer.gd").new()
var last: Dictionary = {}

func point(model,sk:Skeleton3D,p:Vector3)->Vector2:
	return model._camera.unproject_position(sk.to_global(p))

func projected_target(a:Vector3,h:Vector3,ray:Vector3,radius:float,depth_limit:float)->Dictionary:
	var v:=h-a
	if v.length()<=radius:return {"valid":true,"target":h,"depth":0.0}
	var along:=v.dot(ray)
	var square:=radius*radius-(v.length_squared()-along*along)
	if square<0:return {"valid":false}
	var reach:=sqrt(square)
	var depth:=clampf(0.0,-along-reach,-along+reach)
	return {"valid":absf(depth)<=depth_limit,"target":h+ray*depth,"depth":depth}

func arm(sk:Skeleton3D,side:String,target:Vector3,pole:Vector3,hand_basis:Basis)->void:
	var a:=sk.find_bone("UpperArm_"+side);var b:=sk.find_bone("LowerArm_"+side);var c:=sk.find_bone("Hand_"+side)
	var ap:=sk.get_bone_global_pose(a).origin;var bp:=sk.get_bone_global_pose(b).origin;var cp:=sk.get_bone_global_pose(c).origin
	var l1:=ap.distance_to(bp);var l2:=bp.distance_to(cp);var v:=target-ap;var axis:=v.normalized()
	var dist:=clampf(v.length(),absf(l1-l2)+.000001,l1+l2-.000001)
	var bend:=pole-axis*pole.dot(axis)
	if bend.length_squared()<1e-10:bend=Vector3((1 if side=="R" else -1),-.6,0)-axis*Vector3((1 if side=="R" else -1),-.6,0).dot(axis)
	var along:float=(l1*l1-l2*l2+dist*dist)/(2*dist)
	var elbow:=ap+axis*along+bend.normalized()*sqrt(maxf(0,l1*l1-along*along))
	solver.turn_world(sk,a,solver.arc_rotation(bp-ap,elbow-ap))
	bp=sk.get_bone_global_pose(b).origin;cp=sk.get_bone_global_pose(c).origin
	solver.turn_world(sk,b,solver.arc_rotation(cp-bp,target-bp))
	var parent:=sk.get_bone_global_pose(sk.get_bone_parent(c)).basis
	sk.set_bone_pose_rotation(c,(parent.inverse()*hand_basis).orthonormalized().get_rotation_quaternion())
	sk.force_update_all_bone_transforms()

func apply(actor,sk:Skeleton3D,frame:int,move:Dictionary)->void:
	var started:=Time.get_ticks_usec()
	last={"admitted":false,"reason":"ineligible"}
	if not is_instance_valid(actor) or not actor.is_on_floor():return
	# Hook arcs meet the arm-reach limit at different phases on different rigs.
	# Preserve the whole authored hook instead of switching correction strength
	# mid-arc. This pass addresses straight punches and committed heavy strikes.
	if str(move.get("move_id",""))=="jab_2":
		last={"admitted":false,"reason":"authored_hook_preserved"}
		return
	if not str(move.get("move_id","")) in MOVES:return
	var model=actor.model_3d
	if model==null or model._camera==null or model._camera.projection!=Camera3D.PROJECTION_ORTHOGONAL:return
	var start:=maxi(1,int(move.get("startup_frames",1)));var active:=maxi(1,int(move.get("active_frames",1)))
	var end:=start+active+maxi(1,int(move.get("recovery_frames",1)))
	var envelope:=smoothstep(0.0,float(start),float(frame)) if frame<start else 1.0-smoothstep(float(start+active),float(end),float(frame))
	if envelope<.00001:return
	var names:Array=["Spine","Chest","Neck","UpperArm_L","LowerArm_L","Hand_L","UpperArm_R","LowerArm_R","Hand_R"]
	var original:Dictionary={};var pose:Dictionary={}
	sk.force_update_all_bone_transforms()
	for name in names+["Head","Hips","Foot_L","Foot_R"]:
		var index:=sk.find_bone(name)
		if index<0:return
		original[name]=sk.get_bone_global_pose(index)
		if name in names:pose[index]=sk.get_bone_pose_rotation(index)
	var ray:Vector3=(sk.global_transform.basis.inverse()*model._camera.global_basis.z).normalized()
	var angle:=deg_to_rad(float(PITCH_DEGREES.get(actor.fighter_id,10.0)))*envelope
	for fraction in [1.0,.75,.5,.25]:
		for index in pose:sk.set_bone_pose_rotation(index,pose[index])
		sk.force_update_all_bone_transforms()
		var amount:float=angle*fraction
		for name in ["Spine","Chest"]:solver.turn_world(sk,sk.find_bone(name),Basis(Vector3.RIGHT,-amount*.5))
		var head:Transform3D=original.Head
		solver.turn_world(sk,sk.find_bone("Neck"),head.basis*sk.get_bone_global_pose(sk.find_bone("Head")).basis.inverse())
		var targets:Dictionary={};var valid:=true;var max_depth:=0.0
		for side in ["L","R"]:
			var a:Vector3=sk.get_bone_global_pose(sk.find_bone("UpperArm_"+side)).origin
			var b:Vector3=sk.get_bone_global_pose(sk.find_bone("LowerArm_"+side)).origin
			var c:Vector3=sk.get_bone_global_pose(sk.find_bone("Hand_"+side)).origin
			var hand:Transform3D=original["Hand_"+side]
			var target:=projected_target(a,hand.origin,ray,a.distance_to(b)+b.distance_to(c)-.000002,b.distance_to(c))
			if not target.valid:valid=false;break
			targets[side]=target;max_depth=maxf(max_depth,absf(target.depth))
		if not valid:continue
		var drift:=0.0
		for side in ["L","R"]:
			var old_a:Transform3D=original["UpperArm_"+side];var old_b:Transform3D=original["LowerArm_"+side];var hand:Transform3D=original["Hand_"+side]
			arm(sk,side,targets[side].target,old_b.origin-old_a.origin,hand.basis)
			drift=maxf(drift,point(model,sk,hand.origin).distance_to(point(model,sk,sk.get_bone_global_pose(sk.find_bone("Hand_"+side)).origin)))
		var before:=point(model,sk,head.origin);var after:=point(model,sk,sk.get_bone_global_pose(sk.find_bone("Head")).origin)
		var direction:float=actor.attack_direction if actor.attack_direction!=0 else actor.facing
		var retreat:float=-(after.x-before.x)*direction*absf(model._display.scale.x)
		if drift>.001 or retreat<=0:continue
		last={"admitted":true,"pitch_radians":amount,"phase_weight":envelope,"head_retreat_px":retreat,"wrist_projection_error_viewport_px":drift,"max_hand_depth_m":max_depth,"root_moved":false,"bone_lengths_changed":false,"cpu_usec":Time.get_ticks_usec()-started}
		return
	for index in pose:sk.set_bone_pose_rotation(index,pose[index])
	sk.force_update_all_bone_transforms()
	last={"admitted":false,"reason":"anatomical_reach_preserved"}
