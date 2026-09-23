# Generated Production Art Rescue v2 — A–Z

Draft PR #106. Do not merge. Not human-authored final art. RC1 `v1.0.0-rc.1` untouched.

## A — new head / base

- PR: https://github.com/gunnchOS3k/anime-aggressors/pull/106
- Branch: `vxp/vxp-3-combat-impact-nix-rook`
- Start head: `3fc912af385bf40aebff018b2b851de3ec1f3c1e`
- Base / accepted main: `6cd1b3100a7e467c2c991394576891660deb1162`
- This rescue adds a new commit on the same draft branch (head SHA after push)

## B — generator v2 architecture

Volumetric construction → voxel remesh → smooth/decimate → nearest-bone material regions → Blender automatic weights.

- Canonical 22 deform bones kept
- Optional twist bones `TwistArm_*` / `TwistLeg_*` with local copy-rotation
- Fighter accessory bones kept and moved closer to attachment
- Required sockets exported as empties
- Costume/VFX classified (`BODY`/`CLOTHING`/`ARMOR`/`SECONDARY_MOTION`/`ELEMENTAL_ORBIT_VFX`)
- Runtime GLB id preserved: `content/fighters/<id>/model/<id>_generated_production.glb`
- `GENERATOR_VERSION=2.0.0` / `cohesive_body_v2_remesh`

## C — Ember

Cohesive athletic body, ember-cap crest, attached mittens/boots, chest vent + flame tongues (VFX, attached). Forward idle, connected heavy punch, deep hurt fold, charge pose. 15100 tris.

## D — Rook

Widest tank mass, plate-helm void, attached chest/shoulder/back plates, heavy boots. Strongest silhouette. 19368 tris.

## E — Juno

Lean compact frame, arc-crown, attached volt panels/tag. Fastest visual read. 12436 tris.

## F — Kaia

Longer slim aerial frame. Scarf/ribbon attached at neck/head. Veil still soft. 11620 tris.

## G — Nix

Compact centered frame, crystal-facet head, attached crystals/gloves. 15251 tris.

## H — Orion

Taller authority frame, vest layer attached, orbit ring as `ELEMENTAL_ORBIT_VFX`. 14725 tris.

## I — Vesper

Asymmetric idle, smoke-cowl head, coat volumes attached at hips. 13061 tris.

## J — topology counts

| Fighter | Tris | Islands | Foot gap |
| --- | --- | --- | --- |
| ember-vale | 15100 | 1 | 0.0 |
| rook-ironside | 19368 | 1 | 0.0 |
| juno-spark | 12436 | 1 | 0.0 |
| kaia-windrow | 11620 | 1 | 0.0 |
| nix-calder | 15251 | 1 | 0.0 |
| orion-vell | 14725 | 1 | 0.0 |
| vesper-nyx | 13061 | 1 | 0.0 |

Target 12k–35k. Clean remesh, no zero-area dependency.

## K — body connectedness

All seven: `body_connected_components=1`. Neutral and hero poses no longer show exploded-doll gaps.

## L — floating-accessory audit

`artifacts/vxp3/reports/FLOATING_ACCESSORY_AUDIT.json`

`UNINTENTIONAL_FLOATING_ACCESSORIES=0`

Orion orbit ring is the only intentional float (`ELEMENTAL_ORBIT_VFX`).

## M — skinning

Automatic blended weights. Zero-weight body verts = 0. Twist bones present. Not human weight-paint. Extreme poses can still squash.

## N — deformation

Sheets: `artifacts/vxp3/review/deformation_v2/<id>/`

Overhead / punch / twist / crouch / run / jump / heavy / hurt / charge hold as one mesh. No joint separation. Some shoulder squash.

## O — materials

Principled + cheap rim/emission toon stack. Body/cloth/secondary/accent/hair/charged slots. Pixel-readable, no texture soup. Godot import stays principled.

## P — action retarget

Same canonical skeleton; 113 generated actions rewritten onto the new cohesive mesh. No resolver id change.

## Q — heavy / hurt visual strength

Heavy contact is a connected punch silhouette. Hurt-heavy is a full-body fold/recoil before the later launch keys. Still generated motion, not human acting.

