# PR #106 Forward-Port Plan

Provenance: draft [#106](https://github.com/gunnchOS3k/anime-aggressors/pull/106) (`vxp/vxp-3-combat-impact-nix-rook` @ `8cd3e135`).

Policy: **do not merge #106 wholesale**. Prior infrastructure salvage already landed via [#107](https://github.com/gunnchOS3k/anime-aggressors/pull/107). This plan forward-ports only remaining unique production value onto current `main` (post-#113/#114/#115).

## What #106 contained vs main

| Bucket | Disposition |
| --- | --- |
| Authored animation contracts / deform / control-rig / export preset | Mostly **already on main** via #107 |
| Wave A ACTION.json + pose bibles + pipeline_proof.glb | **Forward-ported** (this PR) |
| Authored Blender tool chain + CI workflow | **Forward-ported** (this PR) |
| Animator / Aura Clash docs | **Forward-ported** (this PR) |
| AuraClashDirector + cinematic combat runtime GD | **Deferred** — conflicts with 161-move routing + PartyLink; data schemas parked only |
| Generated art v3–v9 / review PNGs / Pixel evidence | **Discard / reference-only** — remain in #106 history |
| Small fighter `.blend` blockouts | **Already identical on main** |

## Blender source

`BLENDER_SOURCE_AVAILABLE` for the seven small roster blockout `.blend` files (same blobs on main and #106). Full Wave A hero acting masters are still human work; do not claim final authored reproducibility.

## Gates (automation)

- `AUTHORED_ANIMATION_PIPELINE_FORWARD_PORT_PASS=true`
- `AUTHORED_EXPORT_IMPORT_FORWARD_PORT_PASS=true` (pipeline_proof assets present)
- `AUTHORED_PROVENANCE_FORWARD_PORT_PASS=true` (ACTION.json labels; automation never writes `AUTHORED_APPROVED`)
- `AUTHORED_ROSTER_PRODUCTION_MANIFEST_PASS=true`
- `AURA_CLASH_CURRENT_MAIN_COMPAT_PASS=false` (runtime not wired)
- `SELECTED_GENERATED_ART_FORWARD_PORT_PASS=true` (pipeline_proof only)
- Human animation / originality / final-art / merge: **remain false**

## After merge of this forward-port

Owner may close #106 as superseded once salvage coverage is accepted. Aura Clash runtime remains a separate engineering track if desired.
