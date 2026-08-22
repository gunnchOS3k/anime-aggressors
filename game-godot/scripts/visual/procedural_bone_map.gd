extends RefCounted
class_name ProceduralBoneMap

## Canonical Wave012 rig bone names -> GLB Skeleton3D bone names (Blender export).

const CANONICAL_TO_GLB := {
	"Root": "root_2",
	"Hips": "pelvis",
	"Spine": "spine",
	"Chest": "chest_2",
	"Neck": "neck",
	"Head": "head_2",
	"Shoulder_L": "upper_arm.L",
	"UpperArm_L": "upper_arm.L",
	"LowerArm_L": "lower_arm.L",
	"Hand_L": "hand.L",
	"Shoulder_R": "upper_arm.R",
	"UpperArm_R": "upper_arm.R",
	"LowerArm_R": "lower_arm.R",
	"Hand_R": "hand.R",
	"UpperLeg_L": "upper_leg.L",
	"LowerLeg_L": "lower_leg.L",
	"Foot_L": "foot.L",
	"Toes_L": "foot.L",
	"UpperLeg_R": "upper_leg.R",
	"LowerLeg_R": "lower_leg.R",
	"Foot_R": "foot.R",
	"Toes_R": "foot.R",
}

const EVIDENCE_BONES := ["Hips", "Chest", "Hand_R", "Hand_L", "Foot_R", "Foot_L"]


static func glb_bone(canonical: String) -> String:
	return str(CANONICAL_TO_GLB.get(canonical, canonical))


static func resolve_on_skeleton(skeleton: Skeleton3D, canonical: String) -> String:
	var mapped := glb_bone(canonical)
	if skeleton.find_bone(mapped) >= 0:
		return mapped
	if skeleton.find_bone(canonical) >= 0:
		return canonical
	return ""
