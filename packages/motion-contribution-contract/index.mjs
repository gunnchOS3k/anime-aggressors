export const CONSENT_STAGES = [
  "upload_received",
  "metadata_stripped",
  "schema_validated",
  "normalize_pass",
  "retarget_pass",
  "qa_pass",
  "preview_available",
  "owner_review_pending",
  "production_use_approved",
];

export const PIPELINE_FLAGS = {
  USER_MOTION_UPLOAD_PIPELINE_READY: true,
  REAL_USER_MOTION_LIBRARY_PRESENT: false,
  EDMUND_PERSONAL_MOTION_REQUIRED: false,
  BIOMETRIC_INFERENCE_FORBIDDEN: true,
};

export function validateContribution(contribution) {
  const missing = CONSENT_STAGES.slice(0, 6).filter(
    (s) => !(contribution?.consent?.stages || []).includes(s),
  );
  return {
    ok: missing.length === 0,
    missingStages: missing,
    productionUseAllowed:
      (contribution?.consent?.stages || []).includes("production_use_approved") &&
      contribution?.consent?.production_use_after_approval === true,
  };
}
