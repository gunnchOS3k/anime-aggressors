# ANI-03 bounded production and combat-rule backlog

All acceptance gates remain false. These are local engineering tickets, not published issues. Source paths are repository-relative; evidence is under this package. No competitive parameter was tuned in reconciliation.

| ID | Classification | Status / priority |
| --- | --- | --- |
| ANI03-T01 | Independently reproduced gameplay defect | Blocking competitive throw/KO acceptance; next increment |
| ANI03-T02 | Engineering evidence gap | Competitive KO native proof after T01 |
| ANI03-T03 | Engineering evidence gap | Medium/high ground/air/projectile and defense/recovery coverage |
| ANI03-P01 | Authored animation production | Foot planting and contact mechanics |
| ANI03-P02 | Authored animation production | Recovery, reactions, transitions, secondary motion and cosmic bosses |
| ANI03-R01 | Combat-rule design decision | Projectile/terrain interaction |
| ANI03-R02 | Combat-rule design decision | Parry/clash authority |
| ANI03-P03 | Art/human review | Effect scale, launch readability and sound mix |
| ANI04-P01 | Acting/cinematic production | Continuous Kaia OVA and six variations |
| ANI05-T01 | Platform/device evidence + human review | Safe exact-source exports and device acceptance |

## ANI03-T01 — prevent duplicate direct-throw contacts

Reproduction is already preserved: `combo_probes/juno-spark_edgeguard-throw_high/combat_capture.json`, source `967414087b74191fde411b95da5281c85b2c9c72`, public walk/grab/throw against CPU level 3; explicit initial opponent percent 110. One throw_back starts at movie frame 500. Its contacts occur at 500 (move frame 0), 507 (frame 4) and 509 (frame 5), with damage before 110 → 115.75552 → 121.51104. The manifest declares no hitboxes or multi-hit throw. No result, position, velocity or damage was assigned by the driver after setup.

Root path: `fighter.gd:execute_throw()` resolves once immediately, then `_on_move_active()` sets THROW_RELEASE and falls through into generic hitbox activation using the prior grab box. `hit_resolver.gd:resolve()` exempts direct throws from `MoveRunner.can_hit_target()`, so each overlapping active callback resolves again. Event IDs differ; renderer dedupe correctly cannot repair gameplay ownership.

Next implementation: give direct throw one resolution owner; disable/return before generic melee overlap activation for throws, and ensure `_poll_hitbox_overlaps()` cannot resolve an already released direct throw. Preserve authored damage/startup/active/recovery and the release timing unless a separate timing defect is proven. Add a meaningful actual grabbed-target fixture for all four directions and nine fighters asserting exactly one damage application, one contact event, correct shield/armor rejection policy, no repeated audio/VFX and no stale hitbox. Do not solve it by weakening opponent AI or adding invincibility.

Validation required after this gameplay fix: targeted throw/interrupt/combat feedback, fresh/restart Story receipt behavior (ordinary Kaia uses throws), full campaign/save/roster regressions where affected, then one bounded edgeguard attempt using a new label. Do not rerun the successful nine-fighter video campaign. Fixing unintended duplicate damage changes observed buggy totals, so the effect on prior receipts must be tested rather than assumed.

## ANI03-T02 — qualify competitive stock loss and finishing feedback

The bounded T01 reproducer did cause an actual Ember CPU stock loss at movie frame 567 (stocks 9→8) and kind-7 Juno finishing event at process frame 568. It is headless and defect affected: `COMPETITIVE_KO_ATTEMPT.json`. This proves an authentic gameplay event, not fair competitive KO acceptance. The earlier native Story NPC stock loss remains separately scoped.

After T01, use next unused label `ember-vale_edgeguard-throw_high` via `python3 tools/v1_closure/probe_spectral_combos.py ember-vale_edgeguard-throw_high`. It runs one 900-frame public-input attempt. If contact/stock loss is qualified, record only its missing native 60 fps counterpart, preserving CPU actions, pre-contact/release/launch/recovery/stock-loss frames and synchronized original audio. If it fails, retain failure and report it. Match-ending victory at stock zero is separate from a single stock loss.

## ANI03-T03 — medium/high combo and counterplay matrix

`COMBO_COVERAGE_AUDIT.json` preserves six initial-percent groups and 71 missing native cells. Existing thirty core probes cover only Ember/Juno. Ember medium/high produced no genuine pair; Juno medium produced none, high one. Recorded shields/recovery are valid counterplay, not test failures to erase. Actual move pairs must be reported separately from a recipe that later loops light attacks.

