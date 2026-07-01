# Release Checklist

**Last updated:** 2026-07-01  
Use this checklist before claiming a release. Check only items that are **verified** with evidence (CI log, test output, video, sign-off).

---

## Production completion — local platform fighter (2026-07-01)

### Automated gates

- [x] `npm run typecheck` passes
- [x] `npm test` passes (364 tests)
- [x] `npm run build` passes

### Product flow

- [x] Home → Start Game → Fighter Select → Stage Select → Ready → Battle (wired)
- [x] Quick Play → Battle (≤3 clicks)
- [x] Labs separated from main menu
- [x] Reset Game State on Home
- [ ] Manual browser playtest signed (`docs/playtest/2026-07-01-full-game-completion-check.md`)

### Gameplay

- [x] Movement scale: P1 reaches P2 in 2–4s (automated)
- [x] Combat: point-blank and approach hits connect (automated)
- [x] CPU Lv1–3 selectable in Ready Check
- [x] All 7 fighters + 3 production stages validated in tests

### Docs

- [x] `docs/PRODUCTION_COMPLETION_PLAN.md`
- [x] `docs/FULL_GAME_ACCEPTANCE_CRITERIA.md`
- [x] `docs/PRODUCTION_BLOCKERS.md`
- [x] `docs/BUG_SEVERITY_RUBRIC.md`
- [x] `docs/PLAYER_MANUAL.md`, `docs/CONTROLS.md`, `docs/QA_TEST_PLAN.md`

---

## Pre-release (all milestones)

- [ ] Branch named and tagged (`v0.1.0`, etc.)
- [ ] `docs/STATUS.md` reflects current reality
- [ ] `docs/VALIDATION_REPORT.md` updated with commands run
- [ ] No secrets committed (.env, keys)
- [ ] LICENSE and third-party notices current
- [ ] README honest — no oversold platforms

---

## v0.1 — Deterministic web vertical slice (internal)

### Build & test

- [ ] `npm install` succeeds (Node ≥ 20)
- [ ] `npm run typecheck` — all workspaces pass
- [ ] `npm run test` — game-core, rollback, edgeio pass
- [ ] `npm run build:web` — dist produced
- [ ] `npm run quality` — full pipeline green

### Gameplay

- [ ] Landing page loads; **Play Vertical Slice** works
- [ ] Character select: Ember Vale + Tide Kuro
- [ ] 2P match completable (keyboard and/or gamepads)
- [ ] Stocks, blast zones, timer function
- [ ] Results screen shows winner
- [ ] Rematch resets state correctly
- [ ] Debug overlay: frame, hash, inputs, rollback count
- [ ] Hitbox toggle renders overlays

### Architecture

- [ ] `packages/game-core` has no DOM/browser imports
- [ ] RollbackSession wired in `App.ts`
- [ ] Determinism tests pass (hash match)
- [ ] Rollback wrong-prediction test passes

### Documentation

- [ ] `docs/PRODUCT_REQUIREMENTS.md` complete (37 sections)
- [ ] `docs/ARCHITECTURE.md`, `ROLLBACK_DESIGN.md`, `INPUT_SYSTEM.md`
- [ ] `docs/EDGE_IO_PROTOCOL.md` matches parser
- [ ] `docs/BACKLOG.md` with P0 items
- [ ] `docs/decisions/ADR-0001-firmware-stack.md`
- [ ] README rewritten (honest)

### Known acceptable gaps for v0.1

- Online multiplayer not required
- Real BLE hardware not required
- Production art/audio not required
- Firmware binary protocol migration may be open if documented

---

## v0.5 — Public demo

### Build & deploy

- [ ] CI `quality` workflow required on main
- [ ] Static deploy (GitHub Pages or equivalent) live
- [ ] Demo URL in README works on cold load
- [ ] HTTPS enabled

### Gameplay & content

- [ ] 3+ characters, 2+ stages
- [ ] Input remapping UI persists
- [ ] Training mode or frame-step debug
- [ ] Replay export (JSON input log minimum)
- [ ] Online 2P rollback match between two browsers
- [ ] Artificial delay couch test shows rollback > 0 in debug

### Edge-IO

- [ ] Web Bluetooth connects to dev-board mule OR blocker documented
- [ ] GestureNotify → dodge/attack in vertical slice
- [ ] Latency p50 measured and recorded (< 50 ms target)

### Quality

- [ ] 10 external playtesters complete match without assist
- [ ] `QUALITY_BAR.md` v0.5 columns reviewed
- [ ] Zero open P0 bugs for demo scope

### Legal & privacy

- [ ] Original IP review complete
- [ ] Privacy notice for opt-in telemetry
- [ ] Dependency audit (`npm audit` reviewed)

---

## v1.0 — Commercial-quality release

### Product

- [ ] 8+ characters, 4+ stages, training mode
- [ ] Ranked/casual online with basic matchmaking
- [ ] Full art/audio pass
- [ ] WCAG 2.1 AA audit passed (web)
- [ ] Mobile touch layout shippable

### Hardware (optional SKU)

- [ ] Wristband EVT validation matrix passed
- [ ] DFU documented and tested
- [ ] Battery safety review complete
- [ ] Retail packaging spec (if selling)

### Engineering

- [ ] Crash-free sessions > 99.9% in beta
- [ ] Cross-browser determinism suite green
- [ ] Performance budgets in `QUALITY_BAR.md` met
- [ ] Security review (BLE, web, server)

### Business

- [ ] Store/platform accounts ready
- [ ] Support / refund policy
- [ ] ESRB or regional rating if required

---

## Sign-off template

```markdown
## Release: v0.X.Y
Date:
Branch/tag:
Validator:

### Commands
- npm run quality: PASS/FAIL
- Manual playtest: PASS/FAIL
- Deploy smoke: PASS/FAIL

### Open P0 bugs
- (none / list)

### Sign-off
- [ ] Product
- [ ] Engineering
- [ ] QA
```

---

## Related documents

- [STATUS.md](./STATUS.md)
- [QUALITY_BAR.md](./QUALITY_BAR.md)
- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) §29, §34
