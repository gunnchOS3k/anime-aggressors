extends RefCounted
class_name SecondaryMotionLayer

## Optional spring follow on Hair_/Cape_/Coat_/Skirt_/Cloth_ bones.
## Fallback only. Never claims authored secondary quality. No root motion.

const PREFIXES := ["Hair_", "Cape_", "Coat_", "Skirt_", "Cloth_"]
const READY := true


static func should_apply(a11y_reduce_motion: bool) -> bool:
	if not READY:
		return false
	return not a11y_reduce_motion


static func optional_bones_on(skeleton: Skeleton3D) -> Array:
	var found: Array = []
	if skeleton == null:
		return found
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)
		for prefix in PREFIXES:
			if name.begins_with(prefix):
				found.append(name)
				break
	return found


static func provenance() -> String:
	return "PROCEDURAL_FALLBACK"
