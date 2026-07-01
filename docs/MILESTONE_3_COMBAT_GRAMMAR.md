# Milestone 3 — Combat Grammar

**Status:** Complete (pending manual playtest)  
**Branch:** `feat/milestone-3-combat-grammar`  
**Last updated:** 2026-06-24

---

## Goal

Make Anime Aggressors' combat system behave like a **real platform fighter grammar** — data-driven moves, startup/active/recovery, hitlag, hitstun, knockback scaling, shields, grabs, throws, DI, stale move decay, and deterministic tests.

**Milestone 3 is about combat grammar and hit reaction truth. It is not about roster expansion, CPU, training UI, items, online, or visual polish.**

---

## In scope

1. Shared default move catalog with full frame data taxonomy.
2. Deterministic move selection from `InputFrame` + `PlayerState`.
3. Combat state machine hardening (shield stun/break, grab/throw, dodge/roll/air dodge).
4. Hit resolution: hitlag, hitstun, knockback scaling, multi-hit intervals, stale decay, DI.
5. Shield grammar: health, stun, pushback, break, regen.
6. Grab/throw loop (grab beats shield).
7. Regression tests + manual playtest template.
8. Minimal debug panel combat lines.

---

## Out of scope (Milestone 4+)

- New fighters / roster expansion
- CPU, training mode UI, items
- Online, netplay, Godot, Edge-IO, career, story
- Menu redesign, smash charge, complex cancel trees
- Full visual polish

---

## Pre-implementation audit (baseline after Milestone 2)

| Area | State before M3 |
|------|-----------------|
| Attack start | `startAction` in `combat.ts`; fighter moves or legacy move ids |
| Move selection | `resolveMoveSlotFromInput` partial; no dash attack, no back air vs facing |
| Frame data | `frameData.ts` legacy + `moveDefinitions.ts` per-fighter builder |
| Startup/active/recovery | `isInStartup/Active/Recovery` + `movePhases.ts` |
| Hitboxes | Fixed sizes in `collision.ts`; not catalog-driven |
| Hurtboxes | `getHurtbox` with size scaling |
| Hitlag | `computeHitlag` → global `hitstopFrames` |
| Hitstun | `computeHitstun` from strength + damage % |
| Knockback | `computeKnockback` with weight/growth |
| Shield | Hold shield drains health passively; no shield stun/pushback/break grammar |
| Grabs/throws | Input exists; **not implemented** |
| DI | `di.ts` exists; **not wired** into hit resolution |
| Stale moves | **Not implemented** |
| Multi-hit | `multiHit` flag on frame data; limited interval logic |
| Dodge | Ground dodge only; no roll/air dodge distinction |
| Renderer/debug | `actionState`, `currentMoveId`, `actionFrame`; no phase/stale/shield stun |

---

## Files touched

| Area | Files |
|------|-------|
| Catalog | `moves/defaultMoveCatalog.ts`, `moves/combatMoveData.ts` |
| Selection | `combat/moveSelection.ts` |
| State | `combat/combatState.ts`, `types.ts`, `state.ts` |
| Shield | `combat/shieldSystem.ts` |
| Grab/throw | `combat/grabSystem.ts` |
| Dodge | `combat/dodgeSystem.ts` |
| Stale/DI | `combat/staleMoves.ts`, `combat/di.ts`, `combat/hitResolution.ts` |
| Integration | `combat.ts`, `collision.ts`, `simulate.ts`, `playerLifecycle.ts` |
| Tests | `test/milestone3CombatGrammar.test.ts` |
| Web | `apps/web/src/game/debugPanel.ts` |
| Docs | This file, `docs/playtest/2026-06-24-m3-combat-grammar.md` |

---

## Acceptance tests (automated)

42 scenarios in `packages/game-core/test/milestone3CombatGrammar.test.ts` (move selection, phases, hits, shield, grab/throw, DI, stale, dodge, lifecycle, regression).

---

## Manual playtest requirements

See `docs/playtest/2026-06-24-m3-combat-grammar.md`. **Manual browser verification required by product owner** — do not fake checks.

---

## Known risks

- Fighter-specific move ids (`ember:sideAttack`) coexist with catalog ids; lookup order must stay deterministic.
- Grab vs ledge grab naming collision (`grabbedLedgeId` vs combat grab).
- Shield regen tuning may need playtest adjustment.

---

## Definition of done

- [x] `npm run typecheck` passes
- [x] `npm test` passes
- [x] `npm run build` passes
- [x] This doc + playtest record exist
- [x] All 42 M3 tests pass
- [x] No Milestone 4+ systems introduced
- [ ] Manual playtest checklist provided (unchecked)
