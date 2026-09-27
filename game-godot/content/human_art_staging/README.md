# Human-art staging (non-shipping)

`HUMAN_ART_STAGING=0` and `HUMAN_ART_FULL_ROSTER_REVIEW=0` by default.

Place candidate GLBs at `<fighter-id>/<fighter-id>.glb` and fill `candidate_manifest.json`.

This folder is never selected by the production resolver unless a staging flag is explicitly on.
Generated V2–V9 experiment files are never in the fallback chain.
Compare against accepted runtime. Do not replace it. Do not claim `HUMAN_APPROVED`.
