# Full-Completion Program Roadmap

**Last updated:** 2026-06-24  
**Program:** Anime Aggressors — parallel tracks A through H  
**Policy:** Do not merge or expand on broken CI. Track A0 (CI green) is the immediate gate.

---

## Overview

Anime Aggressors is **not** scoped only as a v0.1 vertical slice. The deterministic web vertical slice is **Track A** of a larger full-completion program. Eight parallel tracks run concurrently; each has measurable milestones and honest status.

| Track | Focus | Current phase (honest) |
|-------|-------|------------------------|
| **A** | Full deterministic web game | A1 in progress (A0 partial) |
| **B** | Rollback and online multiplayer | B0 done |
| **C** | C++ engine expansion | C1–C2 in progress |
| **D** | Mobile app | D0–D1 planning |
| **E** | Desktop app | E0 planning |
| **F** | Edge-IO wearable dev-board mule | F0 done; F1–F8 blocked on firmware |
| **G** | Production ring/wristband hardware | G0–G1 planning |
| **H** | AAA-inspired production quality | H0 done |

**Dependencies between tracks (soft, not blocking parallel work):**

- A0 CI green unblocks confident merges across all tracks.
- B3+ online lobby benefits from A5 readiness.
- C4 WASM exploration should not block A shipping.
- D3 touch controls benefit from A3 training mode patterns.
- E2 desktop renderer depends on `apps/web` build artifact.
- F6 game input mapping requires A couch slice + Edge-IO mapper.
- G5+ fabrication requires F7 latency pass on mule.
- H8 release candidate gates on A6 + B6 + selected F/G milestones.

---

## Track A — Full deterministic web game

**Goal:** Full playable web edition with 2–4 local players, full match flow, training mode, content pipeline, accessibility, settings, replay/debug tools, and rollback-ready simulation.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **A0** | CI green | `npm ci`, `typecheck`, `test`, `build`, `quality` pass locally and on GitHub Actions | **In progress** — netplay rollback build-order fix on `fix-netplay-rollback-readme-pc-playtest` |
| **A1** | 2P deterministic match | Select → fight → results → rematch; determinism tests pass | **Done** |
| **A2** | 4P local couch | 4 `InputFrame` slots; device assignment UI | Not started |
| **A3** | Training mode | Dummy opponent, frame step, input display | Not started |
| **A4** | Replay system | Export/import input log; `verifyAgainstReplay` in UI | Not started |
| **A5** | Online private lobby prototype | 2 browsers, room code, hash sync | Not started |
| **A6** | Public web demo | Hosted static deploy; README link; polish pass | Not started |
| **A7** | Content-complete web edition | 8+ chars, 4+ stages, WCAG AA UI, audio pass | Not started |

**Owner areas:** `apps/web`, `packages/game-core`, `packages/rollback`

---

## Track B — Rollback and online multiplayer

**Goal:** Local rollback harness, online transport abstraction, private lobbies, matchmaking later, ping/jitter/rollback metrics, replay/desync tools.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **B0** | Local rollback tests | Wrong-prediction recovery; desync flag | **Done** |
| **B1** | Transport abstraction | `InputTransport` interface; mock peer tests | Not started |
| **B2** | Local network simulation | Artificial delay + jitter in couch mode | Not started |
| **B3** | Private lobby | Create/join room; 2P input exchange | Not started |
| **B4** | Remote input prediction | Unconfirmed slots predicted; rollback on mismatch | Not started |
| **B5** | Desync reporting | Hash mismatch UI + log export | Not started |
| **B6** | Online playtest | External tester completes match without desync | Not started |

**Owner areas:** `packages/rollback`, `cloud/worker/` (future)

---

## Track C — C++ engine expansion

**Goal:** Deterministic native engine core that can eventually power desktop/mobile/native builds or performance-sensitive simulation, **without breaking** the TypeScript `game-core`.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **C0** | Fix CMake source list | Only real files referenced; builds clean | **Done** |
| **C1** | Native deterministic simulation prototype | `simulate_frame`, `create_initial_state` | **Done** (skeleton) |
| **C2** | C++ tests for state hashing | Determinism test in CI | **Done** |
| **C3** | C ABI or WASM boundary design | Documented in `CPP_ENGINE_PLAN.md` | In progress |
| **C4** | WebAssembly build exploration | `emcmake` spike; load from web optional | Not started |
| **C5** | Native desktop integration | Desktop shell calls native lib (optional) | Not started |
| **C6** | Performance benchmark suite | C++ vs TS frame sim timing report | Not started |

**Rules:**

- No placeholder C++ pretending to be shipped features.
- C++ compiles in CI (`native-engine` job) or is explicitly experimental.
- C++ expansion must not block web game shipping.

**Owner areas:** `native/engine/`, `docs/CPP_ENGINE_PLAN.md`

---

## Track D — Mobile app

**Goal:** Mobile companion / playable build path.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **D0** | Decide mobile purpose | ADR or PRODUCT_SCOPE: playable, companion, controller, or sequence | **Done** (companion + controller first) |
| **D1** | Expo app scaffold | `apps/mobile` with valid package.json | Scaffold only |
| **D2** | Share game-core package | Metro resolves `@anime-aggressors/game-core` | Not started |
| **D3** | Touch controls | Complete match on 375px viewport | Not started |
| **D4** | Bluetooth permission research/docs | iOS/Android BLE constraints documented | Not started |
| **D5** | Android internal APK build | EAS internal track | Not started |
| **D6** | iOS TestFlight readiness | Apple dev account + build | Not started |
| **D7** | Mobile performance pass | Stable 60 FPS on mid-tier device | Not started |

**Owner areas:** `apps/mobile/`, `apps/mobile/PRODUCT_SCOPE.md`

---

## Track E — Desktop app

