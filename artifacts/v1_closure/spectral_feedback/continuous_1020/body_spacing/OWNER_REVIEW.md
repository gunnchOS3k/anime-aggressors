# Fighter body spacing — owner review

Quit the earlier review game, then run `tools/v1_closure/play_melee_review.command`.
The new source is380de325d654; an already-open b264ee55 game keeps its old scripts.
Default: Kaia versus active Juno CPU. Optional `--local` for two players and
`--male` for both existing male models. The separate profile preserves owner
Story saves and all earned campaign progress.

Kaia: A/D move, J light, J+K heavy, L shield, W jump, I dodge, U grab.
Juno local: arrows move/up jump, M light, M+comma heavy, period shield,
slash dodge, semicolon grab. During a grab, direction plus attack throws.

Walk into one another, stop and exchange lights/heavies, shield, dodge through,
jump over, grab/throw and walk away. Grounded bodies now stop at their existing
profile-sized shapes. Kaia/Juno roots hold32.4px apart; the identical prior
ordinary inputs settled12.43px apart and approached1.53px. Both actual dodge
and jump changed sides, and the throw produced one owned damage contact.
Before, most attacks whiffed because the roots had crossed while facing outwards;
after the same stream produced shield, hook, lights, heavies and the throw.

This is authoritative body spacing, not an extra head-overlap score or a visual
model translation. Main body layer2/mask1 remains stage-only, so fighters cannot
stand on opponents. The shared solver separates ordinary grounded bodies after
stage movement and before combat, clips pushes against walls/ground support,
limits overlap recovery to existing run speed and adds no velocity. Foot gait
reads the corrected root, rather than the movement that was blocked.

Crossing remains free for air/dodge/phase, authored moving attacks, grab/throw,
hurt/launch, ledge/respawn/invulnerability and passive/cosmic/ally Story staging.
Same-team puppets may cross. No attack/hurtbox, damage, timing, knockback, body
proportions, original sound, projectile, knee-plane or compact-punch data changed.
Normal grounded closing movement and therefore contact opportunities change
intentionally; catalog timing/cancels and defensive rules are preserved.

Validation: all36roster/body/direction public walk+shield cases PASS; exact body
sizes, floorY and move catalogs preserved, stable boundary contact. Bounded
wall/ledge-support/order tests and real six-actor Story puppet setup PASS; five
activeCPUs, no campaign receipt earned. Throw39, footwork, recovery, reaction,
authored-cancel and separate save/restart/watch checks pass. Bounded activeCPU
melee:340frames,9contacts/4CPU moves, no frozen opponent or forced results.
See RESULTS.json, PUBLIC_COMPARISON.json and affected/RESULTS.json.

NEW native before/after videos remain pending: the recording guard found the
owner-opened older review game (PID56232). It has been preserved and closure
requested. No historical movie is relabeled as current collision evidence.
After that window closes, run the exact bounded capture steps in ANI03_RESUME_STATE.md.
Diagnostic root/pushbox traces are saved; no permanent debug geometry is shown.

Physical root stacking is corrected for eligible grounded interactions. Boot/
stage-floor fit, projected head/hair/limb overlap, outer reach and full authored
body acting remain production work requiring visual review. Shared fixtures do
not certify finished nine-fighter art or human game feel. No new true-combo/KO,
complete Story, OVA, LAN or device acceptance is claimed. All broad human and
release gates remain false. No merge, deploy, tag, release or heavy local export.
