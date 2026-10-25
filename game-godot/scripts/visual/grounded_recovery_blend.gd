extends RefCounted
## Visual settling from an authored end pose into the neutral crouch. Never
## locks gameplay movement or moves the fighter/model root. Existing limb
## lengths and authored feet are preserved with the shared two-bone solver.
const DURATION := .12
var active := false
var elapsed := 0.0
var support_error_m := 0.0
var pose: Array = []
var feet: Dictionary = {}
var solver = preload("res://scripts/visual/locomotion_weight_transfer.gd").new()
var profile: Dictionary = {}
var support_side := "L"
var duration := DURATION
var authored_exchange := false

func configure(fighter_id: String) -> void:
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/support_exchanges.json"))
	profile=doc.fighters.get(fighter_id,{})

func curve(keys: Array, phase: float) -> Vector2:
	for i in range(1,keys.size()):
		if phase<=float(keys[i][0]):
			var t:=smoothstep(float(keys[i-1][0]),float(keys[i][0]),phase)
			return Vector2(lerpf(keys[i-1][1],keys[i][1],t),lerpf(keys[i-1][2],keys[i][2],t))
	return Vector2(1,0)

func clear() -> void:
	active = false; elapsed = 0.0; support_error_m = 0.0
	pose.clear(); feet.clear()

func begin(sk: Skeleton3D, gait_phase := 0.0, frames := 0, use_authored_exchange := false) -> void:
	clear()
	support_side="L" if gait_phase<.5 else "R"
	authored_exchange=use_authored_exchange
	duration=float(frames)/60.0 if frames>0 else (float(profile.get("stop_frames",DURATION*60))/60.0 if authored_exchange else DURATION)
	sk.force_update_all_bone_transforms()
	for name in ["Hips", "UpperLeg_L", "LowerLeg_L", "Foot_L", "UpperLeg_R", "LowerLeg_R", "Foot_R"]:
		var index := sk.find_bone(name)
		if index < 0: clear(); return
		pose.append({"bone": index, "rotation": sk.get_bone_pose_rotation(index), "position": sk.get_bone_pose_position(index)})
	for side in ["L", "R"]:
		feet[side] = sk.get_bone_global_pose(sk.find_bone("Foot_" + side))
	active = true

func apply(sk: Skeleton3D, delta: float) -> void:
	if not active: return
	elapsed += delta
	var phase:=clampf(elapsed/maxf(duration,.001),0,1)
	var weight := smoothstep(0.0, 1.0, phase)
	# Read the freshly evaluated neutral pose before applying any offsets.
	sk.force_update_all_bone_transforms()
	var targets: Dictionary = {}
	for side in ["L", "R"]:
		var target := sk.get_bone_global_pose(sk.find_bone("Foot_" + side))
		var previous: Transform3D = feet[side]
		var keys:Array=profile.get("support" if side==support_side else "swing",[[0,0,0],[1,1,0]]) if authored_exchange else [[0,0,0],[1,1,0]]
		var step:=curve(keys,phase)
		var exchange:=previous.interpolate_with(target,step.x)
		exchange.origin.y+=step.y
		targets[side] = exchange
	for bone in pose:
		var index := int(bone.bone)
		var rotation: Quaternion = bone.rotation
		var position: Vector3 = bone.position
		sk.set_bone_pose_rotation(index, rotation.slerp(sk.get_bone_pose_rotation(index), weight))
		sk.set_bone_pose_position(index, position.lerp(sk.get_bone_pose_position(index), weight))
	sk.force_update_all_bone_transforms()
	support_error_m = 0.0
	for side in ["L", "R"]:
		var target: Transform3D = targets[side]
		support_error_m = maxf(support_error_m, solver.hold_foot(sk, side, target.origin))
		var index := sk.find_bone("Foot_" + side)
		var parent_basis := sk.get_bone_global_pose(sk.get_bone_parent(index)).basis
		sk.set_bone_pose_rotation(index, (parent_basis.inverse() * target.basis).orthonormalized().get_rotation_quaternion())
	sk.force_update_all_bone_transforms()
	if elapsed >= duration: active = false; pose.clear(); feet.clear()
