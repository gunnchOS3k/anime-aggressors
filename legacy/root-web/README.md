# Archived root web app (pre–`apps/web`)

This folder holds the **old root-level Vite/React mini-game shell** that previously competed with the production `apps/web` build.

**Do not deploy from here.** Production GitHub Pages must use `apps/web/dist` via the `Deploy GitHub Pages` workflow.

| File | Was |
|------|-----|
| `index.html` | Root Pages entry that loaded `/web/src/main.tsx` (mini-game-first) |
| `vite.config.ts` | Root Vite + PWA config for the legacy React app |

The current game lives in `apps/web/` with hash routing (`#/play`, `#/impact-dummy-derby`, etc.).
