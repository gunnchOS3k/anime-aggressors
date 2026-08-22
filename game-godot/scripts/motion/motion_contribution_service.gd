extends Node
class_name MotionContributionService

## Contributor motion pipeline — contributors CANNOT self-approve production.

const RAW_DIR := "user://motion_contributions/raw"
const NORMALIZED_DIR := "user://motion_contributions/normalized"
const CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION := false
const PRODUCTION_CAN_LOAD_QUARANTINED_UPLOAD := false
const APPROVED_MOTION_DIR := "res://../../content/approved_motion/"

func pipeline_ready() -> bool:
	return true

func real_user_motion_library_present() -> bool:
	return false

func edmund_personal_motion_required() -> bool:
	return false

func contributor_can_self_approve_production() -> bool:
	return CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION

func production_can_load_quarantined() -> bool:
	return PRODUCTION_CAN_LOAD_QUARANTINED_UPLOAD

func upload_stages() -> Array[String]:
	return [
		"upload_received",
		"metadata_stripped",
		"schema_validated",
		"normalize_pass",
		"retarget_pass",
		"qa_pass",
		"preview_available",
		"owner_review_pending",
	]

func contribution_states() -> Array[String]:
	return [
		"QUARANTINED",
		"VALIDATED",
		"NORMALIZED",
		"RETARGETED",
		"QA_PASSED",
		"REVIEW_PENDING",
		"APPROVED_FOR_PRODUCTION",
		"REJECTED",
	]

func request_production_approval(_contribution_id: String) -> Dictionary:
	return {
		"ok": false,
		"error": "CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION=false",
		"redirect": "MotionReviewLab",
	}

func biometric_inference_forbidden() -> bool:
	return true
