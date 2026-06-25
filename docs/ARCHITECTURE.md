# Architecture — 90-Day Canonical Structure

**Last updated:** 2026-06-24  
**Horizon:** Full-completion program — tracks A–H in parallel (`ROADMAP_FULL_COMPLETION.md`)  
**Authoritative sim (shipping):** `packages/game-core` (TypeScript)

---

## Full-completion parallel tracks

Anime Aggressors runs **eight parallel tracks**. Architecture enforces boundaries so experimental paths do not block the web game.

| Track | Repo areas | Authoritative for gameplay? |
|-------|------------|---------------------------|
| A — Web game | `apps/web`, `game-core` | **Yes** (today) |
| B — Rollback / online | `packages/rollback`, `cloud/worker/` | Rollback harness yes; transport no |
| C — C++ engine | `native/engine/` | **No** — experimental skeleton |
| D — Mobile | `apps/mobile/` | No |
| E — Desktop | `apps/desktop/` | No (wraps web build) |
| F — Edge-IO mule | `firmware/ring`, `packages/edgeio` | Input mapping only |
| G — Production HW | `hardware/*` | N/A |
| H — Quality | `docs/QUALITY_BAR.md` | N/A |

---

## Design principles

1. **Simulation is authoritative.** Rendering, audio, haptics, and UI are side effects.
2. **Rollback consumes `InputFrame` only** — never raw DOM, Gamepad API, or BLE bytes inside `game-core`.
3. **One sim path** for couch, online, replay, and debug.
4. **Keyboard/controller first;** Edge-IO maps into the same input abstraction.
5. **Honest boundaries** — document what is not built instead of faking it.

---

## Repository layout (canonical)

```text
anime-aggressors/
├── apps/
│   ├── web/                 # Playable web/couch demo (Vite + Canvas) — Track A
│   ├── mobile/              # Expo scaffold — Track D (not in required CI)
│   └── desktop/             # Tauri planning — Track E (not in required CI)
├── packages/
│   ├── game-core/           # Deterministic platform-fighter simulation (authoritative)
│   ├── rollback/            # Snapshot / input / replay / rollback harness — Track B
│   └── edgeio/              # BLE gesture + haptic binary protocol (TS) — Track F
├── native/
│   └── engine/              # C++ deterministic sim skeleton — Track C
├── firmware/
│   └── ring/                # Wearable firmware / dev-board mule target — Track F
├── hardware/
│   ├── ring/                # Ring EVT path — Track G
│   └── wristband/           # Dev-board mule + wristband EVT — Tracks F/G
├── legacy/
│   ├── web/                 # Archived React PWA — NOT in workspace build
│   └── game-prototype/      # Archived TS/C++ prototype
├── docs/                    # PRD, roadmap, QA, hardware, release docs
└── cloud/worker/            # Future: matchmaking/leaderboards (scaffold)
```

---

## Layer diagram

```mermaid
flowchart TB
  subgraph presentation ["Presentation (non-authoritative)"]
    WEB[apps/web Canvas + DOM UI]
    AUDIO[Audio future]
    HAPTIC_UI[Haptic echo future]
  end

  subgraph input_layer ["Input layer"]
    KB[keyboard.ts]
    GP[gamepad.ts]
    EDGE[edgeioMapper.ts]
    ASSIGN[deviceAssignment.ts]
  end

  subgraph rollback_layer ["Rollback layer"]
    RS[RollbackSession]
    TRANSPORT[Online transport future]
  end

  subgraph sim ["Authoritative simulation"]
    GC[packages/game-core simulateFrame]
    STATE[GameState + hashState]
  end

  subgraph device ["Device layer (optional)"]
    FW[firmware/ring]
    BLE[Web Bluetooth future]
  end

  KB --> ASSIGN
  GP --> ASSIGN
  EDGE --> ASSIGN
  BLE --> EDGE
  FW --> BLE
  ASSIGN -->|InputFrame[]| RS
  TRANSPORT --> RS
  RS --> GC
  GC --> STATE
  STATE --> WEB
  STATE --> RS
```

---

## Package responsibilities

### `apps/web`

| Concern | Owner files | Notes |
|---------|-------------|-------|
| Landing + launch | `index.html`, `main.ts` | Vertical slice vs Training Lab |
| Match UI | `game/App.ts`, `characterSelect.ts`, `results.ts` | Wires RollbackSession |
| Render | `game/renderCanvas.ts` | Reads GameState; fpToDisplay for draw |
| Debug | `game/debugOverlay.ts` | Hash, frame, rollback count |
| Input poll | `input/*` | Produces InputFrame per sim tick |
| Mini-games | `minigames/*` | Prototype experiments, not authoritative |

**Build:** Vite, TypeScript, depends on workspace packages.

### `packages/game-core`

Pure TypeScript — **no** DOM, BLE, React, or Node-only APIs in hot path.

| Module | Purpose |
|--------|---------|
| `types.ts` | GameState, InputFrame, phases |
| `constants.ts` | SIM_HZ, fixed-point scales |
| `state.ts` | createInitialGameState, clone |
| `simulate.ts` | simulateFrame — single tick |
| `combat.ts` | Attacks, hitstun, knockback |
| `collision.ts` | Hitbox/hurtbox, blast zones |
| `characters.ts` | Ember, Tide definitions |
| `stages.ts` | skyline-arena bounds |
| `hash.ts` | serialize + FNV-1a hash |
| `replay.ts` | Deterministic input log replay |

**Public API:**

