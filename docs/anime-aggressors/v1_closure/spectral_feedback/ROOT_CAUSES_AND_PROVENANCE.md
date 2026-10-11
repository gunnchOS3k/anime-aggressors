# ANI-03 runtime findings and provenance

This is the continuation of preserved draft #122 through stacked draft #123. The two reference MP4s were not attached or found among this conversation's attachments. The timestamps and hit-feedback observations are owner-supplied direction; this report does not claim to have viewed either recording or analyzed the legal reel.

## Confirmed runtime causes

| Finding | Runtime consequence | Implemented correction |
| --- | --- | --- |
| Ordinary hit feedback used small proxy shapes and child-local placement for a world contact. | Contact could look detached or too small at the live camera scale. | Scene-owned, world-positioned shader meshes; light/heavy extents 140/190; original directional geometry. |
| LaunchTrail had no live caller continuously following the victim. | Its initial point could not establish a visible moving wake. | Physics-owned weak target, actual displacement sampling, velocity-scaled smoke and recovery termination. |
| Smoke also had an arbitrary one-second cutoff. | A longer genuine launch could lose its wake before recovery. | Removed that presentation-only cutoff; displacement and actual victim state remain authoritative. |
| Old projectile bursts were tied to a callback even when the resolver rejected the target, and transient children disappeared with the projectile. | Misleading or missing impact/dissipation, with duplicate pathways. | Resolver-accepted fighter contact owns the burst; scene-owned release/flight/wake/dissipation survive projectile cleanup. |
| Blocking was classified too late for presentation. | A shield could receive body-hit presentation. | Classify shield/armor before presentation; distinct defensive shapes and existing defensive rules. |
| AnimationEventBridge mapped activation to impact and had a `Dictionary.merge()` return-value parse error. | This was a latent unsafe mapping, not evidence that the unused bridge rendered ordinary BattleScene impacts. | Parse repair and activation → attack_swing only. The ordinary scene uses direct confirmed feedback. |
| Juice events were emitted without a live ordinary effect listener. | A correctly named event did not prove a rendered effect. | Direct live SpectralFeedback dispatch; retain observational bus events. |
| An interrupted victim's MoveRunner stayed active. | Its later callbacks could overwrite hurt/recovery and reactivate its hitbox. | Cancel the victim move and disable its hitbox on a confirmed body hit. Baseline failure and corrected test preserve the identical launch/hitstun values. |
| CPU anticipation and charge used flat rectangles. | Proxy flashes obscured distinct meanings. | Owned anticipation/charge shader effects; charge rectangles hidden. |
| Signatures had a release sound but only a generic swing visual on a miss. | Energy release was absent without a collision. | Separate original signature release on the real first active frame; a miss still has no confirmed-contact burst. |
| Mesh dedupe did not independently guard repeated audio/camera dispatch. | A repeated confirmed event could stack presentation outside the normal resolver ledger. | Bounded event-ID dedupe at both feedback and mesh boundaries. |

No frame data, damage, knockback formula, collision shapes, CPU behavior, netcode, roster manifests, Story graph, receipt rules or save schema were tuned. The victim-move interruption is the identified gameplay defect; the remaining changes concern presentation or observation.

## Combo finding

The first two accurate 60 fps clips had real hits/blocks but no true follow-up. Their driver often dashed into contact and waited too long to press again. Short adaptive probes use public walking, facing correction and fresh attack presses as actions become available. They never assign transforms, velocities, damage after fixture initialization, hitstun, KOs or attack results. P2 remains an active CPU with controls enabled.

Thirty core probes cover five input recipes for Ember/Juno at explicit initial opponent damage 0/50/110. Actual move pairs and actual damage at first contact determine the result; a recipe name does not prove that its heavy or aerial move linked. The core probes recorded 11 genuine pairs, 102 blocked pairs and 24 probes with no true combo. Two native light probes reproduced Ember's one and Juno's three successes. Separate failed edgeguard attempts remain evidence, not finishing-hit acceptance.

Native Juno example: jab_1 contact frame 436, two observed hitstop frames 436–437, jab_2 active frame 444 and contact frame 446 while the defender was still in hitstun. Ember's forward_tilt contacts at 324 and 339 also linked. A contrasting Ember heavy contact at 342 landed at 353; defender control returned at 362, the next attack activated at 363, and the defender shielded contact at 365. These windows explain why a later hit or repeated combo counter cannot be treated as a true combo.

Ground landing recovery often ends control lock before nominal hitstun duration. That is retained existing behavior. Stronger launch or different landing/cancel rules would require separately identified tuning and validation; no experimental tuning is enabled in these results.

## Original assets and audio

The new shipping asset is project-authored `game-godot/shaders/spectral_feedback.gdshader` with its mesh renderer. Distance fields, rings, crescents, facets, noise, branching filaments and cloud lobes are calculated mathematically. There are no imported VFX textures, flipbooks, sprites, animations, models, shader snippets or reference video frames. Code remains under the repository's MIT license. Nine geometries differ independently of palette; 36 raster comparisons passed with a minimum normalized shape difference of 40.2%.

Existing character meshes, rigs, models, motion key-pose studies, facial reactions and owner design direction remain. These are development performances; this change does not claim final authored acting, planted-foot choreography, refined secondary motion or completed OVA animation.

Recordings contain the native Godot mixed audio, encoded from AVI PCM to AAC without dubbing. Existing solid-hit and original synthesized elemental audio are preserved byte-for-byte from the pre-spectral checkpoint. Their layered-source/provenance catalog remains in the dialogue/performance package. No Nintendo assets, actor imitation, paid service, purchased sample pack or newly acquired external sound was used. Temporary Story voices remain local development previews with their existing redistribution gate; they are not included in these versus clips.

## Explicit remaining authority limits

Parry and clash have no current combat-resolution rules. They are not fabricated as successful outcomes. Environment callbacks are wired, but the existing projectile mask 6 excludes stage layer 1: physical terrain interaction is not claimed complete. Altering that mask would change competitive projectile behavior and must be treated as a separate gameplay-rule change. Finishing geometry is emitted by authentic stock loss, never by a predicted launch. Native KO evidence must be recorded before claiming that capture requirement satisfied.

Human game-feel, VFX, animation, sound-mix, V1, platform and release gates remain false. ANI-04 authored OVA/acting and ANI-05 device/human/release acceptance remain separate dependencies. No merge, deploy, tag, heavy platform export or publication is authorized here.
