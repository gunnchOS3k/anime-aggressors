# QA Test Plan — Production Completion

**Last updated:** 2026-07-01  
**Acceptance bar:** `docs/FULL_GAME_ACCEPTANCE_CRITERIA.md`

---

## Automated gates (required every merge)

```bash
npm run typecheck
npm test
npm run build
```

---

## Test layers

| Layer | Location | Coverage |
|-------|----------|----------|
| Engine movement/combat | `packages/game-core/test/productionCompletion.test.ts` | Spawn reach, hits, roster, stages, CPU, training |
| Navigation | `apps/web/test/productionNavigation.test.ts` | Start flow, Quick Play, reset state |
| Milestone regression | `packages/game-core/test/milestone*.test.ts` | Movement, combat grammar, roster |
| Input | `apps/web/test/playerInputMapping.test.ts` | P1/P2 profiles |

---

## Manual smoke (required before “complete”)

Use `docs/playtest/2026-07-01-full-game-completion-check.md`.

Minimum path:

1. Fresh load → Home, no console errors
2. Start Game → Fighter → Stage → Ready → Battle
3. Quick Play → Battle in ≤3 clicks
4. Move, attack, KO, respawn, results, rematch
5. Training: reset damage/position, dummy modes
6. CPU Lv1–3 from Ready Check
7. Audio/VFX on hit, shield, KO

---

## Severity triage

Use `docs/BUG_SEVERITY_RUBRIC.md`. **No P0/P1** open for completion sign-off.

---

## Release verification

See `docs/RELEASE_CHECKLIST.md`.
