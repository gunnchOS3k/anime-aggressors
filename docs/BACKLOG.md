# Backlog

**Last updated:** 2026-06-24  
**Priority:** P0 = blocking milestone · P1 = important · P2 = nice-to-have  
**Milestones:** v0.1 · v0.5 · v1.0 · future  
**Program tracks:** A–H — see `docs/ROADMAP_FULL_COMPLETION.md`

Each item includes title, rationale, acceptance criteria, priority, milestone, and **track label** where applicable.

### Track legend

| Track | Focus |
|-------|-------|
| **A** | Full deterministic web game |
| **B** | Rollback / online |
| **C** | C++ engine |
| **D** | Mobile |
| **E** | Desktop |
| **F** | Edge-IO dev-board mule |
| **G** | Production hardware |
| **H** | Production quality / polish |

---

## Product

### Full-completion roadmap docs
- **Why:** Product is parallel tracks A–H, not vertical-slice-only.
- **Acceptance:** `ROADMAP_FULL_COMPLETION.md`, updated STATUS/ARCHITECTURE/PRD.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** A0 · **Status:** Done

### README honesty pass
- **Why:** Prior README oversold Godot, mobile, desktop, hardware.
- **Acceptance:** README lists only verified capabilities; links to STATUS.md.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** A · **Status:** Done

### Product requirements document
- **Why:** Contributors and investors need measurable compass.
- **Acceptance:** `docs/PRODUCT_REQUIREMENTS.md` with 37 sections and measurable reqs.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Done

### Consolidate legacy `web/` React app
- **Why:** Two web stacks cause confusion (`web/` vs `apps/web`).
- **Acceptance:** Single canonical path documented; legacy archived or merged.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** A0 · **Status:** Done (`legacy/web/`)

### Public demo landing polish
- **Why:** v0.5 needs shareable first impression.
- **Acceptance:** Lighthouse TTI < 2 s; mobile-readable hero.
- **Priority:** P1 · **Milestone:** v0.5

---

## Gameplay

### Deterministic game-core
- **Why:** Foundation for rollback, replay, online.
- **Acceptance:** 60 Hz sim; determinism + combat tests pass; no DOM in package.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** A · **Status:** Done

### Local 2-player vertical slice
- **Why:** Core product proof — couch platform fighter.
- **Acceptance:** Select → fight → results → rematch in browser; 2P keyboard/gamepad.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** A1 · **Status:** Done

### Third character + second stage
- **Why:** Roster depth for public demo.
- **Acceptance:** 3 selectable characters; 2 stages in config.
- **Priority:** P1 · **Milestone:** v0.5

### Cancel routes and combo scaling
- **Why:** Shōnen fighter identity vs generic brawler.
- **Acceptance:** Documented frame data; at least 2 cancel routes per character.
- **Priority:** P2 · **Milestone:** v1.0

### Training mode (dummy, frame step)
- **Why:** Competitive players need lab tools.
- **Acceptance:** Spawn dummy; pause/step frames; input display.
- **Priority:** P1 · **Milestone:** v0.5

---

## Rollback

### Rollback harness package
- **Why:** Same sim path for couch, online, replay.
- **Acceptance:** Wrong prediction test; desync detection; rollback count exposed.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** B0 · **Status:** Done

### Couch artificial delay mode
- **Why:** Exercise prediction/rollback without network.
- **Acceptance:** Configurable 2–8 frame delay; rollbackCount > 0 in debug during play.
- **Priority:** P1 · **Milestone:** v0.5

### Online transport layer
- **Why:** Public demo online matches.
- **Acceptance:** Two browsers sync hash at frame 600+; disconnect UI.
- **Priority:** P1 · **Milestone:** v0.5

### Binary state serialization
- **Why:** Cross-browser float/JSON determinism risk.
- **Acceptance:** serialize/deserialize binary; hash stable Chrome vs Firefox.
- **Priority:** P1 · **Milestone:** v0.5

---

## Online multiplayer

### WebRTC or UDP input relay spike
- **Why:** Validate latency assumptions.
- **Acceptance:** Input frames exchanged; measured RTT logged.
- **Priority:** P1 · **Milestone:** v0.5

### Matchmaking stub
- **Why:** v1.0 online UX.
- **Acceptance:** Create/join room code; 2 players matched.
- **Priority:** P2 · **Milestone:** v1.0

