# Mixamo Usage and Provenance

Adobe Mixamo is an **OPTIONAL** no-cost human-account animation utility for Wave012.

Flags (canonical in `vendor_pins/WAVE012_TOOL_PINS.json`):
- `MIXAMO_REQUIRED_FOR_BUILD=false`
- `MIXAMO_REQUIRED_FOR_PIPELINE_PASS=false`
- `MIXAMO_REQUIRED_FOR_FINAL_ART=false`

Core repo build and Wave012 pipeline PASS succeed with **zero** Mixamo assets.

## Rules

1. Do **not** redistribute raw Mixamo assets in the repo or releases.
2. Human Adobe account action is required for any acquisition (`MIXAMO_ASSET_ACQUISITION=HUMAN_ACCOUNT_ACTION_REQUIRED`).
3. Log acquisition + originality/retarget provenance before any derived clip is treated as production-ready.
4. Software/service ToS ≠ automatic production redistribution rights.
5. Prefer original choreography specs in `content/choreography/` when Mixamo is unavailable.

See also `docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md` and `content/wave012_provenance_overlay.json`.
