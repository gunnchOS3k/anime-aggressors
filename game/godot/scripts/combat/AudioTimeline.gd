extends RefCounted
class_name AudioTimeline

## Audio event hooks — clips wired in M8 polish milestone.

static func queue_event(_fighter: FighterController, event_id: String) -> void:
	if event_id.is_empty():
		return
	# Placeholder: integrate AudioStreamPlayer bus in M8.