**Goal:** Desktop distribution for Windows/macOS/Linux.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **E0** | Decide Electron vs Tauri vs native C++ | ADR-0002 recorded | **Done** (Tauri recommended) |
| **E1** | Desktop shell scaffold | Minimal window loading web build | Not started |
| **E2** | Use apps/web build as renderer | Production `dist/` embedded | Not started |
| **E3** | Controller support validation | Web Gamepad API on all target OSes | Not started |
| **E4** | Offline build artifact | Installable per platform | Not started |
| **E5** | Updater/signing research | Code signing + auto-update plan | Not started |
| **E6** | Release packaging | Signed builds in CI (optional job) | Not started |

**Owner areas:** `apps/desktop/`, `docs/decisions/ADR-0002-desktop-shell.md`

---

## Track F — Edge-IO wearable dev-board mule

**Goal:** Working wristband/ring dev-board prototype that streams sensor/gesture data and receives haptics.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **F0** | Firmware stack decision | ADR-0001 accepted | **Done** |
| **F1** | Dev-board BOM | `hardware/wristband/bom/dev-board-mule-bom.csv` | **Done** (TBD MPNs) |
| **F2** | IMU breakout reads data | Serial/log on bench | Not verified |
| **F3** | BLE binary notifications | SensorNotify + GestureNotify per protocol | **Blocked** — firmware JSON mismatch |
| **F4** | Haptic write characteristic | HapticWrite triggers actuator | Not verified |
| **F5** | Battery measurement | `battery_pct` in SensorNotify | Not verified |
| **F6** | Game input mapping | Gesture → `InputFrame` in web demo | Software only |
| **F7** | Latency measurement | Gesture-to-host p50 < 50 ms | Not measured |
| **F8** | Haptic feel test | Subjective + intensity cap test | Not started |

**Owner areas:** `firmware/ring/`, `packages/edgeio/`, `hardware/wristband/`

---

## Track G — Production ring/wristband hardware

**Goal:** Move from dev-board mule to EVT/DVT/PVT path.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **G0** | Product industrial design requirements | `WEARABLE_PRODUCT_REQUIREMENTS.md` | **Done** |
| **G1** | Electrical requirements | `hardware/*/REQUIREMENTS.md` | **Done** |
| **G2** | Schematic draft | KiCad `.kicad_sch` in repo | Not started |
| **G3** | PCB layout draft | `.kicad_pcb` + DRC clean | Not started |
| **G4** | DFM review checklist | Fab house feedback recorded | Not started |
| **G5** | EVT fabrication package | Real Gerbers + BOM — **no fakes** | Not started |
| **G6** | EVT bring-up | EVT validation matrix pass (5–10 units) | Not started |
| **G7** | DVT revisions | Enclosure + yield on 50-unit build | Not started |
| **G8** | PVT readiness | Pilot production yield > 95% | Not started |

**Rules:**

- Do not fake KiCad/Gerbers/STEP files.
- Prefer wristband EVT before ring miniaturization.
- See `docs/WEARABLE_EVT_DVT_PVT_PLAN.md`.

**Owner areas:** `hardware/ring/`, `hardware/wristband/`

---

## Track H — Production quality / AAA-inspired polish

**Goal:** Product-level quality standards — **not** fake "AAA complete" claims.

| Milestone | Description | Exit criteria | Status |
|-----------|-------------|---------------|--------|
| **H0** | Quality bar document | `docs/QUALITY_BAR.md` | **Done** |
| **H1** | Frame pacing/performance metrics | 60 FPS + sim < 2 ms documented | Partial (web slice) |
| **H2** | Accessibility settings | Remap, contrast, reduce motion | Not started |
| **H3** | Input remapping | Persistent localStorage bindings | Not started |
| **H4** | Visual readability | Silhouettes, hit flash, color-safe UI | Placeholder art only |
| **H5** | Audio/haptic feedback design | SFX spec + HapticWrite patterns | Not started |
| **H6** | Menu/settings polish | No placeholder copy in shipping UI | Not started |
| **H7** | Crash/error reporting plan | Client telemetry opt-in design | Not started |
| **H8** | Release candidate checklist | `RELEASE_CHECKLIST.md` v1.0 signed | Not started |

**Owner areas:** Product, `docs/QUALITY_BAR.md`, `docs/RELEASE_CHECKLIST.md`

---

## CI and merge policy

1. **Required green:** `quality` job — `npm ci`, `typecheck`, `test`, `build`.
2. **Non-blocking (documented):** `npm run audit:ci`, `firmware-audit` job.
3. **Parallel:** `native-engine` job — CMake configure, build, ctest.
4. **PR checklist:** `docs/PULL_REQUEST_CHECKLIST.md`.

---

## Related documents

- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) — Track A is the vertical slice within full program
- [STATUS.md](./STATUS.md) — Honest capability matrix
- [PC_DISTRIBUTION_PLAN.md](./PC_DISTRIBUTION_PLAN.md) — Staged PC friend playtests (web → ZIP → itch.io)
- [GITHUB_PAGES_DEPLOYMENT.md](./GITHUB_PAGES_DEPLOYMENT.md) — Production Pages source (`apps/web/dist` via Actions)
- [playtest/PC_PLAYTEST_GUIDE.md](./playtest/PC_PLAYTEST_GUIDE.md) — Tester instructions
- [BACKLOG.md](./BACKLOG.md) — Work items labeled A–H
- [ARCHITECTURE.md](./ARCHITECTURE.md) — Parallel tracks and legacy paths
- [CPP_ENGINE_PLAN.md](./CPP_ENGINE_PLAN.md) — Track C detail
- [WEARABLE_EVT_DVT_PVT_PLAN.md](./WEARABLE_EVT_DVT_PVT_PLAN.md) — Track G detail
