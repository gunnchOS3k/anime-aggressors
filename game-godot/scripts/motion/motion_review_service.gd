extends Node
class_name MotionReviewService

## Trusted review only — local owner-review mode for motion contributions.

const TRUSTED_REVIEWER_ROLE := "trusted_owner_reviewer"
const LOCAL_OWNER_REVIEW_MODE := true

func compare_spec_to_animatic(fighter_id: String, action_key: String) -> Dictionary:
	var spec_path := "res://../../content/choreography/%s/%s.json" % [fighter_id, action_key]
	var anim_path := "res://../../tools/motion_pipeline/reference_animation/%s/%s.json" % [fighter_id, action_key]
	return {
		"ok": true,
		"fighter_id": fighter_id,
		"action_key": action_key,
		"spec_path": spec_path,
		"anim_path": anim_path,
		"reference_only": true,
		"runtime_alignment_expected": true,
	}

func notes_driven_active() -> bool:
	return true

func is_trusted_reviewer(role: String) -> bool:
	return role == TRUSTED_REVIEWER_ROLE

func approve_for_production(contribution_id: String, reviewer_role: String, all_checks_passed: bool) -> Dictionary:
	if not is_trusted_reviewer(reviewer_role):
		return {"ok": false, "error": "trusted_reviewer_required"}
	if not all_checks_passed:
		return {"ok": false, "error": "all_checks_must_pass"}
	return {
		"ok": true,
		"contribution_id": contribution_id,
		"decision": "APPROVED_FOR_PRODUCTION",
		"local_owner_review_mode": LOCAL_OWNER_REVIEW_MODE,
		"target_dir": "content/approved_motion/",
	}