---

## Input

### Input-frame abstraction
- **Why:** Rollback boundary; wearable + keyboard unity.
- **Acceptance:** Sim accepts only InputFrame; documented in INPUT_SYSTEM.md.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Done

### Keyboard listener lifecycle fix
- **Why:** Repeated listeners caused stuck/multiple inputs.
- **Acceptance:** Singleton keyboard; DevTools shows one keydown/keyup pair after 10 min play.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Done

### Input remapping UI
- **Why:** Accessibility and player preference.
- **Acceptance:** All actions rebindable; persisted localStorage.
- **Priority:** P1 · **Milestone:** v0.5

### Touch controls (mobile web)
- **Why:** Reach without controller.
- **Acceptance:** Complete match on 375px viewport.
- **Priority:** P1 · **Milestone:** v0.5

### 3–4 player device assignment
- **Why:** Party fighter vision.
- **Acceptance:** 4 InputFrames per tick; assignment UI.
- **Priority:** P2 · **Milestone:** v1.0

---

## Edge-IO

### Edge-IO protocol unification
- **Why:** TS binary parser vs firmware JSON mismatch.
- **Acceptance:** EDGE_IO_PROTOCOL.md canonical; parser tests pass; firmware migration plan.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Done (TS side)

### Web Bluetooth pairing UI
- **Why:** Demo wearable without native app.
- **Acceptance:** Connect button; gesture in debug overlay.
- **Priority:** P1 · **Milestone:** v0.5

### Fake IMU / gesture simulator in browser
- **Why:** Test without hardware.
- **Acceptance:** Dev panel injects GestureNotify packets.
- **Priority:** P2 · **Milestone:** v0.5

---

## Firmware

### Firmware stack decision
- **Why:** Wrong BLE stack blocks nRF52840 bring-up.
- **Acceptance:** ADR-0001 recorded with recommendation and migration triggers.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Done

### Firmware compile fix (nRF52840 DK)
- **Why:** Cannot validate protocol on silicon until build works.
- **Acceptance:** `pio run -e nrf52840_dk` succeeds; documented in VALIDATION_REPORT.
- **Priority:** P0 · **Milestone:** v0.5

### Binary BLE notify implementation
- **Why:** Match EDGE_IO_PROTOCOL.md.
- **Acceptance:** SensorNotify + GestureNotify on wire; sniffer hex matches spec.
- **Priority:** P0 · **Milestone:** v0.5

### HapticWrite handler
- **Why:** Close loop wearable feedback.
- **Acceptance:** Host write triggers actuator on bench.
- **Priority:** P1 · **Milestone:** v0.5

### Nordic DFU path
- **Why:** Field updates without SWD.
- **Acceptance:** Documented flash + OTA test on DK.
- **Priority:** P2 · **Milestone:** v1.0

---

## Hardware

### Hardware EVT requirements matrix
- **Why:** Prevent fake fabrication claims.
- **Acceptance:** HARDWARE_PROTOTYPE_PLAN.md with validation matrix and file expectations.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Done

### Wearable bring-up checklist
- **Why:** Repeatable bench → wrist validation.
- **Acceptance:** `hardware/wristband/test/bringup-checklist.md` executable steps.
- **Priority:** P0 · **Milestone:** v0.1 · **Status:** Documented in HARDWARE_PROTOTYPE_PLAN

### Dev-board mule BOM (canonical CSV)
- **Why:** Procurement needs structured BOM.
- **Acceptance:** CSV with required columns; TBD where unverified.
- **Priority:** P1 · **Milestone:** v0.5

### Wristband EVT PCB
- **Why:** Integrated form factor after mule.
- **Acceptance:** KiCad project in repo; 5 boards assembled; HW validation matrix started.
- **Priority:** P2 · **Milestone:** v1.0

### Ring form factor PCB
- **Why:** Long-term product vision.
- **Acceptance:** EVT after wristband pass; no ring before mule demo.
- **Priority:** P2 · **Milestone:** future

---

## Art / audio

### Placeholder → readable silhouettes
- **Why:** Playtesters must read player positions.
- **Acceptance:** Distinct silhouettes per character; KO flash visible.
- **Priority:** P1 · **Milestone:** v0.5

### Hit SFX + UI audio
- **Why:** Combat satisfaction.
- **Acceptance:** Attack connect + KO sounds; mute toggle.
- **Priority:** P2 · **Milestone:** v0.5

