extends Node
class_name MotionContributionService

## Future-ready user motion contribution pipeline (no real uploads in Wave013B).

const RAW_DIR := "user://motion_contributions/raw"
const NORMALIZED_DIR := "user://motion_contributions/normalized"

func pipeline_ready() -> bool:
	return true

func real_user_motion_library_present() -> bool:
	return false

func edmund_personal_motion_required() -> bool:
	return false

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
		"production_use_approved",
	]

func biometric_inference_forbidden() -> bool:
	return true
