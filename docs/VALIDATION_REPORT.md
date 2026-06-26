# Validation report — Three.js platform fighter pivot

**Branch:** `threejs-platform-fighter-pivot`  
**Date:** 2026-06-24

## Baseline (before changes)

On `main` before pivot work began:

- `npm ci` — pass
- `npm run quality` — pass

No pre-existing failures were hidden.

## Commands run (after changes)

| Command | Result |
|---------|--------|
| `npm ci` | pass (during development) |
| `npm run typecheck` | pass |
| `npm run test` | pass (18 game-core + 3 rollback + 4 edgeio + 3 web = 28 tests) |
| `npm run build` | pass |
| `npm run quality` | pass |
| `npm run build:pages` | pass |

## Three.js dependency

- `three@^0.185.0` in `apps/web/package.json`
- `@types/three` devDependency in `apps/web`

## Files created

### Renderer (`apps/web/src/renderer-three/`)

- `ThreeGameRenderer.ts`, `CameraDirector.ts`, `CharacterView.ts`, `StageView.ts`
- `HitboxDebugView.ts`, `HurtboxDebugView.ts`, `VfxSystem.ts`, `AnimationController.ts`
- `AssetLoader.ts`, `Materials.ts`, `SceneLighting.ts`, `RenderTypes.ts`, `index.ts`, `README.md`

### Shell modes (`apps/web/src/shell/`)

- `controllerTest.ts`, `rollbackDebug.ts`, `edgeioLab.ts`, `prototypeLab.ts`

### Game-core feel

- `packages/game-core/src/frameData.ts`, `moves.ts`, `feel.ts`
- `packages/game-core/test/platformFighterFeel.test.ts`
- `packages/game-core/test/collisionHelpers.test.ts`

### Tests & docs

- `apps/web/test/renderMapping.test.ts`
- `docs/RENDERER_THREE_CONTRACT.md`
- `docs/VISUAL_ACCEPTANCE_CHECKLIST.md`

## Files modified (high level)

- `apps/web/index.html` — platform-fighter-first homepage
- `apps/web/src/game/App.ts` — Three.js match + training mode
- `apps/web/src/game/debugPanel.ts` — HTML debug overlay
- `apps/web/src/styles.css` — match viewport + shell styles
- `packages/game-core/src/combat.ts` — feel systems, blast-zone fix (no horizontal hard clamp)
- `packages/game-core/src/collision.ts` — active-frame hitboxes, helper exports
- `packages/game-core/src/types.ts`, `state.ts`, `simulate.ts`, `index.ts`
- `README.md`, `docs/STATUS.md`
- Root `package.json` — web tests in `npm run test`
- `apps/web/package.json` — three, @types/three, test script

## What is playable now

- **Play Match** — 2P local stock battle with Three.js Skyline Arena, capsule fighters, HUD, results/rematch
- **Training Mode** — same match, starts paused, F1–F4 debug controls
- **Controller Test**, **Rollback Debug**, **Edge-IO Lab**
- **Prototype Lab** — Home-Run Sandbag, Paint the Floor, 4-Lane Blaster (demoted)

## What is proven by test

- Deterministic simulation + replay
- Platform-fighter frame data (startup/active/recovery, hitstun, shield, dodge invuln, blast-zone KO)
- Rollback session + desync detection
- Edge-IO protocol parse/encode
- Renderer `mapGameStateReadOnly` does not mutate `GameState`

## What is proven by demo

- Pending GitHub Pages deploy after merge — local `npm run dev` demonstrates PLAYABLE match flow

## Screenshots / GIF instructions for PR

1. Homepage with **Play Match** as primary CTA
2. Character select screen
3. Mid-match Three.js view (2 fighters, orthographic camera, HUD)
4. Hit spark / knockback moment
5. F2 hitbox/hurtbox debug overlay
6. Results screen with rematch
7. Prototype Lab showing mini-games are secondary

```bash
npm run dev
# http://localhost:5173/anime-aggressors/
```

## Remaining blockers (UNSHIPPED)

- Online multiplayer transport
- Real GLB assets + animation rigs
- Edge-IO BLE hardware loop
- Mobile (`apps/mobile`) and desktop (`apps/desktop`) shells
- Combat polish (cancel routes, expanded roster, SFX)
- Tagged **RELEASED** artifact

## Next step toward full completion

1. **Art pass** — import first GLB fighters + stage props via `AssetLoader`; keep placeholder fallback
2. **Combat depth** — expand `frameData.ts` per character, add tilt / DI / more moves
3. **Rollback couch stress** — inject artificial input delay in local play to match online path
4. **Pages deploy** — merge PR, verify PROVEN BY DEMO on live URL
5. **Online track** — WebSocket transport + synchronized `RollbackSession` across peers
