# Audit Action Plan

**Source:** Repo honesty pass (2026-06-24) on `gunnchOS3k/anime-aggressors`  
**Goal:** Move from oversold README/scaffold to a measurable v0.1 rollback-first vertical slice with a credible hardware prototype path.

---

## Audit findings summary

| ID | Finding | Severity | Area |
|----|---------|----------|------|
| A-01 | README claimed Godot, mobile, desktop, production hardware not present | P0 | Docs |
| A-02 | Playable path was mini-games, not platform fighter sim | P0 | Product |
| A-03 | No deterministic `game-core` or rollback harness | P0 | Engine |
| A-04 | Keyboard listeners could attach repeatedly | P0 | Input |
| A-05 | Edge-IO TS parser = binary; firmware = JSON strings | P0 | Edge-IO |
| A-06 | Firmware BLE stack likely wrong for nRF52840 target | P0 | Firmware |
| A-07 | Hardware docs described parts without KiCad/Gerbers/BOM gates | P0 | Hardware |
| A-08 | CI only built legacy `apps/web`, not full workspace quality | P1 | CI |
| A-09 | Duplicate web stacks (`web/` vs `apps/web`) | P1 | Architecture |
| A-10 | Floating-point + JSON state serialize — cross-browser determinism unproven | P2 | Rollback |
| A-11 | No PRD with measurable acceptance criteria | P0 | Product |
| A-12 | Cloud worker / messages packages orphaned from vertical slice | P2 | Cloud |

---

## Phase 0 — Honesty & status (Week 0)

**Objective:** Stop misleading contributors and investors.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| Rewrite README | Honest capability list, run instructions | No false Godot/mobile/desktop claims | Done |
| Create STATUS.md | Playable / broken / deferred matrix | All sections populated | Done |
| Create AUDIT_ACTION_PLAN.md | This document | Phased plan with owners | Done |
| Archive or label legacy `web/` | README note or redirect | Single canonical web app path | Open |

**Exit gate:** New contributor can run vertical slice in < 10 minutes using README only.

---

## Phase 1 — Product compass (Week 0–1)

**Objective:** Canonical requirements every change traces to.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| PRODUCT_REQUIREMENTS.md | 37 sections, measurable reqs | Reviewable by intern/advisor | Done |
| BACKLOG.md | P0–P2 grouped backlog | 12 minimum P0 items listed | Done |
| QUALITY_BAR.md | AAA-inspired measurable standards | No vague "AAA complete" language | Done |

**Exit gate:** Any feature PR cites PRD section + acceptance criterion.

---

## Phase 2 — Deterministic core + rollback (Week 1–2)

**Objective:** One simulation path for couch, online, replay, debug.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| `packages/game-core` | 60 Hz sim, 2 chars, 1 stage | Determinism tests green | Done |
| `packages/rollback` | Snapshots, prediction, resim | Wrong prediction → rollback → hash match | Done |
| ROLLBACK_DESIGN.md | Architecture doc | Explains couch-first rollback rationale | Done |
| INPUT_SYSTEM.md | Input abstraction spec | InputFrame-only sim boundary | Done |

**Exit gate:** `npm run test -w packages/game-core && npm run test -w packages/rollback` pass locally and in CI.

---

## Phase 3 — Web vertical slice (Week 2–3)

**Objective:** Playable couch demo sharing sim with rollback package.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| Canvas vertical slice UI | Select → fight → results → rematch | 2P keyboard/gamepad playable | Done |
| Debug overlay | Frame, hash, inputs, rollback count | Toggle in UI | Done |
| Keyboard singleton fix | One listener pair | No duplicate handlers over time | Done |
| Wire RollbackSession in App | Same path as future online | Uses `advanceFrame` each tick | Done (couch confirms all inputs) |

**Follow-up (Phase 3b):** Simulate network delay in couch mode to exercise prediction/rollback in live play.

**Exit gate:** Manual playtest 3 matches without crash; rematch works.

---

## Phase 4 — Edge-IO unification (Week 3–4)

**Objective:** One binary protocol from firmware spec → TS parser → InputFrame mapper.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| EDGE_IO_PROTOCOL.md | Canonical packet layouts | Matches `packages/edgeio/src/parser.ts` | Done |
| Parser tests | Sensor, gesture, haptic | `npm run test -w packages/edgeio` | Done |
| Firmware PROTOCOL.md + migration | Binary notify implementation plan | ADR-0001 stack decision | In progress |
| Web Bluetooth pairing UI | Connect + map gestures | Gesture appears in debug overlay | Planned v0.5 |

