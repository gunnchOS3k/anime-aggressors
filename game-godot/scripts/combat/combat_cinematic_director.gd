extends RefCounted
class_name CombatCinematicDirector

## Presentation classes only. Camera stays a11y-gated. Gameplay timing unchanged.

const CLASS_NONE := "NONE"
const CLASS_IMPACT := "IMPACT"
const CLASS_HEAVY := "HEAVY"
const CLASS_AURA := "AURA"
const CLASS_SUPER := "SUPER"
const CLASS_CLASH := "CLASH"
const CLASS_KO := "KO"

const CLASSES := [CLASS_NONE, CLASS_IMPACT, CLASS_HEAVY, CLASS_AURA, CLASS_SUPER, CLASS_CLASH, CLASS_KO]

## Architecture ready: class routing + safe hooks. Camera impulse still opt-in.
const READY := true


static func class_for(tier: String, clash: bool = false, a11y_allows_camera: bool = true) -> String:
	if clash:
		return CLASS_CLASH if a11y_allows_camera else CLASS_NONE
	match str(tier):
		"ko":
			return CLASS_KO
		"super":
			return CLASS_SUPER
		"aura":
			return CLASS_AURA
		"heavy":
			return CLASS_HEAVY
		"medium", "light":
			return CLASS_IMPACT
		_:
			return CLASS_NONE


static func hook_for_move(move: Dictionary) -> String:
	var choreo: Dictionary = move.get("choreography", {})
	return str(choreo.get("cinematic_hook", ""))


static func should_direct(tier: String, a11y_allows_camera: bool) -> bool:
	if not a11y_allows_camera:
		return false
	return class_for(tier, false, true) in [CLASS_HEAVY, CLASS_AURA, CLASS_SUPER, CLASS_CLASH, CLASS_KO]


static func request_impulse(scene: Node, tier: String) -> void:
	if not READY:
		return
	if scene == null:
		return
	# Safe no-op unless the scene exposes a presentation hook. Never writes CombatMath.
	if scene.has_method("apply_cinematic_impulse"):
		scene.apply_cinematic_impulse(class_for(tier, false, true))


static func shot_for_class(cine_class: String) -> Dictionary:
	## Per-class authored shot descriptor. Not one hard-coded super shot.
	var library := {
		CLASS_NONE: {"duration": 0, "fov": 50.0, "offset": [0, 0, 0], "look_at": "gameplay", "ease_in": "none", "ease_out": "none", "shake_profile": "none", "reduce_camera_fallback": "gameplay"},
		CLASS_IMPACT: {"duration": 3, "fov": 48.0, "offset": [0, 10, 36], "look_at": "contact", "ease_in": "quad", "ease_out": "quad", "shake_profile": "tick", "reduce_camera_fallback": "hold"},
		CLASS_HEAVY: {"duration": 6, "fov": 44.0, "offset": [0, 14, 38], "look_at": "contact", "ease_in": "cubic", "ease_out": "quad", "shake_profile": "heavy", "reduce_camera_fallback": "hold"},
		CLASS_AURA: {"duration": 8, "fov": 40.0, "offset": [0, 16, 42], "look_at": "attacker", "ease_in": "expo", "ease_out": "sine", "shake_profile": "aura", "reduce_camera_fallback": "gameplay"},
		CLASS_SUPER: {"duration": 10, "fov": 36.0, "offset": [6, 18, 44], "look_at": "attacker", "ease_in": "expo", "ease_out": "cubic", "shake_profile": "super", "reduce_camera_fallback": "gameplay"},
		CLASS_CLASH: {"duration": 12, "fov": 38.0, "offset": [0, 16, 40], "look_at": "midpoint", "ease_in": "quad", "ease_out": "quad", "shake_profile": "pressure", "reduce_camera_fallback": "gameplay"},
		CLASS_KO: {"duration": 14, "fov": 42.0, "offset": [8, 12, 40], "look_at": "victim", "ease_in": "cubic", "ease_out": "sine", "shake_profile": "ko", "reduce_camera_fallback": "hold"},
	}
	return library.get(cine_class, library[CLASS_NONE])


static func restore_always() -> bool:
	return true
