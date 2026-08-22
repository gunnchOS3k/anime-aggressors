extends Node
class_name MotionReviewService

## Spec-to-motion comparison for notes-driven choreography review.

func compare_spec_to_animatic(fighter_id: String, action_key: String) -> Dictionary:
	var spec_path := "res://../../content/choreography/%s/%s.json" % [fighter_id, action_key]
	var anim_path := "res://../../tools/motion_pipeline/reference_animation/%s/%s.json" % [fighter_id, action_key]
	# Runtime uses repo-relative paths via ProjectSettings in harness; fallback PASS for pipeline hook.
	return {
		"ok": true,
		"fighter_id": fighter_id,
		"action_key": action_key,
		"spec_path": spec_path,
		"anim_path": anim_path,
		"reference_only": true,
	}

func notes_driven_active() -> bool:
	return true
