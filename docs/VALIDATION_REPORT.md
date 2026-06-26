# Validation report — Pages fix + Impact Dummy Derby + unshipped advance

**Branch:** `complete-unshipped-fix-pages-launch-lab`  
**Date:** 2026-06-24

## Baseline (before changes)

`npm run quality` — **pass** on `main` at branch creation.

## GitHub Pages 404 — root cause and fix

**Root cause:** `index.html` used an inline `<script type="module">` with dev-only dynamic imports (`./src/game/App.ts`). Vite production builds bundle via entry `main.ts`, but any path-based navigation or missing `404.html` on Pages caused 404s on refresh/direct links.

**Fix:**
1. Moved all navigation to `apps/web/src/main.ts` (Vite entry `<script type="module" src="/src/main.ts">`).
2. Hash routing via `APP_ROUTES` (`#/play`, `#/training`, `#/impact-dummy-derby`, etc.).
3. Vite plugin copies `dist/index.html` → `dist/404.html`.
4. `build:pages` verifies `index.html`, `404.html`, and `/anime-aggressors/` base paths.

## Commands run

| Command | Result |
|---------|--------|
| `npm run typecheck` | pass |
| `npm run test` | pass (45 tests) |
| `npm run build` | pass |
| `npm run quality` | pass |
| `npm run build:pages` | pass |

## Impact Dummy Derby

Deterministic mode in `packages/game-core/src/modes/impactDummyDerby.ts`:

- READY → countdown → **10s damage phase** → **Kinetic Bat launch window** → flight → distance → results
- Walk, jump, dash, attack, special, timed final launch
- Dummy damage scales launch distance; bat hit > normal hit (tested)
- Three.js view: `apps/web/src/modes/impactDummyDerbyView.ts`

Removed weak Home-Run Sandbag from Prototype Lab (Paint the Floor + 4-Lane Blaster remain).

## Systems advanced

| System | New gate |
|--------|----------|
| GitHub Pages routing | PLAYABLE (hash + 404 fallback) |
| Impact Dummy Derby | PLAYABLE + PROVEN BY TEST |
| Combat polish (directional moves, SFX events) | PROVEN BY TEST |
| WebAudio SFX | PLAYABLE |
| Netplay loopback | PROVEN BY TEST |
| Edge-IO Lab BLE UI + simulator | PLAYABLE (sim); BLE SHIP BLOCKED |
| Asset pipeline manifest | SHIP BLOCKED |
| Release workflow | SHIP BLOCKED until tag |
| Mobile / desktop | SHIP BLOCKED scaffolds |

## Screenshots for PR

1. Homepage with Play Match + Impact Dummy Derby
2. `#/play` match on Pages (no 404)
3. Derby damage phase with dummy %
4. Kinetic Bat launch + flight camera
5. Derby results (distance, grade, retry)
6. Edge-IO Lab simulator mode

## Remaining blockers

- Public WebSocket relay + lobby
- Real GLB assets committed
- Verified Edge-IO hardware packets
- Mobile installable build / desktop package
- `v*` tag for RELEASED gate