### Toon-shaded art pipeline
- **Why:** v1.0 visual identity.
- **Acceptance:** Art bible + sprite rig spec.
- **Priority:** P2 · **Milestone:** v1.0

---

## QA

### CI quality workflow
- **Why:** Merge bar for determinism regressions (Track A0).
- **Acceptance:** `.github/workflows/quality.yml` runs typecheck + test + build on PR.
- **Priority:** P0 · **Milestone:** v0.1 · **Track:** A0 · **Status:** In progress

### Native C++ engine skeleton
- **Why:** Track C performance path without blocking web ship.
- **Acceptance:** `native/engine` CMake + determinism test in CI.
- **Priority:** P1 · **Milestone:** v0.5 · **Track:** C1–C2 · **Status:** Done (skeleton)

### Desktop shell (Tauri)
- **Why:** Track E distribution path.
- **Acceptance:** ADR-0002; minimal scaffold loads web build.
- **Priority:** P2 · **Milestone:** v1.0 · **Track:** E0–E1 · **Status:** E0 done

### Mobile Expo scaffold
- **Why:** Track D companion/playable research.
- **Acceptance:** `apps/mobile/PRODUCT_SCOPE.md`; optional typecheck when valid.
- **Priority:** P2 · **Milestone:** v0.5 · **Track:** D0–D1 · **Status:** D0 done

### VALIDATION_REPORT.md per milestone
- **Why:** Honest record of what was run.
- **Acceptance:** Commands, pass/fail, blockers listed.
- **Priority:** P1 · **Milestone:** v0.1

### Manual playtest script
- **Why:** Repeatable human verification.
- **Acceptance:** 3-match script in docs; signed by tester.
- **Priority:** P1 · **Milestone:** v0.5

### Cross-browser determinism suite
- **Why:** Online lockstep confidence.
- **Acceptance:** Chrome + Firefox hash match automated.
- **Priority:** P1 · **Milestone:** v0.5

---

## Release

### v0.1 internal release sign-off
- **Why:** Close vertical slice milestone.
- **Acceptance:** RELEASE_CHECKLIST v0.1 section checked.
- **Priority:** P0 · **Milestone:** v0.1

### GitHub Pages deploy for v0.5
- **Why:** Shareable public demo.
- **Acceptance:** URL live; cold load works.
- **Priority:** P1 · **Milestone:** v0.5

---

## Business / legal

### Original IP audit
- **Why:** No third-party anime/fighter infringement.
- **Acceptance:** Character/move/stage names reviewed; documented clean.
- **Priority:** P1 · **Milestone:** v0.5

### Privacy policy for telemetry
- **Why:** v0.5 opt-in analytics.
- **Acceptance:** Published policy; no IMU upload without consent.
- **Priority:** P2 · **Milestone:** v0.5

### Edge-IO retail SKU business case
- **Why:** Optional hardware revenue path.
- **Acceptance:** BOM cost + target MSRP spreadsheet.
- **Priority:** P2 · **Milestone:** v1.0

---

## P0 summary tracker

| # | Item | Milestone | Status |
|---|------|-----------|--------|
| 1 | README honesty pass | v0.1 | Done |
| 2 | Product requirements document | v0.1 | Done |
| 3 | Deterministic game-core | v0.1 | Done |
| 4 | Local 2-player vertical slice | v0.1 | Done |
| 5 | Rollback harness | v0.1 | Done |
| 6 | Input-frame abstraction | v0.1 | Done |
| 7 | Keyboard listener lifecycle fix | v0.1 | Done |
| 8 | Edge-IO protocol unification (TS) | v0.1 | Done |
| 9 | Firmware stack decision | v0.1 | Done |
| 10 | Hardware EVT requirements matrix | v0.1 | Done |
| 11 | Wearable bring-up checklist | v0.1 | Documented |
| 12 | CI quality workflow | v0.1 | Open |

---

## Related documents

- [ROADMAP_FULL_COMPLETION.md](./ROADMAP_FULL_COMPLETION.md)
- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md)
- [AUDIT_ACTION_PLAN.md](./AUDIT_ACTION_PLAN.md)
- [STATUS.md](./STATUS.md)
- [PULL_REQUEST_CHECKLIST.md](./PULL_REQUEST_CHECKLIST.md)
