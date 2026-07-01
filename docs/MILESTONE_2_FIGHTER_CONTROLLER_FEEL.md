# Milestone 2 — Fighter Controller Feel

**Status:** Complete (pending manual playtest)  
**Branch:** `feat/milestone-2-fighter-controller-feel`  
**Last updated:** 2026-06-24

---

## Goal

Make player movement feel like a **real platform fighter controller** — dash/run, jump squat, short/full hop, coyote/buffered jumps, fast fall, landing lag, and basic ledge/recovery — before Milestone 3 combat grammar.

**Milestone 2 is about controller feel and movement vocabulary. Combat grammar belongs to Milestone 3.**

---

## In scope

1. Deterministic movement state model (`movementState` + frame counters).
2. Ground movement: dash start → run, deceleration, skid/turnaround, crouch.
3. Jump squat, short hop / full hop, double jump, coyote, jump buffer (hardened).
4. Fast fall (after upward motion ends).
5. Landing lag (normal vs fast-fall).
6. Stage ledge points + grab / hang / jump / getup / release + regrab cooldown.
7. Basic recovery (special while airborne, once per airtime).
8. Regression tests + manual playtest template.
9. Minimal debug panel lines for movement state.

---

## Out of scope (Milestone 3+)

- Combat grammar depth (attack cancel trees, stale moves, shield break, DI, parry)
- Grabs, throws, CPU, training mode, items
- Online, netplay, Godot, Edge-IO
- New fighters, menu redesign, full engine rewrite

---

## Pre-implementation audit (baseline after Milestone 1)

| Area | State before M2 |
|------|-----------------|
| Grounded movement | `applyHorizontalMovement`: lerp accel to run speed; instant facing; `running`/`idle` actionState only |
| Dash | Only via **dodge** (`applyDash`), not tap-direction dash-start |
| Deceleration | `vx * 0.55` when input released on ground |
| Turnaround | No explicit skid; lerp reverses velocity |
| Crouch | Not implemented (down only triggered fast fall in air / drop-through on ground) |
| Jump buffer | `jumpBufferFrames` (6) in `jumpSystem.ts` |
| Coyote time | `coyoteFrames` (5), `canCoyoteJump` when `jumpsUsed === 0` |
| Short hop / full hop | Release during `jumpHoldFrames` scales vy; **no jump squat** |
| Double jump | `jumpsUsed` 1→2 via `tryJump` |
| Fast fall | `down` while airborne set `fastFalling` immediately (even while rising) |
| Air drift | `computeAirDriftSpeed` + lerp in `applyHorizontalMovement` |
| Landing lag | **None** |
| Ledge grab | **None** |
| Recovery | Special attacks only; no dedicated recovery movement |
| Input frame | `left/right/up/down/jump/attack/special/shield/dodge/grab` per player per frame |
| Renderer | Uses `actionState`; no `movementState` in debug until M2 |

---

## Files touched

| Area | Files |
|------|-------|
| Movement model | `movement/movementTypes.ts`, `groundMovement.ts`, `movementController.ts` |
| Jump | `movement/jumpSystem.ts` (jump squat) |
| Landing | `movement/landingLag.ts` |
| Ledge | `movement/ledgeSystem.ts`, `stageLayouts.ts` (ledge points) |
| Recovery | `movement/recovery.ts` |
| Integration | `combat.ts`, `state.ts`, `types.ts`, `playerLifecycle.ts`, `simulate.ts` |
| Tests | `test/milestone2FighterControllerFeel.test.ts`, `test/helpers/playerStub.ts` |
| Web | `apps/web/src/game/debugPanel.ts`, animation stubs |
| Docs | This file, `docs/playtest/2026-06-24-m2-fighter-controller-feel.md` |

---

## Acceptance tests (automated)

See `packages/game-core/test/milestone2FighterControllerFeel.test.ts` (22 scenarios).

---

## Manual playtest requirements

See `docs/playtest/2026-06-24-m2-fighter-controller-feel.md`.

---

## Known risks

| Risk | Mitigation |
|------|------------|
| Landing lag blocks attacks briefly | `isMovementLocked` gates `startAction` |
| Recovery vs special attack both use `special` | Recovery only when airborne + `!recoveryUsed`; combat special on ground unchanged |
| Ledge snap position | Deterministic inset on getup; tested |
| M1 drop-through regression | Explicit test in M2 suite |

---

## Definition of done

- [ ] `npm run typecheck` passes
- [ ] `npm test` passes
- [ ] `npm run build` passes
- [ ] This document + playtest record exist
- [ ] All 22 movement behaviors have deterministic tests
- [ ] No Milestone 3+ systems introduced
- [ ] Manual playtest completed by product owner (or marked pending)

**Milestone 2 is complete when controller feel is proven by tests — not when combat is deep.**