Next tool extension: allow explicit roster selection and new probe labels for only missing fighter/band/class cells; keep default resume from launching a new campaign. Run at most two short missing cells per increment at 0/50/110 setup. Observe exact hitstop, landing, first actionable frame, next activation/contact and shield/escape actions. Throws cannot count as combos from release HITSTUN snapshots: execute_throw enters HITSTUN before the resolver snapshot, so that flag alone is insufficient. Observe defender state before grab/connect and separate capture from hitstun combo acceptance. No balance tuning or forced outcomes.

## ANI03-P01 — authored stance, foot planting and contact mechanics

Review current `rendered/ember-vale_active_low.mp4` and `juno-spark_active_low.mp4`, with contact sheets. Existing 216 pose studies under `game-godot/data/animation/authored_studies/` establish distinct candidates but do not prove planted feet, full-body mechanics or final technique. Work through `fighter_animation_controller.gd`, existing Blender/animectl/rig contracts and the nine identities in ROSTER_MOTION_IDENTITY_BIBLE.md. Begin with light/heavy/projectile preparation→contact→follow-through→recovery for Ember and Juno; apply the same matrix to all nine and both presentations. Use original authored keys or verified motion sources, no model restart.

Acceptance evidence: visible supporting foot stays planted or deliberately steps; pelvis/torso/shoulder chain drives the strike; attack silhouette reaches the real contact region on the active frame; recovery/cancel remains responsive at existing frame data. Render normal/slow real inputs and misses against active CPU. Human motion taste stays false until owner acceptance; clip-name difference is not proof.

## ANI03-P02 — transitions, impact recovery and secondary motion

Use existing hurt/facial paths and hitstop synchronization. Refine light/heavy recoil, tumble, land→control, blocks, grabs, aerials, victory/defeat and movement transitions on existing rigs. Add bounded original hair/cloth/armor follow-through without hiding silhouettes. Define distinct cosmic boss choreography for Yin/Yang separately from their competitively equal playable presentation. Reproduce from current representative clips; validate contact/recovery state timing and body variants. This is authored production, not a missing collision/AI blocker.

## ANI03-R01 — decide projectile terrain authority

Reproduce by launching a normal projectile toward Training Grid floor/platform: `scripts/combat/projectile.gd` sets collision_mask=6, while terrain uses layer 1. `_on_body_entered` is wired, but existing terrain is excluded. Decide which projectile classes stop, pass through, detonate or dissipate at floor/wall/edge and whether that changes match strategy. Keep the current mask until that rule is explicitly designed; do not silently alter balance to obtain a terrain demo. Then test each approved class/fighter with one collision/dissipation, no fighter damage from scenery and cleanup on cancel/scene exit.

## ANI03-R02 — define parry/clash gameplay before presentation

Current HitResolver explicitly reports parry_supported=false and clash_supported=false. Shield and armor work; no real parry/clash result exists to render. Define input/window/cost, priority, simultaneous collision authority, deterministic resolution and fair recovery first. This is a combat-rule decision, not an absent shader sprite. After authorization, attach distinct original feedback to actual outcomes and add miss/block/parry/clash tests. No current gate may claim these outcomes.

## ANI03-P03 — effect readability and mix review

Use existing hit/shield/whiff sheets, full charge clips and slowed true pairs. Evaluate directional silhouette, rapid clearing, launch wake at actual velocity, fire/electric character and reduced-flash/density/high-contrast settings. Native trace-to-visible mesh may lag one/two process frames; waveform audio median offset is 20.8–26.8 ms with ~5.34 ms residual. These are measured findings, not final approval. Refine presentation without altering hitboxes, launch or frame data. Review the prior matched-loudness audio A/B assets; preserve strong punch sounds and facial responses. Owner taste/mix/game-feel decisions remain separate from engineering pass results.

## ANI04-P01 — authored OVA/acting

Retain one continuous Kaia OVA plus six variations, the 145/1,025 cue data and Juno/Orion direction. Schedule acting, facial/lip sync, camera/cinematic animation and professional voice replacement/rights as production. Current temp formant speech and voiced Story videos remain local-only; final dialogue/audio/art approval is unearned. Do not present runtime hooks or screenplay coverage as completed authored OVA.

## ANI05-T01 — safe platform/device closure

Twelve source suites and exact-b7 eight CI jobs passed, including Windows build pilots; they do not certify Windows/Web/Android/Pixel game feel, audio mix or device performance. Disk is about 5.1 GiB, below the 18 GiB heavy-export guard. Obtain safe disk capacity and run exact-source platform/device review in a later increment. Do not delete worktrees/backups for space or bypass human acceptance. No merge, deployment, tag, publication or V1-complete declaration.
