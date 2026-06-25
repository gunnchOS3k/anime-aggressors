# Validation Report

**Date:** 2026-06-24  
**Branch:** `revive-product-rollback-vertical-slice`  
**Environment:** macOS, Node 20+

## Commands run

| Command | Result | Notes |
|---------|--------|-------|
| `npm install` | **PASS** | Workspace linking for `game-core`, `rollback`, `edgeio`, `apps/web` |
| `npm run typecheck` | **PASS** | Builds `game-core` first, then all workspace typechecks |
| `npm run test` | **PASS** | 15 tests total (8 game-core, 3 rollback, 4 edgeio) |
| `npm run build:web` | **PASS** | Vite production build → `apps/web/dist/` |
| `npm run quality` | **PASS** | typecheck + test + build:web |

## Test summary

- **game-core:** determinism hash equality, replay hash match, serialize round-trip, combat hitboxes, shield path
- **rollback:** misprediction rollback + authoritative hash match, rollback count, desync detection
- **edgeio:** sensor/gesture/haptic binary parse/encode, gesture → input mapping

## Fixes applied during validation

1. Added missing `collision.js` imports in `combat.ts`
2. Fixed `EdgeIO.ts` duplicate `scanTimeout` config key
3. Fixed `game-core` / `rollback` package `main`/`types` paths for `dist/src/`
4. Fixed rollback `confirmInputs` resimulation to target frame
5. Removed stale compiled `.js` duplicates in `apps/web/src/` that broke Vite resolution

## Not run (documented blockers)

| Command | Result | Reason |
|---------|--------|--------|
| `pio run` (firmware) | **NOT RUN** | Missing `lib_deps`, BLE API errors — see `firmware/ring/README.md` |
| Godot / mobile / desktop builds | **N/A** | Not implemented in repo |
| Hardware fab outputs | **N/A** | Requirements/checklists only — no Gerbers |

## Remaining blockers

1. **Firmware** — wristband/ring sketches do not compile; protocol migration to canonical binary pending
2. **Hardware** — no KiCad/Gerber artifacts; EVT gated on wristband mule
3. **Online multiplayer** — rollback harness is local-only; transport layer not started
4. **Root legacy `web/` React app** — separate from `apps/web` vertical slice; not in CI quality path

## Next recommended actions

1. Human decision: approve **Adafruit nRF52 Arduino** path per `docs/decisions/ADR-0001-firmware-stack.md`
2. Flash wristband mule and validate binary BLE against `packages/edgeio` tests + browser harness
3. Add online input transport adapter on top of `RollbackSession`
4. Deprecate or redirect root `pages.yml` (builds legacy root `dist/`) to `apps/web/dist/`
