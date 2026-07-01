# Engine Reset Decision

**Date:** 2026-07-01  
**Branch:** `product/unity-combat-proof-spike`

---

## Decision

**Freeze Godot as a historical prototype. Do not delete it.**  
**Start a Unity combat proof spike as the new gameplay proof target.**

---

## Why

The Godot-first path (PR #45–#48) produced:

- Normalized data, docs, validation loops, and architecture
- Passing repo validators and smoke tests
- **Unreliable playable combat** in human playtests (hits, feel, loop satisfaction)

The project was stuck in documentation/architecture recursion while the actual game did not improve.

We need **editor-native Play Mode proof** that combat works — not more status JSON.

---

## Unity role

Unity is being tested because:

- Play Mode iteration is fast and inspectable
- Physics, triggers, and HUD are engine-native
- One scene can prove jab → hit → damage → knockback → shield → grab → aura without export pipelines

**Unity is not final** until the proof gate in `docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md` passes human signoff.

This is **not a full migration** yet.

---

## Unreal role

Unreal remains an **R&D option** for high-end 3D anime visuals and cinematic combat reference (`docs/UNREAL_RND_TRACK.md`).

For **gameplay proof speed**, Unity is the first spike. Unreal should be tested next only if Unity proof fails or art direction requires UE-first visuals.

---

## Godot status

| Item | Status |
|------|--------|
| `game-godot/` | **Frozen** — preserved, not deleted |
| Production runtime claim | **Withdrawn** |
| Further Godot combat patches | **Stop** (unless Unity spike fails and team re-evaluates) |
| TypeScript / web | Validation, oracle, legacy shell only |

---

## Success criteria for Unity spike

Human presses Play in Unity and verifies combat proof checklist — see `UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md`.

No claim of full product completion until Unity proof + final art + signed playtest.
