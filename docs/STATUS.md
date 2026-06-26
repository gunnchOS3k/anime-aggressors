# Anime Aggressors — Status

**Last updated:** 2026-06-24  
**Branch:** `fix-pages-source-of-truth`  
**Product:** 2.5D platform fighter (Three.js renderer + deterministic game-core)

## GitHub Pages source of truth

Public site was serving mixed/stale content because:

- Repo root `index.html` + `vite.config.ts` were a **legacy mini-game shell** (competing with `apps/web`).
- GitHub Pages **Source** was set to **Deploy from branch / main / /** (`build_type: legacy`), while a separate Actions workflow also uploaded `apps/web/dist`.
- Committed `apps/web/dist/` could drift from CI-built artifacts.

**Fix (this branch):**

- Archive root web entry to `legacy/root-web/`.
- Gitignore `apps/web/dist/` — production artifact is CI-only.
- Harden `pages.yml`: `npm run build:pages`, marker asserts, `deploy-info.txt`, `apps/web/dist` upload.
- Document required setting: **Pages → Source → GitHub Actions** (`docs/GITHUB_PAGES_DEPLOYMENT.md`).
- Add visible build footer + `/deploy-info.txt` for verification.

## CI note (post PR #7)

After the netplay lockfile fix, `npm run typecheck` failed in CI because `@anime-aggressors/netplay` resolves `@anime-aggressors/rollback` via package `exports` pointing at `dist/`. The root `typecheck` script built `game-core` but not `rollback` before netplay typecheck. Fixed by building rollback before workspace typechecks.

## Friend playtest (PC)

- **Web (live):** https://gunnchOS3k.github.io/anime-aggressors/ — see `docs/playtest/PC_PLAYTEST_GUIDE.md`
- **Windows ZIP:** SHIP BLOCKED — `npm run build:desktop:win` not implemented; target `releases/windows/AnimeAggressors-Playtest-v0.2.0.zip`
- **Distribution stages:** `docs/PC_DISTRIBUTION_PLAN.md`

Ship gate vocabulary:

| Gate | Meaning |
|------|---------|
| **UNSHIPPED** | Not available to users |
| **SHIP BLOCKED** | Implementation exists but fails a quality gate |
| **PLAYABLE** | User can launch and play it |
| **PROVEN BY TEST** | CI/automated tests cover it |
| **PROVEN BY DEMO** | Public demo (GitHub Pages) demonstrates it |
| **RELEASED** | Tagged release / artifact exists |

---

## Playable today

| Capability | Gate | Evidence |
|------------|------|----------|
| **Play Match** — 2P stock battle, Skyline Arena | PLAYABLE | `apps/web` → **Play Match** |
| Three.js 2.5D renderer (orthographic camera, placeholders, VFX) | PLAYABLE | `apps/web/src/renderer-three/` |
| Character select → countdown → fight → results → rematch | PLAYABLE | `apps/web/src/game/App.ts` |
| Training Mode + debug overlay (F1–F4, hitboxes) | PLAYABLE | **Training Mode** on homepage |
| Controller Test | PLAYABLE | `apps/web/src/shell/controllerTest.ts` |
| Rollback Debug shell | PLAYABLE | `apps/web/src/shell/rollbackDebug.ts` |
| Edge-IO Lab (gesture mapping) | PLAYABLE | `apps/web/src/shell/edgeioLab.ts` |
| Prototype Lab mini-games | PLAYABLE | `apps/web/src/minigames/` (demoted from main CTA) |
| Deterministic game-core (60 Hz, frame data, blast zones) | PROVEN BY TEST | `npm run test -w @anime-aggressors/game-core` |
| Rollback harness | PROVEN BY TEST | `npm run test -w @anime-aggressors/rollback` |
| Edge-IO binary protocol | PROVEN BY TEST | `npm run test -w @anime-aggressors/edgeio` |
| Local loopback netplay | PROVEN BY TEST | `npm run test -w @anime-aggressors/netplay` |
| Impact Dummy Derby | PLAYABLE + PROVEN BY TEST | `#/impact-dummy-derby` |

---

## Ship blocked / in progress

| Item | Gate | Blocker |
|------|------|---------|
| GLB character/stage assets | SHIP BLOCKED | Placeholders only; pipeline stubbed |
| Production combat polish | SHIP BLOCKED | Basic frame data; needs tuning |
| Online multiplayer (public relay) | SHIP BLOCKED | Loopback PROVEN BY TEST; relay not deployed |
| Edge-IO hardware loop | UNSHIPPED | No BLE UI / firmware in CI |
| Mobile / desktop apps | UNSHIPPED | Scaffold only |
| Tagged release | UNSHIPPED | No v0.2 tag yet |

---

## Architecture (authoritative vs presentation)

```
packages/game-core     → GameState truth
packages/rollback      → rollback / replay truth
apps/web/renderer-three → read GameState, render only
```

See `docs/RENDERER_THREE_CONTRACT.md`.

---

## Legacy / archived

| Path | Status |
|------|--------|
| `legacy/web/` | Archived React PWA — not in CI |
| `legacy/game-prototype/` | Superseded by game-core + native/engine |
| `apps/web/src/game/renderCanvas.ts` | Legacy 2D canvas — superseded by Three.js |

---

## Verify locally

```bash
npm ci
npm run quality
npm run dev
```

Use `docs/VISUAL_ACCEPTANCE_CHECKLIST.md` before claiming PROVEN BY DEMO.
