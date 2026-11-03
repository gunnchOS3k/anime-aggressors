# Compact melee posture — owner review

Play `tools/v1_closure/play_melee_review.command`. This opens actual Kaia/Juno
combat against an active CPU in a separate isolated profile. Optional `--local`
uses two ordinary players; `--male` selects both male models. Owner Story saves
and earned receipts are untouched. No debug indicator is added to manual play.

Kaia: A/D move, J light, J+K heavy, L shield. Juno in local play: arrows move,
M light, M+comma heavy, period shield. Compare straight punches/heavies, missed
attacks, shielding and recovery at normal speed. Hooks retain authored motion.

The new spine/chest posture reduces excessive head-first overcommitment while
retaining hip/foot anchors, body-chain yaw, gaze, visible hand contact and natural
arm lengths. No whole-model shift, collision or frame/damage/knockback changes.
Three move categories across all nine profiles and 18BASE body rigs; not a new
claim of finished individual choreography. No projectile changes or recaptures.
Owner's specific projectile-impact acceptance remains recorded separately.

Normal-speed native clips (relative to repository root):
- Before7c2035253dff: `artifacts/v1_closure/spectral_feedback/rendered/melee_posture_before1020.mp4`
- After4d5bb494d4bb: `artifacts/v1_closure/spectral_feedback/rendered/melee_posture_after1020.mp4`
- Compare contact crops: `NATIVE_COMPARISON.png`; full before/contact/after
  sheets and exact stream/frame/hash/source checks: `native_before/` and
  `native_after/`. Native rawAVIs remain protected under `local_media/`.

Both clips are742frames at60fps with original game audio,521matched gameplay
barcodes and identical input/physics/control/damage/contact traces. They show
one shield and four hits, including the unchanged hook, plus a deliberate whiff
and recovery. These are two public controllers, not CPU or human performance.
The separately bounded8second activeCPU observation made9CPU moves and17real
contacts; no frozen opponent, forced move or result. No new KO/combo claim.

At four admitted contacts, projected Head skin convex-hull overlap fell
22.8–43.9%; head retreated5.1–5.5gamepixels. The hook contact stayed unchanged.
The comparison crops show reduced leaning; body/head overlap is still visible.
These metrics are partial geometry evidence, not a professional-quality score.

Focused checks:144configurations/864pose samples PASS on18rigs/bothfacings;
108straight/heavy contact corrections and36preserved hooks. Hip/foot drift0m,
projected wrist drift<=0.000031px, arm-length drift<=0.00000011m. Recovery,
reaction-clock, authored-cancel and864choreography checks pass. First failed
hook prototype retained and excluded from current correction coverage. Native
checks use bundledPython after systemPython lacked NumPy; no rerender needed.
Both manual presentation choices loaded their actual respective model paths.

Next blocker: coupled stage-floor/support-leg and melee contact fit, followed by
outer-range contact and fuller individual authored movement. Boots/floor,
remaining body overlap and authored hooks still need work. This increment does
not close those issues or accept artistic quality. Shared geometry fixtures are
not a replacement for nine-fighter ordinary-play and human review.

No merge, tag, deployment, release, heavy export or storage deletion. All33
worktrees/backups/evidence preserved. All broad human/release gates remain false.
Original assets/audio are for owner development review; no redistribution or
release authorization. See `RESULTS.json` for exact test/CI/source limitations.
