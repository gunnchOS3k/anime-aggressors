# Supported Motion Formats

Honest per-format capability status for Wave013B user motion contribution pipeline.

| Format | Upload | Structural Validation | Normalization | Retarget to canonical_humanoid_v1 | Production Ready |
|--------|--------|---------------------|---------------|-----------------------------------|------------------|
| BVH | Yes | Yes (hierarchy + frames) | Yes (execution) | Yes (fixture pass) | Review gate only |
| JSON (timeline) | Yes | Yes (schema) | Metadata strip | Contract only | No |
| GLB | Yes | Header only | No | No | No |
| FBX | Extension allowlist | No | No | No | No |
| CSV/TXT | Extension allowlist | No | Metadata strip | No | No |

## Truth flags

- `USER_MOTION_ARBITRARY_FORMAT_RETARGET_READY=false`
- `BVH_VALIDATION_READY=true`
- `BVH_NORMALIZATION_READY=true` (execution for BVH)
- `BVH_RETARGET_READY=true` (fixture pass; generic BVH humanoid profile)
- `USER_MOTION_RETARGET_PIPELINE_READY` — qualified: BVH fixture only, not arbitrary formats
- `RETARGET_CONTRACT_READY=true` for all profiles in `tools/motion_pipeline/retarget/profiles/`
- `RETARGET_EXECUTION_READY=true` for BVH via `generic_bvh_humanoid` profile only

Production loads only from `content/approved_motion/` after trusted review record.
