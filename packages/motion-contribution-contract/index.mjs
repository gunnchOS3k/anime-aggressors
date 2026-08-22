export const CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION = false;

export const CONTRIBUTION_STATES = [
  "QUARANTINED",
  "VALIDATED",
  "NORMALIZED",
  "RETARGETED",
  "QA_PASSED",
  "REVIEW_PENDING",
  "APPROVED_FOR_PRODUCTION",
  "REJECTED",
];

export const CONSENT_STAGES = [
  "upload_received",
  "metadata_stripped",
  "schema_validated",
  "normalize_pass",
  "retarget_pass",
  "qa_pass",
  "preview_available",
  "owner_review_pending",
];

export const PIPELINE_FLAGS = {
  USER_MOTION_UPLOAD_PIPELINE_READY: true,
  USER_MOTION_CONTRIBUTION_CONTRACT_READY: true,
  REAL_USER_MOTION_LIBRARY_PRESENT: false,
  EDMUND_PERSONAL_MOTION_REQUIRED: false,
  BIOMETRIC_INFERENCE_FORBIDDEN: true,
  PRODUCTION_CAN_LOAD_QUARANTINED_UPLOAD: false,
  USER_MOTION_ARBITRARY_FORMAT_RETARGET_READY: false,
};

/** A: contributor declaration — cannot set production approval */
export function validateContributorDeclaration(contribution) {
  const missing = CONSENT_STAGES.filter(
    (s) => !(contribution?.consent?.stages || []).includes(s),
  );
  const hasProductionApproval =
    contribution?.production_status === "APPROVED_FOR_PRODUCTION" ||
    (contribution?.consent?.stages || []).includes("production_use_approved");
  return {
    ok: missing.length === 0 && !hasProductionApproval,
    missingStages: missing,
    contributorSelfApprovalBlocked: hasProductionApproval
      ? "CONTRIBUTOR_CAN_SELF_APPROVE_PRODUCTION=false"
      : null,
    state: contribution?.state || "QUARANTINED",
  };
}

/** B: machine technical record */
export function validateProcessingRecord(record) {
  return {
    ok: Boolean(record?.normalize_pass && record?.schema_valid),
    machineGenerated: record?.generated_by === "motion_pipeline",
    BVH_NORMALIZATION_EXECUTION_READY: record?.bvh_normalization_execution_ready === true,
    RETARGET_EXECUTION_READY: record?.retarget_execution_ready === true,
  };
}

/** C: trusted reviewer only */
export function validateReviewRecord(review) {
  const trusted = review?.reviewer_role === "trusted_owner_reviewer";
  const approved =
    trusted &&
    review?.decision === "APPROVED_FOR_PRODUCTION" &&
    review?.all_checks_passed === true;
  return {
    ok: trusted,
    productionUseAllowed: approved,
    localOwnerReviewMode: review?.local_owner_review_mode === true,
  };
}

export function nextState(current, event) {
  const transitions = {
    QUARANTINED: { validated: "VALIDATED" },
    VALIDATED: { normalized: "NORMALIZED" },
    NORMALIZED: { retargeted: "RETARGETED" },
    RETARGETED: { qa_passed: "QA_PASSED" },
    QA_PASSED: { review_pending: "REVIEW_PENDING" },
    REVIEW_PENDING: { approved: "APPROVED_FOR_PRODUCTION", rejected: "REJECTED" },
  };
  return transitions[current]?.[event] || current;
}
