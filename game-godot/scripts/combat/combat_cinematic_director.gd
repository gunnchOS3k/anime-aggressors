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
