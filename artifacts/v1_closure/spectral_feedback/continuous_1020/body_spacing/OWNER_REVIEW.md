# Fighter body spacing — owner review

Quit the earlier review game, then run `tools/v1_closure/play_melee_review.command`.
The native AFTER source is e42655d5657e (body code380de325d654). Relaunch to load new scripts.
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

Native comparison is now complete after the owner closed the older game:
- BEFORE b264ee5578f9: `artifacts/v1_closure/spectral_feedback/rendered/body_spacing_before1020.mp4`
- AFTER e42655d5657e: `artifacts/v1_closure/spectral_feedback/rendered/body_spacing_after1020.mp4`
- `NATIVE_COMPARISON.png` gives unretouched2x crops at matched physics frames;
  full before/contact/after sheets are in `native_before/` and `native_after/`.

Each full-stage clip is868frames/14.467seconds at60fps, with original game audio
and647matched gameplay frame codes. All31public-input transitions are identical.
Native traces confirm baseline settled12.43px versus32.40px corrected spacing,
with six actual corrected contacts (shield/hook/light/heavies/singlethrow),
compared with one baseline throw contact. Dodge and jump cross sides. No target
was frozen or state/damage/outcome seeded; both local controllers remain active.
These are automated public controllers, not CPU footage or human acceptance.

RawAVIs remain protected local-only under `local_media/body_spacing_*1020.avi`.
Source/frame/audio hashes and diagnostic root/pushbox traces are beside each
movie's NATIVE_MOVIE.json. The2x crops supplement the full-stage normal-speed
movies, without changing the game camera or models. Owner development review
only; original project assets/audio, no distribution/release authorization.
Offline recording took40–41seconds; fixed60fps output is not deviceFPS proof.

Physical root stacking is corrected for eligible grounded interactions. Boot/
stage-floor fit, projected head/hair/limb overlap, outer reach and full authored
body acting remain production work requiring visual review. Shared fixtures do
not certify finished nine-fighter art or human game feel. No new true-combo/KO,
complete Story, OVA, LAN or device acceptance is claimed. All broad human and
release gates remain false. No merge, deploy, tag, release or heavy local export.
