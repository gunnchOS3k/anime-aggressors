# Milestone 1 — Core Engine Truth

**Status:** In progress  
**Branch:** `feat/milestone-1-core-engine-truth`  
**Last updated:** 2026-06-24

---

## Goal

Make the platform-fighter **simulation mechanically truthful** before building Milestone 2+ features on top of it. Milestone 1 is **not** about polish, new fighters, menu redesign, or netplay — it is about deterministic movement, real platform collision, drop-through, blast-zone KOs, respawn, match-end correctness, regression tests, and a manual playtest record template.

---

## In scope

1. Deterministic movement (same inputs → same hash).
2. Full platform collision for existing `stageLayouts.ts` layouts.
3. Platform drop-through (Down + Jump on non-main platforms).
4. Blast-zone KO correctness.
5. Respawn correctness (state reset + invulnerability).
6. Match-end correctness (winner, rematch reset).
7. Regression tests under `packages/game-core/test/`.
8. Manual playtest record template under `docs/playtest/`.

---

## Out of scope (Milestone 2+)

- Ledges / ledge grab / recovery
- Grabs, throws, DI, parry
- CPU, training mode, items
- Online, career, Godot, Edge-IO, netplay
- New fighters or stages
- Menu redesign
- Full engine rewrite

---

## Files touched

| Area | Files |
|------|-------|
| Platform collision | `packages/game-core/src/stageCollision.ts` |
| Player lifecycle | `packages/game-core/src/combat/playerLifecycle.ts` |
| Simulation | `packages/game-core/src/combat.ts`, `simulate.ts` |
| Blast zones / respawn | `packages/game-core/src/combat/hitResolution.ts` |
| State | `packages/game-core/src/types.ts`, `state.ts` |
| Tests | `packages/game-core/test/milestone1CoreEngineTruth.test.ts`, `stageCollision.test.ts` |
| Web (minimal) | `apps/web/src/renderer-three/fighters/FighterAnimationController.ts` (type stub) |
| Docs | This file, `docs/playtest/2026-06-24-m1-core-engine-truth.md` |

---

## Pre-implementation audit (baseline)

### `simulateFrame` pipeline

1. **Countdown** — decrements `countdownFrames`; transitions to `fighting` at zero.
2. **Results** — no-op (frozen).
3. **Fighting** — if `hitstopFrames > 0`, only hitstop ticks down.
4. Otherwise: decrement match timer → `processPlayer` per player → `resolveCombat` (hits + blast-zone KOs) → energy clash ticks → stamina defeat check → win condition (`alive.length === 1` → `results` + `winnerId`).

### `processPlayer` / movement

- Input → jump buffer, optional drop-through (Down+Jump on pass-through platform), jump, aura, actions, movement, fast fall.
- `tickActionState` → `integratePhysics` (gravity, velocity integration, `resolveStageCollision`).

### Platform collision (before M1)

- PR #36 added `resolvePlatformLanding` using `getStageLayout(stageId)` platform tops.
- Landed from above only; main floor also duplicated via `stage.floorY` fallback.
- No drop-through; no `currentPlatformId` tracking; walk-off edge untested.

### Platform data source

- `integratePhysics` calls `getStageLayout(getStage(stageId).layoutId ?? stageId)` — **yes**, collision uses real `stageLayouts.ts` platform definitions.

### Blast-zone KOs

- `processBlastZoneKOs` in `hitResolution.ts` uses `isOutsideBlastZone` (left/right/top/bottom constants).
- Stock decrement; respawn at stage spawn or `defeated` at 0 stocks.

### Respawn (before M1)

- Duplicate `respawnPlayer` in `combat.ts` and `hitResolution.ts`.
- Missing clears for `dropThroughFrames`, `ignoredPlatformId`, `currentPlatformId`, `hitVictimsThisMove` consistency.

### Match end

- `simulateFrame`: one non-defeated player → `phase = "results"`, `winnerId` set.
- Timer tie-break for time/stock modes exists.

### Determinism tests (before M1)

- `determinism.test.ts`: same-input hash equality, replay hash, serialize round-trip.
- Missing: explicit different-input → different-hash test; platform/drop-through/KO integration tests.

### Gaps addressed in M1

| Gap | Fix |
|-----|-----|
| No drop-through | `dropThroughFrames`, `ignoredPlatformId`, `beginDropThrough` |
| Duplicate respawn logic | `combat/playerLifecycle.ts` → `resetPlayerAfterRespawn` |
| Main-floor double resolution | Single `resolveStageCollision` path |
| Rematch missing platform state | `resetForRematch` clears platform/drop-through fields |
| Missing regression coverage | `milestone1CoreEngineTruth.test.ts` (13 scenarios) |

---

## Acceptance tests (automated)

All tests in `packages/game-core/test/milestone1CoreEngineTruth.test.ts`:

1. Same config + same input log → same final hash.
2. Different input log → different final hash.
3. Falling player lands on main platform.
4. Falling player lands on side platform.
5. Rising player does not snap onto platform from below.
6. Player can walk off platform edge and fall.
7. Down + Jump drops through side platform.
8. Drop-through does not affect main floor.
9. Blast-zone crossing loses stock.
10. Respawn resets damage + grants invulnerability.
11. Zero stocks → defeated.
12. One player remaining → `results` phase.
13. Rematch clears movement/combat/drop-through state.

---

## Manual playtest requirements

See `docs/playtest/2026-06-24-m1-core-engine-truth.md`. Product owner must verify in browser; automated agent does not fake manual checks.

---

## Known risks

| Risk | Mitigation |
|------|------------|
| `tickDropThrough` inside collision may interact with multi-landing per frame | Tests cover drop-through + re-land |
| Shallow clone of `hitVictimsThisMove` in `cloneGameState` | Pre-existing; monitor if determinism regresses |
| Stage `layoutId` vs `stageId` mismatch | Resolve via `getStage().layoutId` everywhere |
| Walk-off requires velocity off platform edge | Integration test via `processPlayer` |

---

## Definition of done

- [ ] `npm run typecheck` passes
- [ ] `npm test` passes
- [ ] `npm run build` passes
- [ ] This document exists with audit + DoD
- [ ] Playtest record template exists
- [ ] All 13 Milestone 1 engine behaviors have automated tests
- [ ] No Milestone 2+ features introduced
- [ ] Manual playtest completed by product owner (or explicitly marked pending)

**Milestone 1 is complete when simulation truth is proven by tests and documented — not when the game feels polished.**
