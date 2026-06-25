# Legacy React PWA (`legacy/web`)

**Status:** Archived — not part of CI or the current product build path.

This directory contains an earlier React + Vite + PWA prototype (pages, mini-games UI, Workbox service worker). The active web product is **`apps/web`** (deterministic vertical slice + training lab).

## Why archived

- Compiled accidentally when other packages inherited the root `tsconfig.json`
- Missing workspace isolation caused JSX/Workbox errors in GitHub Actions
- Functionality superseded by `apps/web` for the rollback-first vertical slice

## If reviving this app

1. Add `legacy/web/package.json` with React, Workbox, and Vite dependencies
2. Add `legacy/web/tsconfig.json` with `"jsx": "react-jsx"`
3. Register as an optional workspace — do **not** include in default `npm run build`

## Do not

- Import from `legacy/web` in `apps/web` or `packages/*`
- Include `legacy/web` in root quality gates without making it a proper workspace