**Exit gate:** Loopback test: fake gesture packet → mapped InputFrame → sim accepts without special case.

---

## Phase 5 — Firmware reality (Week 4–6)

**Objective:** Dev-board firmware that speaks canonical binary protocol.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| ADR-0001 | Stack recommendation | Adafruit vs Zephyr decision recorded | Done |
| Fix or document compile blockers | firmware/ring/README.md, BRINGUP.md | `pio run` result recorded honestly | Open |
| Implement SensorNotify + GestureNotify | Binary BLE characteristics | Wireshark/sniffer or test harness validates layout | Open |
| HapticWrite handler | Host → device | ERM buzz on command in bench test | Open |
| Test mode | Fake IMU frames without sensor | `-DTEST_MODE=1` env builds | Partial config |

**Exit gate:** nRF52840 DK notifies 100 Hz sensor packets; gesture latency measured p50 < 50 ms on bench.

---

## Phase 6 — Hardware EVT path (Week 6–10)

**Objective:** Credible prototype without fake manufacturing artifacts.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| HARDWARE_PROTOTYPE_PLAN.md | Mule-first, EVT/DVT/PVT | No fake Gerbers claimed | Done |
| Wristband mule BOM CSV | `hardware/wristband/bom/` with required columns | TBD where unverified | Partial |
| Directory scaffolding | bom/, fab/, enclosure/, test/ | README + checklists if files missing | Planned |
| EVT validation matrix | Latency, battery, haptic feel | Pass/fail thresholds defined | Documented |
| KiCad ring project | `edgeio-ring.kicad_*` | Only when engineering ready — not faked | Not started |

**Exit gate:** Dev-board mule demo video: swipe → browser receives GestureNotify → dodge in sim.

---

## Phase 7 — CI & quality gates (Week 2–3, ongoing)

**Objective:** `npm run quality` is the merge bar.

| Action | Deliverable | Acceptance | Status |
|--------|-------------|------------|--------|
| Root workspace scripts | typecheck, test, build, quality | All packages included | Done |
| GitHub Actions `quality.yml` | install → typecheck → test → build:web | Required check on PR | Open (ci.yml partial) |
| VALIDATION_REPORT.md | Command results per release | Updated each milestone | Planned |
| Firmware CI (non-blocking) | Documented `pio run` audit job | Fails visible, not silent | Planned |

**Exit gate:** Green CI on default branch for TypeScript quality path.

---

## Phase 8 — Online & v0.5 (Week 10+)

**Objective:** Public demo with optional online and wearable.

| Action | Deliverable | Acceptance | Milestone |
|--------|-------------|------------|-----------|
| Transport layer for input frames | UDP or WebRTC | 2 clients sync hash at frame N | v0.5 |
| Input delay + rollback in couch | Configurable frames delay | Rollback count > 0 in debug | v0.5 |
| 3rd character + stage | Content | Roster screen shows 3+ | v0.5 |
| RELEASE_CHECKLIST.md execution | Sign-off | v0.5 section complete | v0.5 |

---

## Risk register (from audit)

| Risk | Mitigation | Owner |
|------|------------|-------|
| JS float nondetermism breaks online lockstep | Fixed-point in sim; consider binary serialize; cross-browser test suite | Gameplay |
| Firmware team picks wrong BLE stack | ADR-0001 + time-boxed mule on Adafruit | Firmware |
| Hardware rush before mule validated | Wristband dev-board gate before ring PCB | Hardware |
| Scope creep (4 platforms) | v0.1 web-only; defer mobile/desktop | Product |

---

## Decision log

| Decision | Date | Reference |
|----------|------|-----------|
| Rollback active in local couch play | 2026-06-24 | ROLLBACK_DESIGN.md |
| TypeScript game-core authoritative (not Godot) | 2026-06-24 | ARCHITECTURE.md |
| Wristband mule before custom ring | 2026-06-24 | HARDWARE_PROTOTYPE_PLAN.md |
| Firmware stack TBD → see ADR-0001 | 2026-06-24 | docs/decisions/ADR-0001-firmware-stack.md |

---

## Next human decisions required

1. **Firmware stack:** Confirm Adafruit nRF52 Arduino for mule (recommended in ADR-0001) vs immediate Zephyr migration.
2. **Legacy `web/` tree:** Delete, archive, or merge into `apps/web`.
3. **CI:** Promote `quality.yml` to required check and deprecate web-only `ci.yml`.
4. **Hardware budget:** Approve dev-board mule BOM purchase (~$80–150 depending on breakouts).
5. **v0.5 date:** Set public demo target once firmware mule demo is recorded.
