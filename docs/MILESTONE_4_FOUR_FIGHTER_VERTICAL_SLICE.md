# Milestone 4 — Four-Fighter Vertical Slice

**Status:** Complete (pending manual playtest)  
**Branch:** `feat/milestone-4-four-fighter-vertical-slice`  
**Last updated:** 2026-06-30

---

## Goal

Ship a **playable vertical slice** with four production-validated fighters, three production stages, full 7-fighter select (with preview badges), CPU levels 1–3, training basics, and 2-player gamepad hardening — **without** inventing a parallel roster.

`DEFAULT_FIGHTERS` (7) remains the single source of truth.

---

## Roster classification

| Status | Fighters | Notes |
|--------|----------|-------|
| **Production** | Ember Vale, Rook Ironside, Juno Spark, Kaia Windrow | Balance tests, CPU/training coverage, quick-match defaults |
| **Preview** | Nix Calder, Orion Vell, Vesper Nyx | Selectable, mechanically valid, balance-pending badge |

### Helpers (`fighterGameplayProfiles.ts`)

- `getProductionFighters()` — 4 production profiles
- `getPreviewFighters()` — 3 preview profiles
- `getPlayableRoster()` — all 7 `DEFAULT_FIGHTERS`
- `getFighterGameplayProfile(id)` — status, archetype, movement tuning

---

## Production stages

| Stage | Type | Layout |
|-------|------|--------|
| Training Grid | Flat | Single main platform |
| Skyline Arena | Three-platform | Classic duel |
| Neon Rooftops | Casual | Asymmetric catwalks |

---

## Systems delivered

1. **Move tuning** — per-fighter overrides on real IDs (`fighterMoveTuning.ts`); Vesper Nyx preview projectile on neutral special.
2. **Versus CPU** — levels 1–3 via `versusCpu.ts` + `cpuOpponents` on `GameConfig`.
3. **Training** — training-rules preset, flat grid, dummy behaviors (idle/shield/jump/CPU), D/P reset keys.
4. **Web** — production/preview badges, production stage filter, quick match (Ember vs Rook), gamepad auto-map.
5. **Tests** — `milestone4FourFighterVerticalSlice.test.ts`, web roster/device tests; 7-fighter regression restored.

---

## Out of scope (Milestone 5+)

- Menu polish, online/ranked, items, career/story
- Godot runtime, Edge-IO wearable
- Roster expansion beyond 7 defaults
- Fake manual playtest sign-off

---

## Quality gates

```bash
npm run typecheck
npm test
npm run build
```

---

## Manual playtest

See `docs/playtest/2026-06-30-m4-four-fighter-vertical-slice.md` (unchecked until human run).
