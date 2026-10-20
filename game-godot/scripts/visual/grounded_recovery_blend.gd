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

func clear() -> void:
	active = false; elapsed = 0.0; support_error_m = 0.0
	pose.clear(); feet.clear()

func begin(sk: Skeleton3D) -> void:
	clear()
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
	var weight := smoothstep(0.0, DURATION, elapsed)
	# Read the freshly evaluated neutral pose before applying any offsets.
	sk.force_update_all_bone_transforms()
	var targets: Dictionary = {}
	for side in ["L", "R"]:
		var target := sk.get_bone_global_pose(sk.find_bone("Foot_" + side))
		var previous: Transform3D = feet[side]
		targets[side] = previous.interpolate_with(target, weight)
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
	if elapsed >= DURATION: active = false; pose.clear(); feet.clear()
