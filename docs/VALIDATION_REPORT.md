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
