# VXP-3 Phase 1 — Combat Impact Diagnosis

Base: accepted `origin/main` (PR #105 merge). RC1 tag `v1.0.0-rc.1` is not mutated.

## What is true on main today

Damage percent already increments. Hitstop, sparks, and juice events exist. Nix and Rook already have distinct procedural clip signatures for idle/walk/run/jab/hurt/launch.

Hits still read as **numbers going up**, not as **contact**. Light and heavy share the same victim clip (`hurt`) and the attacker only takes half hitstop, so the pair does not freeze together on impact. Camera shake fires on light hits. Special states still resolve through a generic `special` token. Training can freeze and step, but cannot force a hit tier, replay a hit, or hide HUD for clip review.

## Owner feedback mapped

| Feedback | Phase 1 response |
| --- | --- |
| Hits do not feel painful/powerful | Impact profiles + synced hitstop + contact poses + sparks at socket |
| Need better locomotion / attack / hurt / recovery | Deepened Nix/Rook pose-to-pose clips; not claimed as final art |
| Preserve 7 unique identities | Docs bible for all seven; authored slice only Nix vs Rook |
| Watchable / clippable | HUD-hidden impact class + training replay/freeze/hide HUD |
| Do not shrink polish | Architecture + validators + hooks for Phase 2+ |

## Honesty

- Clips are Godot-authored pose-to-pose placeholders, not final GLB/FBX performances.
- `VXP3_HUMAN_VISUAL_VALIDATION_PASS`, `VXP3_HUMAN_COMBAT_FEEL_PASS`, and `VXP3_HUMAN_FUN_PASS` stay **false**.
- Physics knockback formula is unchanged. No root motion.

## Phase 2+ (after owner review only)

Ember, Juno, Kaia, Orion, Vesper choreography. Charged-layer performances. Cinematic director enabled. Pixel 60fps packet if authorized.
