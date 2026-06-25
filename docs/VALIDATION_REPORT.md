# Validation Report

**Date:** 2026-06-25  
**Branch:** `fix-pages-artifact-node24`  
**PR context:** Fixes GitHub Pages deploy failure from PR #20

## Commands run (local)

| Command | Result |
|---------|--------|
| `npm install` | **PASS** — lockfile updated (`zod` added) |
| `npm ci` | **PASS** |
| `npm run typecheck` | **PASS** |
| `npm run test` | **PASS** — 15 tests (8 game-core, 3 rollback, 4 edgeio) |
| `npm run build` | **PASS** — all packages + `apps/web` |
| `npm run quality` | **PASS** |
| `npm run build:pages` | **PASS** — `apps/web/dist/index.html` present |
| `cmake` native engine | **NOT RUN locally** — `cmake` not installed on dev machine; **expected PASS** on `ubuntu-latest` CI job `native-engine` |

## PR #19 CI failures — root cause and fix

| Failure | Root cause | Fix |
|---------|------------|-----|
| Cannot find `@anime-aggressors/rollback` | Workspace build order / implicit paths | Explicit `build:packages` order; `apps/web` tsconfig `paths` to package sources |
| JSX / `Play.tsx` without `--jsx` | Root `tsconfig.json` had no `files`/`include`; `packages/input` `tsc` inherited it and compiled entire repo including `web/` | Moved `web/` → `legacy/web/`; root tsconfig `files: []`; scoped `packages/input/tsconfig.json` |
| Workbox modules missing | `legacy/web/sw.ts` compiled by wrong package | Archived under `legacy/web/` — excluded from CI |
| `zod` missing in messages | Dependency not declared | Added `zod` to `packages/messages/package.json` |
| Missing `StageState` | Orphan type reference | Defined `StageState` in `packages/messages/src/types.ts` |
| `@gunnch/input` compiling unrelated files | No package tsconfig → inherited root config | Added `packages/input/tsconfig.json` with `include: ["src/**/*.ts"]`; fixed `gamepaddisconnected` typo; renamed `GamepadEvent` → `PadConnectionEvent` |

## Package-lock

**Changed:** yes — `zod` dependency + workspace boundary fixes.

## npm audit (2026-06-25)

```
4 vulnerabilities (2 moderate, 2 high)
```

Run `npm audit` for details. See `docs/SECURITY_AUDIT.md` for triage template. Vulnerabilities are primarily in dev/build toolchain (Vite/esbuild chain) — not shipped to browser runtime directly, but should be addressed on a scheduled pass.

## Remaining blockers

1. **Firmware** — still does not compile (`pio run` not gated)
2. **Mobile Expo** — scaffold only; excluded from workspace until Track D1
3. **Desktop shell** — docs only (ADR-0002)
4. **Hardware** — BOM templates/checklists only (no Gerbers)
5. **Legacy `legacy/game-prototype/`** — archived TS/C++ prototype, not in CI

## GitHub Actions expected result

`quality` job: `npm ci` → typecheck → test → build → audit (non-blocking)  
`native-engine` job: cmake configure/build/test on Ubuntu

## Next PR

**Title:** `fix(pages): upload apps/web/dist artifact and Node 24 actions`  
See `docs/VALIDATION_REPORT.md` § PR #20.

---

## PR #20 Pages failure

**Root cause:**
- GitHub Pages upload step was looking for root `dist`.
- Vite web build outputs `apps/web/dist`.

**Fix:**
- Pages artifact path changed to `apps/web/dist`.
- Added assertion that `apps/web/dist/index.html` exists before upload.
- Updated Actions to Node 24-compatible action versions (`checkout@v6`, `setup-node@v6`, `upload-pages-artifact@v5`).

**Validation:**
- `npm ci` — see commands table below
- `npm run quality`
- `npm run build:pages`
