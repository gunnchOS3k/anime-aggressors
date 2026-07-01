# Platform Fighter Requirements — Anime Aggressors

**Status:** Requirements freeze (Milestone 0)  
**Last updated:** 2026-06-24  
**Related:** [Gap analysis](./ANIME_AGGRESSORS_GAP_ANALYSIS.md) · [MVP DoD](./MVP_DEFINITION_OF_DONE.md) · [Engine architecture](./ENGINE_ARCHITECTURE.md)

---

## 1. Product goal

Anime Aggressors should become an **original** platform fighter inspired by the structure and feel of Super Smash Bros. Ultimate and Super Smash Flash 2 — without copying Nintendo, McLeodGaming, anime IP, characters, stages, sounds, names, UI, or copyrighted assets.

The goal is **not** to build “Smash Ultimate” at commercial Nintendo scale. The goal is to build a **fully operational indie platform fighter** with:

- A clear match loop
- Readable combat
- Finished controls
- Unique fighters
- Working stages
- Local multiplayer
- CPU support
- Training mode
- A clean release path

---

## 2. Reference baseline

A fully operational platform fighter needs:

1. **Match loop** — damage opponents, launch farther as damage rises, score KOs outside the arena.
2. **Multiple fighters** — distinct movement, stats, attacks, animations, recovery.
3. **Responsive movement** — walk, dash, jump, double jump, air drift, fast fall, platform landing, drop-through, ledge interaction, recovery.
4. **Real combat model** — hitboxes, hurtboxes, startup/active/recovery, hitlag, hitstun, knockback, DI, shields, grabs, throws, dodges, supers.
5. **Stage systems** — platforms, blast zones, spawns, hazards on/off, legal variants, camera bounds, stage select.
6. **Local multiplayer** — P1–P4 controls, controller support, remapping, pause, restart, results.
7. **CPU opponents** — basic difficulty levels.
8. **Training mode** — frame step, hitbox display, damage reset, CPU behavior, input display, move testing.
9. **Menus** — obvious main play path.
10. **Architecture** — deterministic simulation separated from rendering, UI, audio, storage, networking.
11. **Content pipeline** — fighters, stages, animations, VFX, SFX, music, UI art, balance data.
12. **Quality gates** — automated tests and manual playtest checklists that verify the game feels playable.

---

## 3. Requirement categories

### A. Core match loop

| Requirement | Notes |
|-------------|--------|
| Fresh launch → playable match within two clicks | Quick Match is the canonical path |
| Stock, time, and training rules | Ruleset presets in `game-core` |
| Correct spawns | `spawn.ts`, stage spawn points |
| Damage increases on hit | `hitResolution.ts` |
| Knockback scales with damage | `knockback.ts`, `feel.ts` |
| Blast zones remove stocks | `blastZones.ts`, `processBlastZoneKOs` |
| Respawn invulnerability | `respawnPlayer` |
| Clean match end | `phase === "results"` |
| Results: winner, stocks, damage, KOs, rematch/menu | `MatchResultsScreen`, career stats |

**Priority:** High

### B. Player movement

