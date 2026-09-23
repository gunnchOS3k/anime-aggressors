extends RefCounted
class_name CombatCinematicDirector

## Phase 1 hook. Camera impulses stay opt-in and a11y-gated.

const READY := false


static func hook_for_move(move: Dictionary) -> String:
	var choreo: Dictionary = move.get("choreography", {})
	return str(choreo.get("cinematic_hook", ""))


static func should_direct(tier: String, a11y_allows_camera: bool) -> bool:
	if not a11y_allows_camera:
		return false
	return tier in ["heavy", "aura", "super", "ko"]


static func request_impulse(_scene: Node, _tier: String) -> void:
	if not READY:
		return
