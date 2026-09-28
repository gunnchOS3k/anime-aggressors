# Combat Animation Style Guide

Companion to `docs/vxp3/FIGHTER_MOTION_IDENTITY_BIBLE.md`. Original IP only.

## Shared grammar

- Pose-to-pose with readable silhouettes. Contact frame stays inside the existing hitbox window.
- Anticipation → contact → follow-through. Follow-through may be longer than gameplay recovery; do not retarget hitboxes to match late acting.
- No root-motion locomotion. Feet plant visually; CombatMath owns travel.
- Charge 0 / 25 / 50 / 75 / 100 changes **volume and line**, not just glow.
- Hurt must read with HUD hidden.
- Heavy, aura, and super must not share a contact pose.
- Jabs stay snappy. They never enter aura-clash.

## Per fighter (do not recolor)

| Fighter | Tempo | Weight | Signature line |
|---------|-------|--------|----------------|
| Ember Vale | Fast | Light-medium | Rush-through, whip hurt |
| Rook Ironside | Slow | Heavy | Plant, armor swell, body snap |
| Juno Spark | Staccato | Light | Pop / reset, never Ember timing |
| Kaia Windrow | Long | Medium-float | Carry arcs, loft hurt |
| Nix Calder | Held | Medium-stiff | Crystal contact, freeze before launch |
| Orion Vell | Delayed | Heavy | Set space, sink, then pull |
| Vesper Nyx | Broken | Medium-asymmetric | Feint, dissolve-snap |

## Clash

Only aura / super / beam / explicitly `choreography.clashable`. Mixed-identity clashes combine both palettes. Resolve is deterministic. No mash.

## Accessibility

Reduce-camera / reduce-motion must still leave posing readable. Do not rely on shake or flash for the read.

## What this pass is not

Scripted JSON keys and pipeline-proof pose-blocks are **not** this style guide satisfied.
