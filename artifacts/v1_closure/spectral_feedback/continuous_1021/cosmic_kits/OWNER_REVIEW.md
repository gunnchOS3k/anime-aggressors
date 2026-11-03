# Yin / Yang playable tuning candidates

Runtime source: `e6ead8f9bbf2331032975e5d28e58c3b25dbbdc7`, draft PR #123,
stacked on draft #122. The following delivery commit changes reports only.
Balance, animation, art and feel approval remain pending. This does not close
ANI-04 acting or final OVA production.

## Play

From the repository, launch one review at a time:

```sh
tools/v1_closure/play_cosmic_review.command yin --opponent juno-spark --body female
tools/v1_closure/play_cosmic_review.command yang --opponent rook-ironside --body male
```

Choose either body and any of the nine opponents. Add `--local` for two players.
This uses a separate profile and actual BattleScene. It grants no aura, campaign
progress or shipping unlocks, and leaves owner saves alone.

A/D move, W jumps, J attacks, J+K uses heavy, K fires, L shields, U grabs and I
dodges. Hold K+L to charge normally. S+K uses the new defensive action. Begin
with movement, light/heavy attacks and shield exchanges before testing it.

| Yin — reduction | Yang — definition |
|---|---|
| Deliberate inward palm rhythms, inward launch directions and slower aperture pulses. | Ordered outward strikes, outward launch directions and faster radiant facets. |
| **Absorption Window:** costs 25 aura only when one eligible integrity-1 enemy shot reaches the real swept fighter-contact point during six active frames. | **Definition Panel:** a stationary, non-piercing construct lasting 36 frames; only one owned panel remains active. |
| Strong shots, a second shot, poor timing or insufficient aura still threaten Yin. No reflection or melee parry was added. | Uses existing projectile interception authority; quick opposing shots mutually cancel it and stronger shots can break through. |
| Distance Fold moves normally; Toward Zero is the signature candidate. No teleport or boss immunity. | Declared Vector advances normally; Perfect Definition is the signature candidate. No terrain or invulnerability rule. |

All 24 move entries per character now have their own identity and resource paths.
The two characters have separate aura profiles, charged-shot parameters, special
actions and original keys on both rigs: inward absorption versus outward panel
construction, and quiet recoil versus a fractured brace. Existing original
elemental shapes and audio hooks are reused. No imported art, motion, samples or
synthetic voices were added. The seven other move manifests and authored clip
files remain byte-identical to the recovered source.

## Verified scope and limits

144 real light/heavy contacts cover both cosmic fighters against all nine
opponents, both bodies and facings. Controlled setup fixtures pass nine weak-shot
absorptions, five counterplay cases, panel lifetime/replacement and nine roster
projectile interceptions. Eight focused public-input cases pass for the
counter/panel across both bodies and facings. These fixtures declare setup and
resources; they are not earned Story or human playthrough evidence.

Ten affected regression suites passed, followed by the nine-profile identity
contract, staged cosmic shipping paths and CampaignRestart. Together the shipping
runs exercised all 18 base model paths. Four isolated review launches load the
corresponding model resources. Some tests retain resource-at-exit warnings;
this is not a leak-free certification.

Two 900-frame public-input probes against active CPUs recorded 24 and 31 real
contacts. Juno and Rook attacked and damaged the player. No forced moves, damage,
KO or frozen opponent was used. Neither probe demonstrated the new absorption,
a KO or full authored combo acceptance. These are headless observations, not
60 fps videos or hardware performance measurements.

Failed attempts are retained: the freed-reference fixture error, insufficient
fixture watchdog, late counter inputs and fresh shipping-unlock fixture. The
late shot correctly hit after the counter window; only test input timing changed.
See [attempt ledger](ATTEMPT_LEDGER.json), [validation](VALIDATION_REPORT.json)
and [nine-row matrix](ROSTER_MATRIX.json).

## Existing visual evidence and unfinished authored work

The ANI-03 comparison remains complete: 868 native frames, 647 matching frame
codes, original audio and unchanged six contacts. Reuse
[before](../../rendered/body_spacing_after1020.mp4),
[after](../../rendered/contact_integration_after1020.mp4) and
[matched frames](../../continuous_1020/final_contact/GUARD_COMPARISON.png).
They retain their old sources and are **not** new Yin/Yang kit footage.
The source/hash receipt is [ANI03_PRESERVED.json](ANI03_PRESERVED.json).
Media and character art retain their existing owner-review restrictions;
this increment grants no redistribution or publication permission.

`VISUAL_ACCEPTANCE=false`. The existing 35–38 px boot/floor discrepancy,
12.5–17.6 px outer hand gaps and projected head/hair overlap remain open.
New cosmic keys do not repair those shared problems. No whole-model offset,
anatomical scaling, hidden collision change or cosmetic mask was applied.

[Asset closure plan](ART_CLOSURE_PLAN.md) identifies the Blender/GLB, sole-control,
camera projection, kinetic-chain and hair-weighting work. The next highest-impact
production task is an original, coordinated support/strike/recovery asset pass
with weighted-sole references on the preserved rigs, judged in the unchanged
battle camera. Floor and contact must be addressed together. All nine fighters
retain production animation work.

All human and release gates remain false. Seven genuinely earned campaigns,
Prismatic Gray/Sevenfold Convergence, final Kaia OVA plus six variations, real
LAN and physical-device/platform acceptance remain unfinished dependencies.
No new recording/export was attempted below the 18 GiB plus allocation reserve.
