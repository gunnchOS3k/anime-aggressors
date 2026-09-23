extends RefCounted
class_name AnimationPoseContract

## Contact pose must land inside the authored hitbox window. No root motion.

const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")


static func contact_frame_for_move(move: Dictionary) -> int:
	var choreo: Dictionary = move.get("choreography", {})
	if choreo.has("contact_frame"):
		return int(choreo.get("contact_frame"))
	var startup := int(move.get("startup_frames", 0))
	return startup


static func hitbox_window(move: Dictionary) -> Vector2i:
	var startup := int(move.get("startup_frames", 0))
	var active := int(move.get("active_frames", 1))
	var boxes: Array = move.get("hitboxes", [])
	if boxes.size() > 0 and boxes[0] is Dictionary:
		var b: Dictionary = boxes[0]
		if b.has("start_frame") and b.has("end_frame"):
			return Vector2i(int(b.get("start_frame")), int(b.get("end_frame")))
	return Vector2i(startup, startup + maxi(active, 1))


static func contact_aligned(move: Dictionary) -> bool:
	var window := hitbox_window(move)
	var contact := contact_frame_for_move(move)
	return contact >= window.x and contact <= window.y


static func contact_pose_clip(move: Dictionary, tier: String) -> String:
	var choreo: Dictionary = move.get("choreography", {})
	var explicit := str(choreo.get("contact_pose_clip", ""))
	if not explicit.is_empty():
		return explicit
	match tier:
		"ko":
			return "contact_ko"
		"super":
			return "contact_super"
		"aura":
			return "contact_aura"
		"heavy":
			return "contact_heavy"
		"medium":
			return "contact_medium"
		_:
			return "contact_light"


static func socket_for_move(move: Dictionary) -> String:
	var choreo: Dictionary = move.get("choreography", {})
	var sock := str(choreo.get("contact_socket", ""))
	if not sock.is_empty():
		return sock
	var fb: Dictionary = move.get("feedback", {})
	return str(fb.get("vfx_socket", "chest"))


static func forbids_generic_special(requested_clip: String, resolved: Dictionary) -> bool:
	if requested_clip == "special" and str(resolved.get("mapping_status", "")) == "MISSING_CLIP":
		return true
	if str(resolved.get("clip", "")) == "special" and str(resolved.get("mapping_status", "")) != "EXACT":
		return true
	return false
