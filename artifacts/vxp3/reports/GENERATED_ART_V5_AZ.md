# Generated Art v5 A–Z

Generated production art only. Not human-authored final art. Do not merge.

**A new head:** `56afa57bcd4b716edcfbbb9f5284dab1f2de3ee0`
**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106
**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`
**RC1:** `v1.0.0-rc.1` untouched

## B non-remesh generator architecture

- `tools/generated_art_v5/` loft/profile builders (torso, limbs, joints, hands, boots, heads, costume shells)
- Construction: `profile_loft_no_voxel_remesh`
- Digital no-remesh: PASS
- Masters ok: True

## C body surface: digital=PASS visual=FAIL / pending

## D Ember

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 1989
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/11

## E Rook

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 2271
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/11

## F Juno

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 1728
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/10

## G Kaia

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 1736
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/11

## H Nix

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 1828
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/9

## I Orion

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 2196
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/10

## J Vesper

- construction: profile_loft_no_voxel_remesh
- used_voxel_remesh: False
- triangles: 1778
- packet_complete: True missing=[]
- hand/boot/head/costume parts: 5/4/4/12

## K hands: digital=PASS visual=FAIL / pending
## L boots: digital=PASS visual=FAIL / pending
## M heads: digital=PASS visual=FAIL / pending
## N costume shells/coverage: digital=PASS visual=FAIL / pending/FAIL / pending
## O materials: FAIL / pending
## P deformation: FAIL / pending
## Q animation retarget: same 22-bone rig, sockets, action IDs; v5 hero overlays on idle/charge/hurt/super/clash
## R heavy/hurt: FAIL / pending / FAIL / pending
## S charge: FAIL / pending
## T super: FAIL / pending
## U clash acting: FAIL / pending
## V review packet: artifacts/vxp3/review/generated_art_v5/ FRONT_CAMERA_CORRECT=7/7

## W v5 gates

- VISUAL_REMESH_TOY_REMAINING: True
- WAVE014: PASS
- WAVE020: PASS
- HUMAN_*: all false
- MERGE_AUTHORIZED: false

## X exact-head CI: Wave014/Wave020 remain green on the previous exact head. This v5 push will re-run exact-head CI; Wave015 was already failing on 56afa57. APK is forbidden until stills stop reading as remesh toys and required exact-head CI is green.
## Y APK/Pixel: Not eligible. File forbids APK until v5 stills stop reading as remesh toys and exact-head CI is green.

## Z remaining defects / next action

v5 replaced voxel remesh with profile loft + costume shells. Torso coverage and per-fighter proportions are materially better than v4 remesh toys, and FRONT cameras stay 7/7. Stills still read as low-poly mannequins: mitten/nub hands, slab/cup boots, faceted heads, Nix value-collapse to a white dummy, and boot-detail cameras often miss the feet. Visual-craft gates stay false. Not Q3-like generated character craft. Not APK-eligible. Not merge authorized.

Next human step: Open artifacts/vxp3/review/generated_art_v5/ front/hand/boot/silhouette sheets. Do not set HUMAN_* or MERGE. Do not install an APK. Next agent pass should thicken designed fists (thumb/knuckle readable at gameplay scale), lock boots to ankles with soles on the ground, and split Nix costume/body values.

