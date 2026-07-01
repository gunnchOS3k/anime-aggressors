# Playable Vertical Slice Audit

**Branch:** `fix/playable-vertical-slice`  
**Goal:** One predictable Web path — Home → Quick Match → Battle → Results/Rematch.

## Current problems (pre-fix)

### Multiple battle/runtime paths

| Path | Entry | Runtime |
|------|-------|---------|
| Godot iframe | Home primary CTA | `GodotRuntimeScreen` + rescue runtime |
| TypeScript / Three.js | Legacy “Start Match” setup flow | `PlatformFighterApp` via `#/battle` / `#/play` |
| Impact Dummy Derby | Secondary menu | Separate derby view + physics |
| Flagline Clash | Secondary menu | Flagline mode + team setup |

Players landing on the home screen had no obvious “just play” path; Godot prototype was the hero CTA while the Web fighter required a multi-step setup wizard.

### Inconsistent controls

`inputProfiles.ts` mapped **P1 to arrow keys** and **P2 to WASD**, while help copy, Godot rescue runtime, and player expectations followed the inverse (WASD P1, arrows P2). No single source of truth; remapped profiles could drift from battle toolbar hints.

### Battle presentation

`#app-root` was capped at `1100px` for all routes. The Three.js canvas lived inside a card with `min-height: 520px`, making matches feel like an embedded widget instead of a full-stage platform fighter.

### Platform physics vs stage layouts

`stageLayouts.ts` defines main floor, side platforms, and center high platform per stage. `integratePhysics` in `combat.ts` only resolved `player.y >= stage.floorY`, so side/center platforms were visual-only.

### Combat feedback gaps

`resolveCombatHits` applied damage every overlapping active frame with no per-move hit registry. Multi-frame active windows could stunlock or stack damage unrealistically. Debug hitboxes were easy to leave on; acceptance tests for knockback/hitstun/KO were thin.

## Canonical path (this pass)

1. **Quick Match** — primary home CTA → `#/battle` with defaults (no setup wizard).
2. **Defaults:** `skyline-arena`, default P1/P2 fighters, 3 stocks, 2 players, items off.
3. **Corrupt / incomplete `localStorage` setup** — ignored; Quick Match always seeds valid defaults.
4. **Labs / Experimental** — Godot, Derby, Flagline, Edge-IO, rollback, etc. remain available but off the main path.

## Out of scope

- New modes, characters, netplay, career expansion, Godot export, Edge-IO features.
- Platform drop-through (down + jump while airborne).
- Full Smash-style move catalog polish.

## Files touched (summary)

- `apps/web/src/match/quickMatch.ts` — default setup + launch
- `apps/web/src/ui/mainMenuConfig.ts` — Quick Match primary; labs grouping
- `apps/web/src/input/inputProfiles.ts` — unified keyboard map
- `packages/game-core/src/stageCollision.ts` — platform landing
- `packages/game-core/src/combat/hitResolution.ts` — single-hit-per-move registry
- `apps/web/src/styles.css` — `.app-root--battle` fullscreen shell