## R — charge

`charged_idle` / charge 100 stills show a wider stance and raised-arm focus pose. Head posture helps sell charge. Not a Super-Saiyan parody.

## S — secondary-motion attachment

Kaia scarf/ribbon attached. Vesper coats attached at hips. Rook plates attached. Ember flames attached as VFX. Orion orbit tracked as VFX.

## T — review still paths

- `artifacts/vxp3/review/generated_production/<id>/` — idle, personality, walk, run, dash, charge_100, heavy family, hurt-heavy, aura, super, KO, close_body_3q, silhouette, costume_detail, deformation_stress
- `artifacts/vxp3/review/deformation_v2/<id>/`
- `artifacts/vxp3/review/generated_production/roster/roster_compare.html`

## U — quality classification

See `GENERATED_PRODUCTION_QUALITY_V2.json`. Roster **Q2+**. Exploded mannequin defect removed. Not finished anime. Not Q4. No art-director sign-off.

## V — exact-head CI

Local digital checks run on this worktree (recipe unit test, geometry v2, exaggeration). Exact-head GitHub CI is whatever the new pushed SHA reports. Do not claim green while pending.

## W — APK

Not built. Owner-review APK waits for exact-head CI green plus owner look at stills. Target would be `anime-aggressors-generated-art-v2-owner-review.apk`. RC1 not touched.

## X — Pixel install

Not run. No `adb install -r` this pass.

## Y — gate states

| Gate | Value |
| --- | --- |
| GEN_ART_V2_COHESIVE_BODY_ROSTER_PASS | true |
| GEN_ART_V2_NO_BODY_GAPS_PASS | true |
| GEN_ART_V2_NO_FLOATING_ACCESSORY_PASS | true |
| GEN_ART_V2_HAND_FOOT_HEAD_READ_PASS | true |
| GEN_ART_V2_COSTUME_ATTACHMENT_PASS | true |
| GEN_ART_V2_SMOOTH_SKINNING_PASS | true |
| GEN_ART_V2_DEFORMATION_ROSTER_PASS | true |
| GEN_ART_V2_SILHOUETTE_ROSTER_PASS | true |
| GEN_ART_V2_MATERIAL_READ_PASS | true |
| GEN_ART_V2_ANIMATION_RETARGET_PASS | true |
| NO_OBVIOUS_BLOCKOUT_DEFECTS | true (exploded mannequin removed; stills are cohesive remesh figures) |
| GENERATED_PRODUCTION_MODEL_ROSTER_PASS | true (automated v2) |
| GENERATED_PRODUCTION_ART_PASS | true (automated v2 only) |
| HUMAN_AUTHORED_ART_PASS | false |
| HUMAN_AUTHORED_ANIMATION_PASS | false |
| HUMAN_ART_DIRECTION_APPROVAL | false |
| HUMAN_ANIMATION_QUALITY_PASS | false |
| HUMAN_COMBAT_FEEL_PASS | false |
| HUMAN_AURA_CLASH_PASS | false |
| HUMAN_CLIP_WORTHY_PASS | false |
| MERGE_AUTHORIZED | false |
| FINAL_AUTHORED_ANIMATION_PASS | false |

## Z — remaining visible defects / next human step

Remaining:

1. Figures are still smooth remesh toys, not finished anime costumes/faces (faceless is canonical; costume language is still soft).
2. Hands are mitten blobs; heads are designed volumes but simple.
3. No Pixel install / owner-review APK this pass.
4. Blend masters stay gitignored until LFS remote auth exists.
5. Owner questions 1–12 unanswered.

**Exact next human step:** Open PR #106 stills — especially `idle`, `close_body_3q`, `heavy_contact`, `hurt_heavy`, `charge_100` for all seven, plus `deformation_v2`. Answer whether these cohesive remesh bodies are acceptable generated art for this release before later human-art upgrades. Do **not** set HUMAN_* / MERGE_AUTHORIZED until that answer. Then, only if exact-head CI is green, export/install `anime-aggressors-generated-art-v2-owner-review.apk` with `adb install -r` (do not uninstall, do not touch RC1).
