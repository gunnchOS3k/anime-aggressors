# ANI-06 — authored transitions and grounded motion

Runtime source **125c18b07baea90d19efad63cc23e9de5f1aa998**, pushed to the existing
`release/anime-v1-dialogue-and-elemental-performance` branch. [Draft PR123](https://github.com/gunnchOS3k/anime-aggressors/pull/123)
remains stacked on draft122. The subsequent delivery commit contains reports only.
All 33 worktrees, owner saves, Blender backups and failed evidence remain intact.
`VISUAL_VERIFICATION_PENDING=true`; human, balance and release gates remain false.

## Implemented source and runtime changes

Four existing Kaia/Juno male/female `candidate.blend` sources now contain **18
new ANI06_WIP actions each**: nine transition types and their left-facing keys.
Original meshes, skin weights, rest skeletons, original 147 actions and completed
32 ANI05 actions per rig remain protected. Nothing was rebuilt; no GLB was exported.

- [Kaia male source](../../../../../art_source/collectible_v1/kaia-windrow/male/candidate.blend)
- [Kaia female source](../../../../../art_source/collectible_v1/kaia-windrow/female/candidate.blend)
- [Juno male source](../../../../../art_source/collectible_v1/juno-spark/male/candidate.blend)
- [Juno female source](../../../../../art_source/collectible_v1/juno-spark/female/candidate.blend)

The new actions are `ANI06_WIP_transition_` followed by `start`, `accelerate`,
`stop`, `reverse`, `pivot`, `dash`, `move_light`, `move_heavy` or `guard`, with
`_left` versions. [Exact source paths, action names and hashes](VALIDATION_REPORT.json)
are retained. The new `transitions_v1.json` directing scores sit beside the
existing per-character source scores. Kaia uses open-palm counterbalance and
flowing torso arcs; Juno uses compact coils, faster weight exchange and diagonal
snap. These are unapproved source performances, not final choreography.

Saved Blender actions export directly to existing runtime animation JSON. Full
readback covers **4,512 evaluated frames**, including retained ANI05 actions.
New source pelvis/torso/arm deltas compose with the existing distance gait and
existing support constraint. The original full-body ANI05 source-clip ownership
remains intact. There is no new runtime body-pose generator or IK solver.

The corrected gait clock preserves planted-sole distance when stride length
changes between walk/run/dash, and follows signed real displacement during
reversal braking. Neutral entry begins at a support-compatible phase. Movement
into light/heavy uses source anticipation within existing startup and retires
before active contact. Other seven fighters retain their legacy transitions.
All 28 of their body-specific choreography/performance resources are unchanged.

No movement speed, combat frame, damage, hitbox, root spacing, projectile,
Story/save, aura or Yin/Yang authority changed. Position and velocity were
identical in all **72** before/after public-input fixture traces.

## Measured improvements and unfinished transitions

The unchanged **24-case ANI05 footwork recipe** gives maximum ankle-projection
slip of **Kaia 1.71305 → 0.01980 px/frame**, **Juno 1.24848 → 0.04585 px/frame**.
Both bodies, both facings and three walk/run/dash input strengths are included.
This verifies a gait integration improvement, not rendered sole/floor fit.

The broader nine-category fixture retains mixed results. Peak planted-phase
ankle displacement below is in px/frame; samples exclude swing and facing-flip
frames. Movement-to-attack rows measure adjacent neutral/gait handoff frames,
not all attacking limb or stance motion. Complete raw traces retain those poses.

| Input sequence | Kaia before → after | Juno before → after |
| --- | --- | --- |
| Neutral → walk | 3.8344 → 0.0034 | 0.0047 → 0.0049 |
| Walk → run | 1.1606 → 0.0120 | 1.4635 → 0.0276 |
| Run → stop | 0.9239 → 1.4765 | 1.6416 → 0.3798 |
| Moving reversal | 5.5537 → 1.2105 | 5.4411 → 0.0413 |
| Neutral pivot | 2.0316 → 0.0150 | 1.2822 → 0.0170 |
| Dash entry | 7.0093 → 0.0161 | 7.9709 → 0.0192 |
| Movement/light handoff | 3.7016 → 2.0556 | 3.1660 → 4.2366 |
| Movement/heavy handoff | 2.9727 → 2.9727 | 5.0869 → 3.5793 |
| Guard return | 0.2737 → 0.2737 | 0.0231 → 0.0220 |

**Kaia stop replanting remains worse in this sample**, and Juno's light-attack
handoff has a larger adjacent-neutral peak. Heavy/guard improvement is not
universal. These rows remain unfinished, not accepted via generic PASS.
Per-case means, weighted soles, support errors and excluded facing-flip motion
are retained in [COMPARISON](COMPARISON.json) and [final measurements](FINAL_MEASUREMENTS.json).
No artistic passing threshold was invented. The comparison uses old292fd24d
scripts over unchanged shipping models/legacy clips; unused new resources are
present in that overlay, so it is not a full historical build.

## Validation and counterplay

**17/17 affected suites PASS** on the committed runtime source:
DirectedSourceAssets, AuthoredTransitions, RosterFootwork, MeleeGuardContinuity,
GroundedRecovery, StrikePostureConstraints, SupportKneePlane, RosterLanding,
ContactReactionClock, CombatChoreography, FighterBodySpacing, ThrowOwnership,
ChargeContinuity, ProjectileFighterImpact, CosmicKits public interactions,
AuthoredCancel and TerminalBodyActing. [Exact commands/results](final/RESULTS.json)
include shared nine-roster checks and all 18 model loads. All nine new transition
paths were observed on 72 body/facing cases. Both owner-launch smokes pass.
Some existing teardown-resource warnings remain; this is not leak-free approval.

One bounded active-CPU observation used ordinary approach, waiting/defense and
attacks, with no AI, damage, hitstun or outcome changes. Juno made **43 move
attempts, 15 body hits and two blocked contacts**; Kaia made 23 hits/17 blocks.
No KO occurred. The earlier zero-CPU-hit sample did not establish a general AI
failure; this changed-input observation confirms ordinary CPU hit capability.
The actual run is **1,800 frames with 300 periodic samples**, not an exact
900-frame trace (two initially supplied CLI flags were unsupported).
[Counterplay analysis](COUNTERPLAY_ANALYSIS.json) retains this limitation.

[Attempt ledger](ATTEMPT_LEDGER.json) preserves the missing-property baseline,
compile failure, source-only attempt that did not reduce slip, and first-callback
source metadata failures. None was erased or promoted to acceptance. [CI snapshot](CI_125c18b0.json)
records the exact source; query the latest delivery head separately, including
Windows 2025. No Mac/source check establishes physical Windows/Android acceptance.
Long unchanged campaign validations and prior media were not repeated.

## Original asset dependencies still open

No new native visual evidence was made. The previous **35–38px boot/floor
projection mismatch**, **12.5–17.6px outer-strike gaps**, and head/hair overlaps
remain **visually unclosed**. Existing ANI03 movies retain their original IDs;
they are not ANI06 evidence.

- Four collectible `candidate.blend` sources / weighted Boot meshes: the two
  sole reference empties are non-deforming references, not a finished foot-roll
  or animator-facing support rig. Phase-dependent stop/replant and movement-to-
  attack support exchanges still need authored lower-body keys and control work.
- Existing `fighter_model_3d.gd` Camera3D/SubViewport/display projection and the
  same source rig/strike clips require coordinated sole/hip/hand assessment in
  the shipping camera. No standalone whole-model offset, scaling or hitbox
  retuning was used. The new gait measurements do not solve that coupled fit.
- Original Head-bound Hair cap/Hair sweep/Face assets require independent hair
  controls/weights and authored head/torso silhouette clearance. No shrinking,
  cosmetic mask or camera trick was used. See the retained [asset-specific
  dependency plan](../cosmic_kits/ART_CLOSURE_PLAN.md).

## Owner-controlled review

Close older review windows. Run one game at a time from the existing worktree,
with the usual runtime/storage preflight and **no recording**:

```sh
tools/v1_closure/play_melee_review.command
tools/v1_closure/play_melee_review.command --male
```

Default is female Kaia versus active CPU Juno; `--male` changes both visible
models, `--local` enables a second human. Isolated profiles preserve regular
owner saves; there are no unlock, aura or victory grants.

Kaia: A/D move, W jump, J light, J+K heavy, K special, L shield, I dodge, U grab.
Local Juno: arrows/up move/jump, M light, M+comma heavy, comma special, period
shield, slash dodge, semicolon grab. After a real grab, a fresh directional attack
selects the existing throw. Normal escape and defensive rules remain active.

Review at normal speed: starts, acceleration, stops, opposite-direction pivots,
movement into attacks, recoil/guard return, charge, jumping/landing, grabs and
throws. Inspect both bodies and both facings, including feet, hips, shoulders,
head/hair and outer contact. KO acting must be observed from a genuinely earned
result; the terminal fixture is presentation coverage only.

Current recorded free storage is **12.93 GiB**, below the **18 GiB plus anticipated
allocation** reserve. No new native movie, platform/model export, APK, archive,
cache cleanup or protected-data deletion was performed. [Storage snapshot](STORAGE.json)
records the scoped source growth; remaining APFS free-space movement is unattributed.

Next: author phase-dependent stop/replant and movement-to-attack support exchanges,
then assess the coordinated floor/contact/hair assets when safe native review is
possible. Full nine-fighter production, final elemental VFX/SFX, seven earned
campaigns, Gray/Convergence, finished Kaia OVA plus six variants, real LAN,
physical Android/Windows and final human acceptance remain unfinished.
No merge, release, tag, deployment or publication is authorized.
