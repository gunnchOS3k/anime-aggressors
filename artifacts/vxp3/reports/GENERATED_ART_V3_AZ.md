# Generated Art v3 A–Z

Generated production art only. Not human-authored final art. Do not merge.

**A new head:** `e44258549698332f7815ae79e30fe3a81066fad8`
**PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/106
**Base:** `6cd1b3100a7e467c2c991394576891660deb1162`
**RC1:** `v1.0.0-rc.1` untouched

## B generator-v3 changes

- Versioned shape profiles at `game-godot/data/art/generated_v3/fighter_shape_profiles.json`
- Body core remesh stays one island; designed heads/hands/boots/costume attach after remesh
- 2–3 band toon materials with rim + accent emission
- Fighter-specific idle/walk/heavy/hurt/charge/super poses

## C Ember art result

- class: Q3-like (digital only)
- head: ember_crest_heat_mask
- boots: heat_resistant
- hands: fist strength=1.22
- tris: 12535 islands=1 gap=0.0
- note: Digital structural score only. Not human art-direction approval.

## D Rook art result

- class: Q3-like (digital only)
- head: plate_helm_void
- boots: armored_heavy
- hands: fist strength=1.3
- tris: 16281 islands=1 gap=0.001
- note: Digital structural score only. Not human art-direction approval.

## E Juno art result

- class: Q3-like (digital only)
- head: arc_crown_cap
- boots: speed_shoe
- hands: open strength=0.86
- tris: 10524 islands=1 gap=0.0
- note: Digital structural score only. Not human art-direction approval.

## F Kaia art result

- class: Q3-like (digital only)
- head: ribbon_veil
- boots: aerial_boot
- hands: open strength=0.84
- tris: 10488 islands=1 gap=0.001
- note: Digital structural score only. Not human art-direction approval.

## G Nix art result

- class: Q3-direction (digital only)
- head: crystal_facet_mask
- boots: frost_geometric
- hands: guard strength=1.04
- tris: 12941 islands=1 gap=0.0
- note: Digital structural score only. Not human art-direction approval.

## H Orion art result

- class: Q3-like (digital only)
- head: authority_orbit_halo
- boots: cosmic_layered
- hands: open strength=1.02
- tris: 14394 islands=1 gap=0.001
- note: Digital structural score only. Not human art-direction approval.

## I Vesper art result

- class: Q3-like (digital only)
- head: smoke_cowl_void
- boots: asymmetric_narrow
- hands: guard strength=0.94
- tris: 10870 islands=1 gap=0.0
- note: Digital structural score only. Not human art-direction approval.

## J hands results

- Rook/Ember stronger than Juno/Kaia: True
- hierarchy: {"ember-vale": 1.22, "rook-ironside": 1.3, "juno-spark": 0.86, "kaia-windrow": 0.84, "nix-calder": 1.04, "orion-vell": 1.02, "vesper-nyx": 0.94}
- gate: PASS

## K feet results

- designed boots per fighter, ground gap gate: PASS

## L head-design results

- seven unique abstract heads: PASS

## M costume-craft results

- attached designed plates/panels: PASS

## N silhouette results

- digital uniqueness: PASS worst=21.085
- human/owner silhouette approval: false

## O materials results

- 2–3 band toon: PASS

## P heavy-contact results

- gate: PASS

## Q hurt results

- gate: PASS

## R charge-body results

- body-read without VFX: PASS

## S super-pose results

- unique supers: PASS

## T design-sheet paths

- `artifacts/vxp3/review/generated_art_v3/design_sheets/<fighter>/`
- packet: `artifacts/vxp3/review/generated_art_v3/<fighter>/`
- sheets gate: PASS

## U v3 gate matrix

- GEN_ART_V3_HANDS_PASS: True
- GEN_ART_V3_FEET_PASS: True
- GEN_ART_V3_HEAD_DESIGN_PASS: True
- GEN_ART_V3_COSTUME_CRAFT_PASS: True
- GEN_ART_V3_SILHOUETTE_PASS: True
- GEN_ART_V3_MATERIAL_PASS: True
- GEN_ART_V3_HERO_POSE_PASS: True
- GEN_ART_V3_HEAVY_CONTACT_PASS: True
- GEN_ART_V3_HURT_POSE_PASS: True
- GEN_ART_V3_CHARGE_BODY_READ_PASS: True
- GEN_ART_V3_SUPER_POSE_PASS: True
- GEN_ART_V3_DESIGN_SHEET_PASS: True
- GENERATED_PRODUCTION_ART_PASS: True
- HUMAN_AUTHORED_ART_PASS: False
- HUMAN_AUTHORED_ANIMATION_PASS: False
- HUMAN_ART_DIRECTION_APPROVAL: False
- MERGE_AUTHORIZED: False
- FINAL_AUTHORED_ANIMATION_PASS: False

## V quality classification per fighter

- ember-vale: Q3-like mean=0.961 (digital only)
- rook-ironside: Q3-like mean=0.925 (digital only)
- juno-spark: Q3-like mean=0.956 (digital only)
- kaia-windrow: Q3-like mean=0.927 (digital only)
- nix-calder: Q3-direction mean=0.858 (digital only)
- orion-vell: Q3-like mean=0.912 (digital only)
- vesper-nyx: Q3-like mean=0.928 (digital only)

- roster: Q3-like
- finished_anime: false

## W exact-head CI

- reported after push; do not claim green while required workflows are pending

## X APK path/SHA if eligible

- APK not built. File forbids owner-review APK until the visual-craft pass and exact-head CI are complete.

## Y Pixel install result if available

- skipped; no APK

## Z remaining defects / owner questions

Visible remaining defects (honest, from stills — not owner taste):
- Torsos still remesh-smooth; designed parts are blocky add-ons, not a finished sculpt
- Review cameras often sit behind the fighter (Rook/Orion/Vesper idle read as rear mannequin)
- Ember still has a small detached flame-tongue bit in silhouette
- Hands read as beveled blocks, not fully articulated stylized hands
- Costume plates are attached but still thin/secondary versus the nude remesh body
- Digital Q3-like is structural scoring only. Visible read is generated blockout / Q3-direction pending owner
- APK withheld: exact-head CI is not on this new head yet, and obvious generated-blockout language remains

1. Do these look like intentional game characters rather than remesh toys?
2. Are the abstract heads designed enough?
3. Do hands/feet look intentional?
4. Are costumes readable and character-specific?
5. Can you distinguish all seven in black silhouette?
6. Does each fighter have a unique body language?
7. Do heavy attacks look painful?
8. Does hurt acting read before knockback?
9. Does charge 100 transform the body, not just VFX?
10. Are supers screenshot-worthy?
11. Does Aura Clash feel dramatic?
12. Is this generated art acceptable to ship for this release before future human-art upgrades?

Human gates stay false until the owner answers.

masters_ok: True