```typescript
createInitialGameState(config: GameConfig): GameState
simulateFrame(state: GameState, inputs: InputFrame[]): GameState
serializeState(state: GameState): string
deserializeState(serialized: string | Uint8Array): GameState
hashState(state: GameState): string
replay(initial: GameState, inputLog: InputFrame[][]): ReplayResult
```

### `packages/rollback`

Local rollback harness — online transport plugs in later.

| Module | Purpose |
|--------|---------|
| `rollbackSession.ts` | Snapshots, predict, confirm, resim |
| `types.ts` | RollbackSessionConfig, RollbackStats, events |

**Config defaults (vertical slice):**

- `maxRollbackFrames`: 120 (2 s at 60 Hz)
- `snapshotInterval`: 1 (every frame)
- `playerCount`: 2

### `packages/edgeio`

| Module | Purpose |
|--------|---------|
| `parser.ts` | SensorNotify, GestureNotify, HapticWrite |
| `gestures.ts` | Canonical enum + ID map |
| `inputMapper.ts` | Gesture → action flags |
| `fake.ts` | Test packet generators |

Firmware must converge on same binary layout (`docs/EDGE_IO_PROTOCOL.md`).

### `native/engine` (Track C — experimental)

C++ deterministic simulation **skeleton** — not used by `apps/web` today.

| Module | Purpose |
|--------|---------|
| `include/aa/simulation.hpp` | `InputFrame`, `GameState`, API |
| `src/simulation.cpp` | `simulate_frame`, `hash_state` |
| `tests/determinism_test.cpp` | Same-input → same-hash |

**Relationship to `game-core`:** TS remains authoritative until shared test vectors and hash parity pass. See `docs/CPP_ENGINE_PLAN.md` for WASM boundary and CI policy.

**Build:**

```bash
cmake -S native/engine -B build/native-engine && cmake --build build/native-engine
ctest --test-dir build/native-engine
```

CI job `native-engine` runs on every PR.

---

## Data flow — one simulation frame (couch)

```text
1. rAF loop accumulates real time → fixed 1/60 s steps
2. pollAllInputs(simFrame) → InputFrame[2]
3. rollback.advanceFrame(inputs, confirmed=[true,true])
4. simulateFrame inside advanceFrame
5. renderFrame(gameState) — canvas draw only
6. simFrame++
```

Online (future): step 3 receives `confirmed` from network; unconfirmed slots use prediction.

---

## Fixed-point and determinism

- Positions/velocities use `FP_SCALE = 256` integers where practical.
- State hash serializes via `JSON.stringify` today — **known risk** for cross-browser lockstep; v0.5 may move to binary serialize.
- Tests enforce same-input → same-hash on Node 20.

---

## Firmware & hardware (90-day path)

| Week | Focus |
|------|-------|
| 1–2 | game-core + rollback + web slice |
| 3–4 | Edge-IO protocol unification in TS; ADR firmware stack |
| 5–6 | nRF52840 DK firmware mule (binary BLE) |
| 7–8 | Wristband mule bench: latency + haptic |
| 9–10 | Online transport spike |
| 11–12 | v0.5 polish + public deploy |

**Hardware:** Prototype on dev board before custom ring PCB. See `HARDWARE_PROTOTYPE_PLAN.md`.

---

## CI & quality

```bash
npm install
npm run typecheck   # all workspaces
npm run test        # game-core, rollback, edgeio
npm run build       # packages + apps/web
npm run quality     # all of the above
```

| Job | Scope | Blocking |
|-----|-------|----------|
| `quality` | npm typecheck, test, build | Yes |
| `native-engine` | CMake + ctest | Yes |
| `firmware-audit` | platformio.ini presence | No |

Target: `.github/workflows/quality.yml` on every PR. See `docs/STATUS.md` CI section.

Firmware compile: non-blocking until ADR-0001 migration completes.

---

## Legacy & archived paths

| Path | Status | Action |
|------|--------|--------|
| `legacy/web/` | Archived React PWA + Workbox | Excluded from workspace `tsconfig`; see `legacy/web/README.md` |
| `legacy/game-prototype/` | Archived TS + `performance_engine.cpp` | Do not extend; see `legacy/game-prototype/README.md` |
| `cloud/worker/` | Scaffold | Wire post-v0.5 (Track B) |
| `packages/messages/` | Shared wire types | Align with edgeio; no circular deps with game-core |
| `packages/input/` (`@gunnch/input`) | Older gamepad helper | Strict tsconfig include; superseded by `apps/web/src/input` |

**Policy:** Legacy trees must not be pulled into active package compilation. Root cause of PR #19 CI failures.

---

## Extension points

1. **Online:** Implement `InputTransport` sending `(frame, playerId, InputFrame, confirmed)` to peer; feed `RollbackSession.confirmInputs`.
2. **Replay files:** Serialize `inputLog` + `GameConfig` JSON; verify with `replay()`.
3. **Characters:** Move `characters.ts` data to JSON loaded at boot (non-authoritative load, deterministic after parse).
4. **Edge-IO:** Web Bluetooth notify → parseGesturePacket → edgeioMapper → pollPlayerInput.

---

## Related documents

- [ROADMAP_FULL_COMPLETION.md](./ROADMAP_FULL_COMPLETION.md)
- [CPP_ENGINE_PLAN.md](./CPP_ENGINE_PLAN.md)
- [ROLLBACK_DESIGN.md](./ROLLBACK_DESIGN.md)
- [INPUT_SYSTEM.md](./INPUT_SYSTEM.md)
- [EDGE_IO_PROTOCOL.md](./EDGE_IO_PROTOCOL.md)
- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md)
- [STATUS.md](./STATUS.md)
