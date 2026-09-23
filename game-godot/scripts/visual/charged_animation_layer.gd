extends RefCounted
class_name ChargedAnimationLayer

## Phase 1 hook only. Does not silently replace uncharged clips.

const READY := false


static func layer_for_move(move: Dictionary) -> String:
	var choreo: Dictionary = move.get("choreography", {})
	return str(choreo.get("charged_layer", "none"))


static func overlay_clip(base_clip: String, move: Dictionary) -> String:
	var layer := layer_for_move(move)
	if layer == "hold":
		return "charged_hold"
	if layer == "release":
		return "uncharged_release" if base_clip.is_empty() else base_clip
	return base_clip


static func should_apply(_fighter_id: String, _move: Dictionary) -> bool:
	return READY
