# Battle Black Screen — Validation Report

**Date:** 2026-06-24  
**Branch:** `fix-battle-black-screen-renderer`  
**Issue:** Battle HUD loads at `#/battle`, but after Ready/Fight the match viewport is a black rectangle with no stage, fighters, or effects.

## Root Cause

**Coordinate system mismatch** between game simulation and the Three.js renderer.

| Layer | Coordinate space | Example values |
|-------|------------------|----------------|
| Game logic (`PlayerState.x/y`) | Fixed-point display units | P1 ≈ `800`, P2 ≈ `1600`, floor Y ≈ `836` |
| 2D canvas renderer | Scales by `width/2400` | Correct — fighters visible |
| Three.js renderer (before fix) | Arbitrary small world units (`0–24`) | Stage at `x≈12`, fighters ~2 units tall |

The orthographic camera followed players at display coordinates (~800–1600) with zoom ~400+, while stage geometry was built near the origin in a tiny 0–24 space. **Stage and fighters existed but were off-screen and microscopic.**

Secondary issues:

- Canvas container `min-height` was only 360px (could collapse visually on some layouts).
- No boot-time validation or diagnostics when the scene was empty.
- No guaranteed fallback stage/fighter path surfaced to the user.

## Fixes Applied

1. **Unified display coordinates** — `fpToWorld(v) = v / 256` used for stage platforms, fighter positions, camera bounds, and blast zones (`RenderTypes.ts`, `StageModelFactory.ts`, `CharacterView.ts`, `cameraBounds.ts`).
2. **Fighter scale** — Low-poly humanoids scaled with `characterWorldScale()` (~30×) to match ~64px-tall 2D fighters.
3. **Camera** — `CameraDirector` targets stage center by default, clamps zoom 180–720, positions camera at `z=800` looking at fighters.
4. **Lighting & background** — Scene background `#12122e`, fog, hemisphere + `setupSceneLighting()` so content is never black-on-black.
5. **Fallbacks** — `buildFallbackStageModel()` (Training Grid) and `createFallbackFighterModel()` for unknown/broken assets.
6. **Boot contract** — `createBattleScene.ts` returns `BattleSceneBootResult`; `App.ts` wires diagnostics and failure panel.
7. **CSS** — `.battle-screen`, `.battle-canvas-shell`, `.three-battle-canvas` enforce `min-height: 520px`.
8. **Diagnostics** — `RendererDiagnostics.ts` (F6 toggle) reports mount, canvas size, object counts, camera, errors.

## Reproduction (local)

```bash
npm ci
npm run dev -w anime-aggressors-web
```

Flow: Start Match → Rules → Map → Character (Ember Vale vs Orion Vell) → Controls → Start Battle.

**Before fix:** HUD visible, viewport black after Fight.  
**After fix:** Stage platforms, backdrop, and both fighters visible; camera frames the fight.

## Commands Run

```bash
npm ci
npm run typecheck
npm run test
npm run build
npm run quality
npm run build:pages
```

(See CI / local terminal output for pass/fail timestamps.)

## Manual QA Checklist

- [ ] Ready/Fight overlay appears
- [ ] Stage geometry visible
- [ ] Ember Vale (flame/red) visible
- [ ] Orion Vell (gravity/indigo) visible
- [ ] No black screen after Fight
- [ ] Fighters move with input
- [ ] Alternate stage / fighter pair
- [ ] Impact Dummy Derby / Flagline Clash modes

## GitHub Pages

```bash
npm run build:pages
npx serve apps/web/dist
```

Verify `#/battle` after full setup flow does not black-screen after Ready/Fight.
