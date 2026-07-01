extends RefCounted
class_name MoveTimeline

## Orchestrates animation + hitbox + VFX + camera + audio for one move.

static func play(move_id: String, fighter: FighterController) -> void:
	var data := MoveChoreography.get_choreography(move_id)
	if fighter == null:
		return
	var anim := fighter.get_node_or_null("FighterAnimationDriver") as FighterAnimationDriver
	if anim != null:
		anim.current_animation = StringName(data.animation_name)
	HitboxTimeline.apply_active_frames(fighter, data)
	VfxTimeline.queue_trail(fighter, data)
	CameraTimeline.queue_event(fighter, data.camera_event)
	AudioTimeline.queue_event(fighter, data.audio_event)
