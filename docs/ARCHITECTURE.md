# Architecture — 90-Day Canonical Structure

**Last updated:** 2026-06-24  
**Horizon:** v0.1 → v0.5 (deterministic web slice → public demo + Edge-IO mule)

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
│   └── web/                 # Playable web/couch demo (Vite + Canvas)
├── packages/
│   ├── game-core/           # Deterministic platform-fighter simulation
│   ├── rollback/            # Snapshot / input / replay / rollback harness
│   └── edgeio/              # BLE gesture + haptic binary protocol (TS)
├── firmware/
│   └── ring/                # Wearable firmware / dev-board mule target
├── hardware/
│   ├── ring/                # KiCad + EVT documentation path (ring)
│   └── wristband/           # Dev-board mule BOM + validation (first prototype)
├── docs/                    # PRD, design, QA, hardware, release docs
├── cloud/worker/            # Future: matchmaking/leaderboards (scaffold)
└── web/                     # LEGACY — React mini-games; consolidate or archive
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
npm run build:web
npm run quality     # all of the above
```

Target: `.github/workflows/quality.yml` runs full `quality` on PR.

Firmware: non-blocking `pio run` audit until compile fixed.

---

## Legacy & deferred components

| Path | Status | Action |
|------|--------|--------|
| `web/` (React) | Legacy mini-games | Archive or merge into apps/web |
| `cloud/worker/` | Scaffold | Wire post-v0.5 |
| `packages/messages/` | Shared types | Align with edgeio or deprecate |
| `packages/input/` | Older gamepad helper | Superseded by apps/web/input |
| Godot / C++ game/ | Not in active slice | Do not document as shipped |

---

## Extension points

1. **Online:** Implement `InputTransport` sending `(frame, playerId, InputFrame, confirmed)` to peer; feed `RollbackSession.confirmInputs`.
2. **Replay files:** Serialize `inputLog` + `GameConfig` JSON; verify with `replay()`.
3. **Characters:** Move `characters.ts` data to JSON loaded at boot (non-authoritative load, deterministic after parse).
4. **Edge-IO:** Web Bluetooth notify → parseGesturePacket → edgeioMapper → pollPlayerInput.

---

## Related documents

- [ROLLBACK_DESIGN.md](./ROLLBACK_DESIGN.md)
- [INPUT_SYSTEM.md](./INPUT_SYSTEM.md)
- [EDGE_IO_PROTOCOL.md](./EDGE_IO_PROTOCOL.md)
- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md)
- [STATUS.md](./STATUS.md)
