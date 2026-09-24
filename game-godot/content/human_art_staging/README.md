# Human-art staging (non-shipping)

`HUMAN_ART_STAGING=0` by default.

Place candidate GLBs at `<fighter-id>/<fighter-id>.glb` plus a sidecar JSON.

This folder is never selected by the production resolver unless the flag is explicitly on.
Compare against accepted runtime. Do not replace it.