| Required | Repo touchpoints (today) |
|----------|-------------------------|
| Walk / run | `applyMovement.ts`, size classes |
| Dash start / turnaround | Partial — dodge dash exists |
| Crouch | `moveDown` input, not full crouch state |
| Full hop / short hop | Jump only; no short-hop split |
| Double jump (or per-fighter count) | `jumpSystem.ts` |
| Air drift | `applyHorizontalMovement`, air control |
| Fast fall | `fastFallSpeed` |
| Landing lag | **Missing** |
| Platform landing | `stageCollision.ts` (PR #36) |
| Platform drop-through | **Missing** |
| Ledge grab / hang / getup / roll / jump | **Missing** |
| Recovery specials | Move slots exist; recovery tuning incomplete |
| Wall collision | **Missing** (where applicable) |

**Priority:** Critical

### C. Combat system

| Required | Status |
|----------|--------|
| Ground attacks (neutral/forward/up/down tilt, dash attack) | Partial — directional attack slots |
| Smashes (forward/up/down) | Partial — charged smash not formalized |
| Aerials (N/F/B/U/D) | Partial |
| Specials (neutral/side/up/down) | Partial — fighter move catalog growing |
| Grab / pummel / throws | Input exists; grab combat **incomplete** |
| Shield / shield stun / pushback / break | Shield HP only; no full shield model |
| Dodge / roll / air dodge | Ground dodge only |
| Hitlag / hitstun / knockback scaling | `hitlag.ts`, `hitstun.ts`, `knockback.ts` |
| DI / SDI | **Missing** |
| Multi-hit | `multiHit` flag on frame data (PR #36) |
| Projectiles / supers | Energy clash / beam path exists |
| Stale move decay | **Missing** |
| Per-fighter frame data | `frameData.ts`, `moveDefinitions.ts` |

**Priority:** Critical

### D. Fighters

**Minimum indie vertical-slice roster:**

1. Balanced all-rounder  
2. Heavy bruiser  
3. Fast rushdown  
4. Projectile / zoning fighter  

**Per fighter:** name, silhouette, stats, movement tuning, complete move list, frame data, hit/hurt boxes, recovery, animations (idle/walk/run/jump/fall/land/attack/hitstun/KO), VFX, SFX, select portrait, training move card.

**Today:** Seven default ROYGBIV fighters with specs under `docs/fighters/`; gameplay differentiation and polish are **not** product-grade.

**Priority:** Critical

### E. Stages

**Minimum set:**

1. Training Grid  
2. Battlefield-style (three platforms)  
3. Final Destination-style flat  
4. Casual identity stage  
5. Experimental / hazard stage  

**Per stage:** main platform, optional floats, spawns, blast zones, camera bounds, legal variant, art, collision map, performance budget, preview card.

**Today:** `stageLayouts.ts`, `stages.ts`, skyline-arena + training-grid; basic platform landing (PR #36). Missing: drop-through, polished select, legal variants, hazards, camera tuning.

**Priority:** High

### F. Camera

- Track active fighters; zoom on spread; readable blast zones  
- KO drama without disruption  
- 2 / 3 / 4 player support  
- Training / debug modes  
- Never lose off-screen players  

**Today:** `ThreeGameRenderer`, smooth camera — needs formal acceptance tests.

**Priority:** High

### G. Controls and input

- Keyboard P1/P2 (canonical map in `controlReference.ts`, PR #36)  
- Gamepad P1–P4  
- Connect/disconnect, remapping, saved profiles  
- Input buffering (`jumpSystem` buffer)  
- Tap jump, short-hop, C-stick / smash stick (if gamepad)  
- Pause / menu; training input display  

**Priority:** High

### H. CPU opponents

- Recover, approach, attack, shield/dodge, return to stage  
- Difficulty levels  
- Training and versus modes  

**Today:** Flagline bots only; **no** general versus CPU.

**Priority:** High

### I. Training mode

- Damage/position reset, frame advance, hitbox toggle, input display  
- CPU behaviors: idle, jump, shield, attack, DI, recover  
- Move list, combo counter, frame advantage, knockback preview  
- Save/load scenario  

**Today:** Partial overlays in `PlatformFighterApp`; not a complete lab.

**Priority:** Medium-high

### J. UI/UX

Home · Quick Match · Versus · Training · Fighter Select · Stage Select · Rules · Controls · Settings · Pause · Results · Credits · Labs separated from main path.

**Today:** Quick Match + Labs split (PR #36); hierarchy still dense.

**Priority:** High

### K. Audio / VFX / feel

Hit sparks, shield sparks, jump/land dust, dash FX, KO blast, screen shake, hit pause, character SFX hooks, menu sounds, stage music, volume settings.

**Today:** `AudioManager`, VFX modules — no polished feel pass.

**Priority:** Medium-high

### L. Engineering architecture

See [ENGINE_ARCHITECTURE.md](./ENGINE_ARCHITECTURE.md). Summary:

- Deterministic `game-core` sim  
- Renderer separated (`apps/web` Three.js)  
- Input → `InputFrame` → sim  
- Replayable logs, frame-data combat, data-driven fighters/stages  
- Debug overlay, testable physics/combat, playtest harness  

**Priority:** Critical

---

## 4. Out of scope (this requirements doc)

- Netplay / ranked ladder (future track B)  
- Godot export as shipping runtime (labs / parallel R&D)  
- Edge-IO as required input (optional track F)  
- Copying Smash / SSF2 assets, moves, or characters  

---

## 5. Traceability

| Doc | Purpose |
|-----|---------|
| [PLAYABLE_VERTICAL_SLICE_AUDIT.md](./PLAYABLE_VERTICAL_SLICE_AUDIT.md) | PR #36 web path audit |
| [PLAYTEST_CHECKLIST.md](./PLAYTEST_CHECKLIST.md) | 5-minute manual QA |
| [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) | Full program PRD (tracks A–H) |
| [GENRE_GAP_ANALYSIS.md](./GENRE_GAP_ANALYSIS.md) | Genre positioning (pre–Milestone 0) |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Repo-wide architecture |
