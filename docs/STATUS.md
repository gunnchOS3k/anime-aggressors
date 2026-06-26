# Anime Aggressors — Status

**Last updated:** 2026-06-24  
**Branch:** `threejs-platform-fighter-pivot`  
**Product:** 2.5D platform fighter (Three.js renderer + deterministic game-core)

Ship gate vocabulary:

| Gate | Meaning |
|------|---------|
| **UNSHIPPED** | Not available to users |
| **SHIP BLOCKED** | Implementation exists but fails a quality gate |
| **PLAYABLE** | User can launch and play it |
| **PROVEN BY TEST** | CI/automated tests cover it |
| **PROVEN BY DEMO** | Public demo (GitHub Pages) demonstrates it |
| **RELEASED** | Tagged release / artifact exists |

---

## Playable today

| Capability | Gate | Evidence |
|------------|------|----------|
| **Play Match** — 2P stock battle, Skyline Arena | PLAYABLE | `apps/web` → **Play Match** |
| Three.js 2.5D renderer (orthographic camera, placeholders, VFX) | PLAYABLE | `apps/web/src/renderer-three/` |
| Character select → countdown → fight → results → rematch | PLAYABLE | `apps/web/src/game/App.ts` |
| Training Mode + debug overlay (F1–F4, hitboxes) | PLAYABLE | **Training Mode** on homepage |
| Controller Test | PLAYABLE | `apps/web/src/shell/controllerTest.ts` |
| Rollback Debug shell | PLAYABLE | `apps/web/src/shell/rollbackDebug.ts` |
| Edge-IO Lab (gesture mapping) | PLAYABLE | `apps/web/src/shell/edgeioLab.ts` |
| Prototype Lab mini-games | PLAYABLE | `apps/web/src/minigames/` (demoted from main CTA) |
| Deterministic game-core (60 Hz, frame data, blast zones) | PROVEN BY TEST | `npm run test -w @anime-aggressors/game-core` |
| Rollback harness | PROVEN BY TEST | `npm run test -w @anime-aggressors/rollback` |
| Edge-IO binary protocol | PROVEN BY TEST | `npm run test -w @anime-aggressors/edgeio` |
| Renderer mapping (no GameState mutation) | PROVEN BY TEST | `npm run test -w anime-aggressors-web` |
| GitHub Pages demo | PROVEN BY DEMO | After merge + Pages deploy |

---

## Ship blocked / in progress

| Item | Gate | Blocker |
|------|------|---------|
| GLB character/stage assets | SHIP BLOCKED | Placeholders only; pipeline stubbed |
| Production combat polish | SHIP BLOCKED | Basic frame data; needs tuning |
| Online multiplayer | UNSHIPPED | No transport |
| Edge-IO hardware loop | UNSHIPPED | No BLE UI / firmware in CI |
| Mobile / desktop apps | UNSHIPPED | Scaffold only |
| Tagged release | UNSHIPPED | No v0.2 tag yet |

---

## Architecture (authoritative vs presentation)

```
packages/game-core     → GameState truth
packages/rollback      → rollback / replay truth
apps/web/renderer-three → read GameState, render only
```

See `docs/RENDERER_THREE_CONTRACT.md`.

---

## Legacy / archived

| Path | Status |
|------|--------|
| `legacy/web/` | Archived React PWA — not in CI |
| `legacy/game-prototype/` | Superseded by game-core + native/engine |
| `apps/web/src/game/renderCanvas.ts` | Legacy 2D canvas — superseded by Three.js |

---

## Verify locally

```bash
npm ci
npm run quality
npm run dev
```

Use `docs/VISUAL_ACCEPTANCE_CHECKLIST.md` before claiming PROVEN BY DEMO.
