# Engine Architecture — Production Platform Fighter Path

**Status:** Milestone 0 boundary document  
**Last updated:** 2026-06-24  
**Related:** [ARCHITECTURE.md](./ARCHITECTURE.md) (repo-wide) · [RENDERER_THREE_CONTRACT.md](./RENDERER_THREE_CONTRACT.md) · [INPUT_SYSTEM.md](./INPUT_SYSTEM.md)

This document defines the **production platform fighter boundary** — what ships in the indie Smash-like MVP — distinct from labs, Godot, C++, Edge-IO, and netplay experiments.

---

## 1. Production path (authoritative)

```
Home → Quick Match → Battle (#/battle) → Results → Rematch
```

| Layer | Location | Authoritative? |
|-------|----------|----------------|
| Simulation | `packages/game-core` | **Yes** |
| Rollback harness | `packages/rollback` | Yes (local/replay) |
| Input | `apps/web/src/input/` | Maps to `InputFrame` |
| Rendering | `apps/web/src/renderer-three/` | No |
| UI / routes | `apps/web/src/screens/`, `main.ts` | No |
| Audio | `apps/web/src/audio/` | No |
| Storage | `apps/web/src/storage/`, career | No |

**Rule:** `game-core` never imports from `apps/web`, Three.js, DOM, or network.

---

## 2. Simulation contract

### Tick

- Fixed **60 Hz** (`SIM_HZ`)
- Integer fixed-point positions (`FP_SCALE`)

### State machine

```
countdown → fighting → results
```

### Per-frame pipeline (`simulateFrame`)

1. Hitstop gate  
2. `processPlayer` (input → movement → actions → physics)  
3. `resolveCombat` (hits, blast zone KOs)  
4. Energy / clash ticks (optional; disable for minimal MVP if needed)  
5. Win / timeout resolution  

### Determinism requirements

- Same `GameConfig` + input log → same final hash (`determinism.test.ts`)
- Replay round-trip (`replay.test.ts`)

---

## 3. Physics and stages

| System | Module | MVP target |
|--------|--------|------------|
| Gravity, fall speed | `combat.ts` `integratePhysics` | Done |
| Horizontal move | `movement/applyMovement.ts` | Done |
| Jump / double jump / coyote / buffer | `movement/jumpSystem.ts` | Partial |
| Platform landing | `stageCollision.ts` | Partial (PR #36) |
| Platform drop-through | **TBD** `stageCollision.ts` | Milestone 1 |
| Blast zones | `combat/blastZones.ts` | Done |
| Ledge | **TBD** | Milestone 2 |

Stage layout data: `stageLayouts.ts` → collision via `getStageLayout(stageId)`.

---

## 4. Combat contract

| System | Module | Notes |
|--------|--------|-------|
| Hitboxes / hurtboxes | `collision.ts` | Debug toggle F2 in battle |
| Hit resolution | `combat/hitResolution.ts` | Single-hit registry per move |
| Hitlag | `combat/hitlag.ts` | |
| Hitstun | `combat/hitstun.ts` | |
| Knockback | `combat/knockback.ts` | Damage scaling |
| Frame data | `frameData.ts`, `moves/` | Extend per Milestone 3 |
| Events | `combat/hitEvents.ts` → renderer/audio | |

**Combat grammar gap:** tilts vs smashes, grabs, throws, DI — see requirements doc §C.

---

## 5. Input contract

```
Keyboard / Gamepad / Edge-IO
        ↓
  deviceAssignment.ts → pollAllInputs()
        ↓
  InputFrame[] per tick
        ↓
  game-core simulateFrame
```

- Canonical keyboard map: `controlReference.ts` (PR #36)  
- Profiles: `inputProfiles.ts`, `inputProfileStorage.ts`  
- Remap UI: `InputRemapScreen.ts`  

Edge-IO maps gestures → same `InputFrame` fields; must not fork sim logic.

---

## 6. Rendering contract

- `ThreeGameRenderer` reads `GameState` read-only  
- No gameplay authority in renderer  
- Camera: smooth follow, zoom — acceptance tests Milestone 1+  
- VFX triggered from `lastHitEvents`, aura state, move phase  

See `RENDERER_THREE_CONTRACT.md`.

---

## 7. Labs boundary (non-production)

These **must not** block or replace the Quick Match path:

| Mode | Route | Runtime |
|------|-------|---------|
| Godot prototype | `#/godot` | iframe / rescue runtime |
| Impact Dummy Derby | `#/impact-dummy-derby` | Separate sim view |
| Flagline Clash | `#/flagline-clash` | Team mode sim |
| Edge-IO lab | `#/edgeio-lab` | BLE experiment |
| Rollback debug | `#/rollback-debug` | Harness UI |
| Prototype lab | `#/prototype-lab` | Misc |

Home screen: **Labs & Experimental** panel only.

---

## 8. Content pipeline

| Asset type | Source of truth | Consumed by |
|------------|-----------------|-------------|
| Fighter stats / moves | `packages/game-core` data + `docs/fighters/` | sim + renderer |
| Stage layouts | `stageLayouts.ts`, `stages.ts` | sim + `StageModelFactory` |
| Animations | `renderer-three/fighters/` clips | renderer only |
| Balance | rulesets + per-move frame data | sim |

Validators: `npm run validate:*` (see `PRODUCTION_ACCEPTANCE_GATES.md`).

---

## 9. Testing pyramid

| Level | Location | Purpose |
|-------|----------|---------|
| Unit / sim | `packages/game-core/test/` | Physics, combat, determinism |
| Web integration | `apps/web/test/` | Routes, input, menu |
| Manual | `docs/PLAYTEST_CHECKLIST.md`, `MVP_DEFINITION_OF_DONE.md` | Feel / UX |
| CI | `npm run typecheck`, `test`, `build` | Merge gate |

**Gap:** No automated “feel” tests; manual playtest records required for milestone sign-off.

---

## 10. Parallel tracks (do not confuse with MVP)

Documented in `ARCHITECTURE.md`:

- **Track B** — netplay / cloud worker  
- **Track C** — `native/engine` C++  
- **Track F/G** — Edge-IO hardware  
- **Godot / Unreal R&D** — `docs/ENGINE_STRATEGY.md`, `GODOT_*`  

MVP ships on **Track A** (`game-core` + web Three.js) only.

---

## 11. File map (quick reference)

```
packages/game-core/src/
  simulate.ts          # frame loop
  combat.ts            # processPlayer, physics integration
  stageCollision.ts    # platforms
  combat/hitResolution.ts
  movement/
  stageLayouts.ts
  rulesets.ts

apps/web/src/
  match/quickMatch.ts  # default battle setup
  game/App.ts          # PlatformFighterApp battle shell
  input/
  renderer-three/
  main.ts              # hash router
```

---

## 12. Decision log

| Date | Decision |
|------|----------|
| 2026-06 | `game-core` remains authoritative sim for shipping web game |
| 2026-06 | Quick Match + `#/battle` is production entry; Godot demoted to labs |
| 2026-06 | Platform collision lands on layout platforms, not floorY only |
| 2026-06 | Per-move hit registry prevents multi-tick damage |

Add ADRs under `docs/decisions/` for future engine boundary changes.
