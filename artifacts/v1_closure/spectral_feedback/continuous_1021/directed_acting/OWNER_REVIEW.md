# ANI-05-R directed acting — source increment ready for gameplay review

Tested runtime source: `52872c4fa05d85361d285b0155ed20e42623674b`, pushed to
`release/anime-v1-dialogue-and-elemental-performance`. [Draft PR123](https://github.com/gunnchOS3k/anime-aggressors/pull/123)
remains stacked on draft122. The following delivery commit contains reports only.
All 33 worktrees, original artwork, owner saves and failed attempts are retained.
`VISUAL_VERIFICATION_PENDING=true`; all human, balance and release gates remain false.

## What changed in the recovered source

The interrupted 17-action set was preserved and completed to **32 WIP actions per
original Kaia/Juno rig**, covering both body presentations. These are 128 baked
actions including mirrors and body retargets, not 128 unique finished performances.
Kaia uses open palm/body arcs; Juno uses compact coils, diagonal extension and snap
recoil. The actions coordinate pelvis, torso, shoulders, wrist orientation, knees
and soles. Light and heavy poses differ. Existing hook arcs remain intact.

The four source files are:

- [Kaia male](../../../../../art_source/collectible_v1/kaia-windrow/male/candidate.blend)
- [Kaia female](../../../../../art_source/collectible_v1/kaia-windrow/female/candidate.blend)
- [Juno male](../../../../../art_source/collectible_v1/juno-spark/male/candidate.blend)
- [Juno female](../../../../../art_source/collectible_v1/juno-spark/female/candidate.blend)

Each contains `ANI05_WIP_` actions for jab, heavy, side special, projectile,
grab, four directional throws (each with a left-facing version), idle, shield,
charge, jump, soft/hard land, light/heavy/elemental hurt, walk/run/dash, KO and
defeat. [Exact names, paths and source hashes](VALIDATION_REPORT.json) are recorded.
Meshes, skin weights, rest bones, mesh object transforms and all 147 original
actions per file remain hash-protected. No shipping GLB was replaced.

Two non-deforming sole reference empties per rig identify the original weighted
boot surface. They are reference markers, not a finished animator-facing IK or
foot-roll rig. Hair remains Head-bound; independent hair/cloth controls and
weighting still require original asset work.

Saved Blender actions now export directly into the existing bone-local animation
JSON resources. All four saved files were read back and evaluated: **3,584 frames**,
maximum matrix-component discrepancy **3.76e-6**. This is numerical source/runtime
agreement, not a visual-quality measurement. No model/GLB export was needed.

`fighter_animation_controller.gd` respects `posture_authority: source_clip`, so
the legacy grounded-strike correction cannot overwrite these authored body
chains. Legacy clips retain their previous posture behavior. Movement distance,
move timing, throw release, root spacing, hitboxes, damage, projectiles, Story,
saves and Yin/Yang mechanics are unchanged. Other seven fighters' animation data
is preserved; this increment does not claim their final acting is complete.

## Corrected stance phase and remaining transition work

The original failed phase measurement is retained in `category_checks/`.
The established convention is restored: left support in the first cycle half,
right support in the second. Both facings, both bodies and walk/run/dash strengths
were measured in 24 public-input cases, including neutral/start transitions.

| Measurement | Kaia | Juno |
| --- | --- | --- |
| Mean slip across complete measured cases, px/frame | 0.00094–0.08469 | 0.00205–0.07073 |
| Mean steady-gait slip, px/frame | 0.00103–0.01030 | 0.00220–0.01299 |
| Largest observed start-transition spike, px/frame | 1.71305 | 1.24848 |

Final exported source-space stance path error is at most **5.77e-7 m**. Forward
knee and mirrored support metadata checks pass. Start weight transfer still
produces the reported spikes; a generic footwork PASS is not perfect foot planting
or a finished start/stop/pivot performance. [Per-case measurements](STANCE_ANALYSIS.json)
retain transition context without inventing a visual passing threshold.

## Final validation and its limits

[Final exact-source results](final/RESULTS.json): **14/14 PASS** — DirectedSourceAssets,
MeleeGuardContinuity, StrikePostureConstraints, SupportKneePlane, GroundedRecovery,
ContactReactionClock, CombatChoreography, ThrowOwnership, ChargeContinuity,
AuthoredCancel, CosmicKits public interactions, RosterFootwork, TerminalBodyActing
and ProjectileFighterImpact. Shared suites include nine-roster compatibility;
all 18 shipping model paths load. Footwork's explicit trace covers the four changed
rigs. Terminal presentation tests do not constitute an earned competitive KO.
Some fixtures retain resource-at-exit warnings; this is not leak-free certification.

[Playable checks](playable/RESULTS.json): both body launchers pass. One bounded
900-frame headless public-input observation recorded 52 input transitions, eight
Kaia hits and six shield contacts against active CPU Juno. Juno attempted 20 moves,
but did not hit the player. No KO, forced move, frozen opponent, damage override
or Story reward was used. This is not a human playthrough, a guaranteed-combo
claim, a native movie, audio acceptance or sustained device frame-rate evidence.

[Failed/partial attempt ledger](ATTEMPT_LEDGER.json) preserves the initial source
matrix-conversion failure, mirrored metadata failure, reversed gait measurement
and initial sandbox-limited run. They are superseded, not relabeled as passes.
Long historical Story/campaign tests were not repeated: their authority files
are unchanged, and their original source-bound results retain their limits.

[CI snapshot](CI_52872c4f.json) records the exact tested source. Check the current
PR for later delivery-head results; a pending Windows 2025 job is not a pass.

## Owner-controlled gameplay review

Close older review windows. From this existing worktree, launch one game at a
time, subject to the normal storage/runtime preflight:

```sh
tools/v1_closure/play_melee_review.command
tools/v1_closure/play_melee_review.command --male
```

Use `--local` for two human-controlled fighters. Default is Kaia versus active
CPU Juno. Profiles are isolated; regular owner saves and earned Story progression
are untouched. There are no aura, victory or unlock grants and no automatic inputs.

- Kaia: A/D move, W jump, J light, J+K heavy, K special, L shield, I dodge, U grab.
- Juno in local mode: arrows/up move/jump, M light, M+comma heavy, comma special,
  period shield, slash dodge, semicolon grab.
- After a real grab, press a fresh attack with left/right/up/down to throw.
  Observe the original escape/counterplay rules. Cross sides to inspect both facings.

Review normal-speed walk/run/dash starts, neutral guard, approach, anticipation,
strike, real hit or shield, recoil and recovery. Compare both bodies and both
facings. Observe jump/land, charge, grab and throws; review KO/defeat only if a
genuine battle result occurs. Judge visible weight, feet, reach and silhouette,
not pose counts or fixture scores. Blender users can inspect the named WIP actions
on the preserved rigs; solo the selected action from the original NLA tracks.

No new native movie was generated. The preserved ANI-03 comparison has **868
frames / 647 matching codes**, original audio and its original source IDs
(before `e42655d5`, after `9d291e7b`). Its screenshots/movies predate ANI-05 and
show the original problems, not verification of the new actions.

## Open asset dependencies and next production milestone

The previously observed **35–38 px projected boot/floor gap**, **12.5–17.6 px
outer-contact gaps** and head/hair silhouette overlap remain visually unverified.
Source sole constancy does not calibrate the stage projection. No whole-model
translation, anatomical scaling, hitbox retuning, camera concealment or weakened
test was used. There are no newly certified visual closures.

Next: author start/stop/pivot transitions against the retained transient traces;
then review these source actions together with the unchanged shipping projection
when storage permits native evidence. Coordinated sole/leg/hip asset work and
independent hair/cloth controls/weights remain required. Remaining normals,
aerials, up/down specials and cancel transitions still need move-specific acting.

[Live storage snapshot](STORAGE.json) remains below **18 GiB plus anticipated
allocation**. Native captures, APKs, heavy exports and production renders are
deferred. No caches, backups, source or evidence were deleted or relocated.

Full nine-fighter acting and Yin/Yang balance review, seven genuinely earned
campaigns, Gray/Convergence, finished Kaia OVA plus six variants, genuine LAN,
Android/Windows physical-device acceptance and final human art/sound/gameplay
approval remain open. No V1 readiness, publication or release is authorized.
