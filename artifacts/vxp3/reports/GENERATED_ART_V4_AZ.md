# Generated Art v4 A–Z

Generated production art only. Not human-authored final art. Do not merge.

**A new head:** `7c7d4f2185d8d294707f743be47d3e637c845c3d`
**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106
**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`
**RC1:** `v1.0.0-rc.1` untouched

## B exact start CI failures

- Wave014 procedural_smoke: models_loaded=0 / anim_roots=0 because discovery still required PROCEDURAL_PRODUCTION_PROXY
- Wave020: Kaia silhouette_readable=false (coverage 0.482); headless texture_2d_get null spam

## C review-camera: FRONT_CAMERA_CORRECT=7/7 source=AA_FrontMarker + rest-pose Foot/Toes +Y

## D headless visibility: HEADLESS_VISIBILITY_NO_NULL_PASS=PASS

## E Wave014 discovery: WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS=PASS

## F Wave020 Kaia: WAVE020_ROSTER_VISIBILITY_PASS=PASS

## G Ember

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 1 verts=728
- pose deltas heavy/hurt/charge/super: 7.7603/6.6148/4.3503/5.0842

## H Rook

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 1 verts=616
- pose deltas heavy/hurt/charge/super: 7.041/4.1683/3.6911/4.0244

## I Juno

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 3 verts=224
- pose deltas heavy/hurt/charge/super: 8.2773/7.2127/4.0301/5.5652

## J Kaia

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 2 verts=448
- pose deltas heavy/hurt/charge/super: 5.688/4.4531/3.5068/3.9027

## K Nix

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 2 verts=416
- pose deltas heavy/hurt/charge/super: 5.3914/5.3276/3.0017/2.5471

## L Orion

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 2 verts=800
- pose deltas heavy/hurt/charge/super: 5.3786/7.4836/3.9092/3.0723

## M Vesper

- front_camera_correct: True
- packet_complete: True missing=[]
- costume front forms: 5 verts=336
- pose deltas heavy/hurt/charge/super: 7.1039/4.0766/3.1953/3.7653

## N hands: FAIL / pending
## O boots: FAIL / pending
## P heads: FAIL / pending
## Q costume: FAIL / pending
## R materials: FAIL / pending
## S heavy/hurt/charge/super: FAIL / pending / FAIL / pending / FAIL / pending / FAIL / pending
## T silhouette: FAIL / pending

## U review packet

`artifacts/vxp3/review/generated_art_v4/`

## V v4 gate matrix

- GEN_ART_V4_FRONT_CAMERA_PASS=True
- GEN_ART_V4_MOBILE_READ_PASS=False
- GEN_ART_V4_HAND_CRAFT_PASS=False
- GEN_ART_V4_BOOT_CRAFT_PASS=False
- GEN_ART_V4_HEAD_CRAFT_PASS=False
- GEN_ART_V4_COSTUME_COVERAGE_PASS=False
- GEN_ART_V4_MATERIAL_READ_PASS=False
- GEN_ART_V4_HERO_POSE_PASS=False
- GEN_ART_V4_HEAVY_CONTACT_READ_PASS=False
- GEN_ART_V4_HURT_READ_PASS=False
- GEN_ART_V4_CHARGE_BODY_READ_PASS=False
- GEN_ART_V4_SUPER_READ_PASS=False
- GEN_ART_V4_SILHOUETTE_ROSTER_PASS=False
- WAVE014_GENERATED_RUNTIME_DISCOVERY_PASS=True
- WAVE020_ROSTER_VISIBILITY_PASS=True
- HEADLESS_VISIBILITY_NO_NULL_PASS=True
- HUMAN_ART_DIRECTION_APPROVAL=False
- MERGE_AUTHORIZED=False

## W exact-head CI: pending after this push; local Wave014 smoke and Wave020 framing passed on generated GLBs
## X APK: not eligible — stills still read as remesh toys; do not build
## Y Pixel / HUMAN_*: false / not started
## Z remaining defects + next human step: FRONT cameras are contract-correct and Wave014/Wave020 pass locally, but stills still read as remesh toys (block hands, primitive heads, peach remesh around plates). Do not Pixel-review questions 1–12. Do not merge. Owner should inspect `artifacts/vxp3/review/generated_art_v4/` and exact-head CI; a later human/internal art pass is required for Q3-like craft.

