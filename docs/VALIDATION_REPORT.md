# Validation report — GitHub Pages source of truth

**Branch:** `fix-pages-source-of-truth`  
**Date:** 2026-06-24

## Public site stale vs `main`

**Root cause:**

| Issue | Detail |
|-------|--------|
| Latest game on `main` | Yes — `apps/web`, Impact Dummy Derby, Three.js renderer, game-first README (PR #7) |
| README on `main` | Updated (game-first) after PR #7 merge |
| Stale root app | Yes — root `index.html` loaded `/web/src/main.tsx` (mini-game shell); root `vite.config.ts` was legacy PWA config |
| Pages source | Was `legacy` branch deploy from `/`; Actions workflow also ran but could be ignored |
| Committed `apps/web/dist` | Stale build artifacts tracked in git |

**Fix:**

1. Moved root `index.html` + `vite.config.ts` → `legacy/root-web/`.
2. Added `apps/web/dist/` to `.gitignore`; removed tracked dist from git.
3. Rewrote `.github/workflows/pages.yml` to run `npm run build:pages`, assert Play Match / Impact Dummy Derby markers, write `deploy-info.txt`, upload `apps/web/dist`.
4. Added `apps/web/src/version.ts` + footer `Build: Anime Aggressors Pages Build`.
5. Documented Pages setting in `docs/GITHUB_PAGES_DEPLOYMENT.md`.
6. Set repo Pages `build_type` to `workflow` (GitHub Actions).

**Verify after deploy:**

```text
https://gunnchOS3k.github.io/anime-aggressors/
https://gunnchOS3k.github.io/anime-aggressors/deploy-info.txt
```

**Validation:**

| Command | Result |
|---------|--------|
| `npm ci` | pass |
| `npm run quality` | pass |
| `npm run build:pages` | pass |

---

## Netplay rollback typecheck (PR #7)

**Root cause:**
- `@anime-aggressors/netplay` depends on `@anime-aggressors/rollback` (workspace `0.1.0`, symlink OK).
- Rollback `package.json` `exports` point to `./dist/src/index.d.ts` (built output).
- Root `typecheck` built `game-core` then ran `tsc --noEmit` on all workspaces without building rollback first.
- On clean CI (`npm ci`, no prior `dist/`), netplay typecheck failed: `TS2307: Cannot find module '@anime-aggressors/rollback'`.

**Fix:**
- Updated root `package.json` `typecheck` script to run `npm run build -w @anime-aggressors/rollback` after game-core and before workspace typechecks.
- No lockfile change required (dependency was already declared correctly).

**Validation:**

| Command | Result |
|---------|--------|
| `npm ci` | pass |
| `npm run typecheck` | pass |
| `npm run test` | pass |
| `npm run build` | pass |
| `npm run quality` | pass |
| `npm run build:pages` | pass |

---

## README + PC playtest docs

- README top half rewritten as game landing page (modes, controls, playtest CTA).
- Ship gates / dev docs moved below the fold.
- Added `docs/playtest/` (PC guide, feedback form, checklist, known issues).
- Added `docs/PC_DISTRIBUTION_PLAN.md` (Pages → Windows ZIP → itch.io → Steam).
- Added `docs/media/README.md` (banner/GIF placeholder instructions; no broken image links in README).

---

## Post-PR #5 CI failure: netplay workspace lockfile (resolved in PR #6)

**Root cause:**
- PR #5 added `packages/netplay` as workspace package `@anime-aggressors/netplay@0.1.0`.
- `package-lock.json` was not updated/committed.
- `npm ci` failed correctly because `package.json` and `package-lock.json` were out of sync.

**Fix:**
- Ran `npm install` from repo root to regenerate `package-lock.json`.
- Verified `npm ci` after deleting `node_modules`.
- Confirmed `package-lock.json` includes `packages/netplay` and `node_modules/@anime-aggressors/netplay`.

**Validation:**

| Command | Result |
|---------|--------|
| `npm ci` | pass |
| `npm run typecheck` | pass |
| `npm run test` | pass (45 tests) |
| `npm run build` | pass |
| `npm run quality` | pass |
| `npm run build:pages` | pass |

---

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
