# Anime Aggressors — Status

**Last updated:** 2026-06-24  
**Branch:** `revive-product-rollback-vertical-slice`  
**Milestone:** v0.1 deterministic web vertical slice

This document is the honest capability matrix. If something is not listed under **Playable today**, assume it is not shipped.

---

## Playable today

| Capability | Evidence | How to verify |
|------------|----------|---------------|
| 2-player local couch match (keyboard + gamepad) | `apps/web/src/game/App.ts`, `deviceAssignment.ts` | `npm run dev -w apps/web` → **Play Anime Aggressors Vertical Slice** |
| Character select (2 original characters) | `packages/game-core/src/characters.ts` — Ember Vale, Tide Kuro | Select P1/P2 on character screen |
| Match flow: countdown → fighting → results → rematch | `simulate.ts`, `App.ts`, `results.ts` | Play until stocks depleted or timer expires |
| Fixed 60 Hz deterministic simulation | `packages/game-core/src/constants.ts` (`SIM_HZ = 60`) | Run `npm run test -w packages/game-core` |
| Deterministic state hash + replay | `hash.ts`, `replay.ts`, determinism tests | Tests: same inputs → same hash; replay matches step sim |
| Local rollback harness (unit-tested) | `packages/rollback/src/rollbackSession.ts` | `npm run test -w packages/rollback` |
| Canvas renderer with debug overlay | `renderCanvas.ts`, `debugOverlay.ts` | Toggle Debug / Hitboxes in vertical slice toolbar |
| Keyboard singleton (no per-frame listener leak) | `apps/web/src/input/keyboard.ts` | Inspect `initialized` guard; play 5+ minutes without duplicate handlers |
| Gamepad auto-assignment (pad 0 → P1, pad 1 → P2) | `deviceAssignment.ts` | Connect two controllers; verify slot mapping |
| Edge-IO binary protocol parse/encode (software) | `packages/edgeio/src/parser.ts`, tests | `npm run test -w packages/edgeio` |
| Training Lab mini-games (prototype) | `apps/web/src/minigames/*` | **Open Training Lab** on landing page |
| Monorepo quality scripts | Root `package.json`: `typecheck`, `test`, `build`, `quality` | `npm run quality` from repo root |

---

## Prototype quality

These work for demos and engineering validation but are not product-complete.

| Item | Current state | Gap to v0.5 |
|------|---------------|-------------|
| Combat feel | Basic attack/special/shield/dodge/grab with percent + knockback | Cancel routes, combo scaling, frame data tuning |
| Art | Colored rectangles + character names | Sprite rigs, VFX, readable hit flash |
| Audio | None in vertical slice | Hit SFX, UI sounds, music stubs |
| Rollback in live match | `RollbackSession` wired; couch uses `[true, true]` confirmed inputs | Inject artificial delay + prediction for couch parity with online |
| Edge-IO in browser | Mapper + fake packet generators; no Web Bluetooth UI | BLE connect flow, latency measurement |
| Characters | 2 stats-differentiated originals | 4+ roster, unique specials |
| Stages | 1 stage (`skyline-arena`) | 2+ with hazards |
| CI | `ci.yml` builds `apps/web` only | Full workspace `quality` gate on every PR |
| Legacy web tree | Root `web/` React app still present | Consolidate or archive |

---

## Planned

| Item | Target milestone | Owner area |
|------|------------------|------------|
| Online rollback transport (UDP/WebRTC) | v0.5 | `packages/rollback` + cloud worker |
| 3–4 player local | v0.5 | `game-core`, input assignment |
| Input buffering (1–3 frames) | v0.5 | `apps/web/src/input` |
| Remapping UI | v0.5 | Web settings |
| Touch controls (mobile web) | v0.5 | New input module |
| Web Bluetooth Edge-IO pairing | v0.5 | `packages/edgeio` + web app |
| Firmware binary protocol on dev board | v0.5 | `firmware/ring` |
| Wristband dev-board mule EVT | v0.5 | `hardware/wristband` |
| Replay file export/import | v1.0 | `game-core` + web |
| Tournament mode | v1.0 | Product |
| Production art pipeline | v1.0 | Art |

---

## Broken / unknown

