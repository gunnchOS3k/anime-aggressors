# Authored guard and contact integration review

Implemented: jab_1 and heavy_attack now load from and return to the existing
fighter-specific neutral guard. The old boundary displaced Kaia/Juno's striking
wrist8.25–10.06cm and changed pelvis height abruptly. New entry/late-settle keys
are baked on all18existing rigs/bothfacings (72clips); no new runtime solver.
The active intervals are byte-identical, the whole hook arcs/reactions and all
other clips unchanged. Original hip lead, ribcage/arm delay and attack timing
remain. This is a narrow continuity improvement, not finished choreography.

Play `tools/v1_closure/play_melee_review.command` (active Juno CPU).
Optional `--local` for two players or `--male` for both male presentations.
Relaunch to load new source. Separate review identity; owner Story saves untouched.
Kaia:A/D move,J light,J+K heavy,L shield,W jump,I dodge,U grab.
Juno local:arrows move/up jump,M light,M+comma heavy,period shield,slash dodge,
semicolon grab. Direction+attack during grab throws. Pause between first lights
to compare the straight jab; the existing second-press hook is preserved.
Compare preparation and return to guard, then shield/dodge/jump/grab and retreat.

Normal-speed native BEFORE: `../../rendered/body_spacing_after1020.mp4`
exacte42655d5657ecbf1a4a8750e7c9be89ea35d29db. Its gameplay scripts/data are
identical tob45a7a36; reused without recapture.
AFTER: `../../rendered/contact_integration_after1020.mp4`, exact
9d291e7b599271b54eafe1a32d1d6084716f1608 (same authored data0b36d69f).
Both868frames/14.467s60fps, native game audio,647matched framecodes;31identical
input transitions. Same6contacts, frames, world positions, damage and launch.
GUARD_COMPARISON.png and JUNO_GUARD_COMPARISON.png are unretouched2x fixed crops;
full-stage movies remain primary. Native per-event before/contact/after sheet,
source/audio/frame/hash verification: `native_after_foreground/`.
These are two automated active local controllers, not CPU/human acceptance.
Fixed60fps recording is not sustained physical-device FPS. Original project
assets/audio: owner development review only, no release/distribution authority.
First native attempt had125stale rendered frames; excluded and preserved under
`native_after/` and protected local_media/contact_integration_after1020.avi.
Only the explicit foreground retry qualifies. No raw footage deleted.

Engineering validation: GuardContinuity72, full CombatChoreography864,
GroundedRecovery36, ContactReactionClock18, ThrowOwnership39, AuthoredCancel9
PASS. No script errors; pre-existing resource-at-exit diagnostics persist in
some fixtures. `affected/RESULTS.json` is the exact serial ledger.
340frame activeCPU before/after:9contacts/4CPU attacks each, same contact frames,
damage and velocity; no frozen opponent, forced move/KO or gameplay alteration.
Close inputs retain32.40px neutral roots, shield, authored hook, lights/heavies,
ordinary dodge/jump crossing and one direct throw. Whiff has no contact burst.
Outer ordinary two-controller attempt:3real contacts at~70.7–71.2px spacing,
shield and two heavy counters. This is actual input gameplay, not a seeded
geometry target. It exposes remaining visual misses, not accepted outer reach.

## Exact remaining authored/projection work

The native comparison still shows a small guard/recovery change, with much of
Kaia's arm obscured by overlapping projected bodies. It does NOT establish the
requested large improvement in physical combat. Projected head/hair/torso overlap
and floor fit remain obvious. Do not add another small solver/offset to hide it.

Current measured sole error:Kaia35.27px,Juno38.12px below physical collider floor.
Outer hand-surface gaps:Kaia jab/shield17.63px,Juno heavy12.49px,Kaia heavy14.86px.
Close tested melee hand hulls overlap the actual contact regions (0px gap).
These are surface/authority diagnostics, not final art approval thresholds.

Work in preserved `art_source/collectible_v1/{kaia-windrow,juno-spark}/{male,female}/candidate.blend`
and the matching preserved BASE.glb rigs; do not regenerate/rescale characters.
Required assets: original full-body guard/anticipation/strike/recoil/settle clips
with intentional hip/shoulder chain, support-foot switches and a plausible outer
strike silhouette. Validate weighted boot soles (not ankle joints), head/hair
clearance and visible palm against the shared orthographic projection at actual
body spacing. Bake/retarget through the existing combat_choreography/performance
pipeline, retaining canonical proportions and resolved active/cancel frames.

Coordinate authority is unchanged:CharacterBody2D stage shape owns physical
support; the hurt region is48px high while the current projected core is~139–142px.
Camera3D→256x320SubViewport→ModelDisplay (0,-56),scale.68→worldCamera2D projects
skin. Previous whole-display shift repaired soles but created13–27px typical
strike gaps; it remains rejected. Authored floor/contact poses and approved
framing must be designed together. Any necessary competitive geometry change
requires a separate explicit decision; none is made here. Hair is largely bound
to Head and the existing accessory follow is limited, so independent authored
secondary controls/weights are also unfinished source-art work.

No new runtime contact/spacing defect reproduced in these bounded tests. Complete
floor/reach/acting acceptance is blocked on coordinated authored art/projection,
not missing particles or another pushbox pass. Next independent existing V1 task:
wire/verify Yin and Yang's established distinct authored competitive kits against
their bibles, preserving balance/design gates. Do not begin it in this increment.
Seven earned Story routes/Convergence, continuous Kaia OVA/six variants, genuine
multiplayer and platform/device acceptance remain unfinished separate work.

All human art/game-feel/VFX/animation/SFX/V1 and final-release gates remain false.
Draft123 stays stacked122. No merge/tag/deploy/release, heavy export or cleanup.

October 21 recovery: existing video/raw/contact-sheet hashes and stream metadata
were rechecked without recapture. All 7 CI checks passed on exact source9d291e7b.
Current storage is below the 18 GiB reserve; no new render or export was run.
The recorder now reserves18GiB plus all anticipated raw/derivative allocations;
10 guard tests pass, preserving the original process/partial-file protections.
Historical movie receipts retain their original October20 storage policy.
