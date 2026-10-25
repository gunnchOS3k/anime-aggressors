# Playable production increment — October 19

Run `tools/v1_closure/play_story_continuation.command`, then Start Game → Story.
This isolated profile genuinely earned 13 Kaia nodes and 11 qualifying encounter
receipts. Puppet Imbalance and First Release passed; Orion was released. Next is
Equilibrium. No progress, damage, AI or victories were seeded. Normal owner saves
are separate. The original `play_story_review.command` still opens the separate
seven-receipt Accord profile for Stop Scene/restart review.

Combat now honors existing explicit, hit-confirmed target cancel windows. Attack
again during the jab's authored window; Kaia can link jab 1 → jab 2, then request
Up + Attack. Juno can link jab 1 → jab 2 → finisher. Later hits are not guaranteed:
shielding and recovery remain real. No attack frame values, damage, knockback or
collision geometry changed. Simultaneous Attack + Special remains heavy;
Special is a projectile; Special + Shield charges. Native/public probes are
input automation against active CPUs, not owner playtest approval.

All nine fighters and both rigs now load original pelvis/ribcage/arm timing
refinements for the first two jabs, heavy and side special. Their active poses
remain exact; supporting limbs are constrained around the modified preparation
and recovery. Real damage/tier selects authored light/heavy/elemental body breaks,
with counter-rotating pelvis, delayed head and opening guard. Hitstop freezes the
reaction in the contact callback. A 75ms upper-body neutral-return blend clears
immediately for the next action and does not override feet or control timing. These are working
refinements, not completed professional choreography for every move.

Confirmed hits and blocks can react on a real stage surface beneath contact.
Wind carries open curls/leaves; voltage branches along surfaces; combustion
leaves cooling heat; stone fractures, frost branches, inward gravity orbits,
separated phase seams, inward Yin apertures and outward Yang construction have
separate shape grammars. Decoration uses the existing pool, yields to primary
feedback, sits below fighters, expires, and respects VFX accessibility. It does
not damage or alter terrain. Airborne contact over empty space paints no floor.

`AUTHORED_COMBO_RESULTS.json` separates authored data, recognized inputs, legal
cancels, strict pairs and human acceptance. The legacy catalog contains 70 routes;
the current shared TypeScript file contains **46**, versus the reported 48.
Neither catalog directly drives the shipping Godot BattleScene. Existing routes
were preserved; complete legacy/web-route certification remains pending.

Remaining: the model/floor/outer-reach coordinate mismatch needs coordinated
visual/art authority; no collider changes or anatomy distortion shipped. Complete
move-by-move acting, lower-body transition polish, secondary motion, high-damage route
certification, unsupported parry/clash and projectile/terrain design, full
seven-route ordinary acceptance, ANI-04 and ANI-05 remain open. All human,
art/audio/game-feel and final release gates remain false.

Review videos (normal speed, original audio, active CPUs, female models):

- [Kaia versus Juno](../rendered/production1019_kaia-windrow.mp4)
- [Juno versus Kaia](../rendered/productionjuno1019_juno-spark.mp4)

Both are source `4416c85e`, 25.35 seconds at 60 fps, with all 1,300 visible
frame stamps matched per movie. The later surface-layer correction and truthful
training counter are source `6ed18e61d7324e38a292b909fc3c07894d2af51a`. The two
`stage_native_preview/*surface_preview.png` images are declared renderer fixtures,
with no CPU/damage/combo claim. They verify the corrected floor layer. Existing
movies remain preserved and are not relabeled as the later source.

Training now ends a displayed combo when the defender recovers, rejects duplicate,
shield/armor and unconfirmed packets, and shows the existing manifest link. The
live training check landed isolated jabs at frames 296 and 400; both correctly
displayed combo 1 and the Attack hint. This is a training UI check, not CPU combo
certification. See `CURRENT_ROSTER_PRODUCTION_MATRIX.json` and
`LATEST_INCREMENT_VALIDATION.json` for exact source scopes.

The inspected gameplay frames still show close-body overlap and the shared
model/floor/reach mismatch. Full fighter visual readiness remains false in the
matrix. The floor-layer previews demonstrate rendering order only; their staged
actors are not animation or gameplay acceptance evidence.