| Item | Symptom | Likely cause | Status |
|------|---------|--------------|--------|
| Firmware compile on target | Not verified in CI | `main.cpp` uses ESP32-style `BLEDevice.h` on nRF52840 Arduino; JSON notify vs binary protocol | **Blocked** — see ADR-0001 |
| Real BLE end-to-end | No hardware-in-loop test | Firmware/protocol mismatch; no validated PCB | **Not tested** |
| Root legacy `web/` app | May diverge from `apps/web` | Two web stacks in repo | **Unknown** — needs audit |
| Godot / C++ engine paths | Referenced in old README | Placeholder or removed | **Not present** in active vertical slice |
| Mobile (Expo) / Desktop (Electron) | Old README claims | No workspace packages | **Not implemented** |
| Cloud worker leaderboards | `cloud/worker/` exists | Not wired to vertical slice | **Scaffold only** |
| Floating-point determinism across browsers | Uses JSON serialize + JS numbers | Acceptable for v0.1; cross-platform lockstep needs audit | **Risk** — monitor in QA |

---

## Deferred

| Item | Reason |
|------|--------|
| Custom ring PCB fabrication | Wristband/dev-board mule first; no KiCad project in repo |
| Zephyr/NCS firmware migration | Deferred until Adafruit mule proves protocol |
| 6G / ReadyGary integration | Out of product scope |
| Mod marketplace | Post v1.0 |
| AI opponents | Post v1.0 |
| Full haptic choreography | Requires validated DRV2605L hardware path |
| Anti-cheat / server authority | Online milestone |

---

## Hardware readiness

| Gate | Status | Notes |
|------|--------|-------|
| Target BOM documented | Partial | `hardware/wristband/bom.csv`, `hardware/ring/bom.csv` — minimal, not EVT-complete |
| KiCad project (`edgeio-ring.kicad_*`) | **Missing** | Do not claim fabrication-ready |
| Gerbers / pick-place / STEP | **Missing** | See `docs/HARDWARE_PROTOTYPE_PLAN.md` for file expectations |
| Dev-board mule plan | Documented | nRF52840 DK + IMU breakout + DRV2605L recommended first |
| EVT validation matrix | Documented | `hardware/ring/test/` checklists planned |
| Safety review (battery/charging) | **Not started** | Required before wearable EVT |
| Measured latency on silicon | **Not measured** | Target: gesture-to-host notify p50 < 50 ms (PRD) |

**Hardware readiness score:** **Prototype planning** — not EVT, not DVT, not PVT.

---

## Firmware readiness

| Gate | Status | Notes |
|------|--------|-------|
| PlatformIO config | Present | `firmware/ring/platformio.ini` — nRF52840 DK targets |
| Canonical binary protocol in firmware | **No** | TS parser expects binary; firmware sends JSON strings |
| BLE service/characteristic layout | **Placeholder UUIDs** | Must align with `docs/EDGE_IO_PROTOCOL.md` |
| IMU driver validated on board | **Unknown** | BMI270/ICM-42688 references; not CI-built |
| Haptic write path | **Scaffold** | DRV2605L calls present; not hardware-tested |
| DFU / OTA | **Planned** | Nordic DFU suggested in firmware notes |
| CI firmware build | **Not in CI** | Documented future gate |

**Firmware readiness score:** **Bring-up planning** — compile status unverified; protocol migration required.

---

## Release readiness

| Stage | Status | Blockers |
|-------|--------|------------|
| **v0.1 vertical slice (internal)** | **In progress / near** | CI quality workflow; validation report |
| **v0.5 public demo** | Not ready | Online play, polish, Edge-IO dev board, remapping |
| **v1.0 commercial** | Not started | Content, art, platforms, hardware optional SKU |

### v0.1 exit criteria (measurable)

- [x] `packages/game-core` tests pass (determinism, combat)
- [x] `packages/rollback` tests pass (rollback + desync detection)
- [x] `packages/edgeio` protocol tests pass
- [x] Web vertical slice: select → fight → results → rematch
- [ ] `npm run quality` green on CI for full workspace
- [x] `docs/PRODUCT_REQUIREMENTS.md` and honest `README.md`
- [ ] `docs/VALIDATION_REPORT.md` with command results
- [ ] Firmware stack decision recorded (ADR-0001)

---

## Quick commands

```bash
cd /path/to/anime-aggressors
npm install
npm run quality          # typecheck + test + web build
npm run dev              # launches apps/web on Vite dev server
npm run test -w packages/game-core
npm run test -w packages/rollback
npm run test -w packages/edgeio
```
