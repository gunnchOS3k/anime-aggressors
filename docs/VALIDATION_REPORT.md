# Validation Report

## Post-Flagline test failure

Root cause:
- Stale `packages/game-core/dist/` artifacts from a prior Flagline branch build were present locally. `node --test dist/test/*.test.js` picked up compiled `flaglineClash.test.js` and `simpleFlaglineBot.test.js` that import `createInitialFlaglineState` from `index.js`, but `main` did not yet include Flagline source exports in `packages/game-core/src/index.ts`.
- On a clean CI checkout this manifests when Flagline tests exist in source but exports are missing; locally it also appeared when old dist test files survived across branch switches because `dist/` is gitignored.

Fix:
- Merged `flagline-clash-team-mode` so Flagline simulation, bots, and `index.ts` exports ship together with Flagline tests.
- Updated root `package.json` `test` script to run each workspace sequentially (`test:game-core`, `test:rollback`, `test:netplay`, `test:edgeio`, `test:web`) so CI logs identify the failing package immediately.
- `npm run build` in each package regenerates `dist/` from current `src/` before tests run.

Validation:
- npm ci
- npm run test:game-core
- npm run test:rollback
- npm run test:netplay
- npm run test:edgeio
- npm run test:web
- npm run test
- npm run quality
- npm run build:pages

## Start Match routing (GitHub Pages project site)

Root cause:
- Primary CTA **Play Match** used `#/play` (legacy quick launch). External docs sometimes linked `https://gunnchos3k.github.io/play`, which is outside the `/anime-aggressors/` project-site base and returns GitHub Pages 404.
- Any path-based link to `/play` (without the project prefix) navigates away from the hosted app root.

Fix:
- **Start Match** now routes to `#/match-setup/rules` with a full setup flow: Rules → Map → Fighters → Controls → `#/battle`.
- Centralized hash routes in `apps/web/src/routes.ts` and public URLs in `apps/web/src/siteUrls.ts`.
- Static tests scan sources and build artifacts for forbidden root `/play` links.

Validation:
- npm run test:web (includes `startMatchRoute`, `matchSetupFlow`, `noRootPlayLinks`, `routingNoRootPaths`, `publicUrls`, `matchSetupSession`)
- npm run build:pages (artifact scan rejects root play links)

## Pages deploy failure: missing apps/web/dist/index.html

Root cause:
- The Pages workflow asserted `apps/web/dist/index.html`, but the **Assert artifact** step also grepped for the stale label **Play Match** after the main menu CTA was renamed to **Start Match**. GitHub Actions surfaced the step as failing at `test -f apps/web/dist/index.html`, even though `npm run build:pages` had already produced the file and `finalize-pages-artifact.mjs` succeeded.

Fix:
- Made `npm run build:pages` explicitly run the `anime-aggressors-web` workspace build via `build:web` + `finalize:pages`.
- Made `apps/web/vite.config.ts` output to `apps/web/dist` with explicit `root` and `outDir`.
- Made `finalize-pages-artifact.mjs` fail loudly if `index.html` is missing.
- Updated workflow assertions to grep **Start Match** (not Play Match) and use explicit `if grep` blocks for forbidden strings.
- Added workflow debug output listing root, `apps/web`, and discovered `index.html` files.
- Upload path remains `apps/web/dist`.

Validation:
- npm ci
- npm run build:web
- npm run build:pages
- npm run quality

## Stale live site after merge (Pages deploy blocked)

Root cause:
- The **Deploy GitHub Pages** workflow can fail before upload/deploy (for example brittle UI text greps like **Play Match** / **Start Match**). GitHub Pages then keeps serving the **last successful** deployment, so the live site looks stale even after merges to `main`.

Fix:
- Removed deploy-blocking UI text greps from `.github/workflows/pages.yml`.
- Workflow now asserts only required files exist (`index.html`, `404.html`, `deploy-info.txt`) and rejects forbidden root `/play` links.
- `finalize-pages-artifact.mjs` no longer fails on UI label markers — only missing artifact, wrong base path, or forbidden root play links.
- Upload path remains `apps/web/dist`.

Correct live URLs:
- App: `https://gunnchos3k.github.io/anime-aggressors/`
- Start Match: `https://gunnchos3k.github.io/anime-aggressors/#/match-setup/rules`
- Wrong: `https://gunnchos3k.github.io/play` (requires separate root user-site redirect)

Validation:
- npm run test:web (includes `pagesDeployContract`)
- npm run build:pages
- Confirm `deploy-info.txt` commit_sha after merge
