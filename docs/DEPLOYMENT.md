# Deployment — Anime Aggressors Public Web Demo

**Last updated:** 2026-07-01

See also: [GITHUB_PAGES_DEPLOYMENT.md](./GITHUB_PAGES_DEPLOYMENT.md)

---

## Quick start (local)

```bash
npm ci
npm run typecheck
npm test
npm run build
npm run preview -w anime-aggressors-web
```

Open: http://localhost:4173/anime-aggressors/

---

## Production build artifact

| Command | Output |
|---------|--------|
| `npm run build` | `apps/web/dist` (web demo only) |
| `npm run build:pages` | `apps/web/dist` + Godot export + validations (full Pages pipeline) |

Required files after `npm run build`:

```text
apps/web/dist/index.html
apps/web/dist/assets/*
```

After `npm run build:pages` also:

```text
apps/web/dist/404.html
apps/web/dist/deploy-info.txt
```

---

## Hash routes (SPA)

All routes use `#/` prefixes for GitHub Pages:

| Route | Purpose |
|-------|---------|
| `#/` | Home |
| `#/battle` | Play Demo / Quick Match |
| `#/training` | Training mode |
| `#/fighter-select` | Demo fighter select |
| `#/stage-select` | Demo stage select (3 production stages) |
| `#/controls` | Controls + audio settings |
| `#/about` | About / Credits |

Direct navigation to these hashes must load the app shell (`index.html` / `404.html` fallback).

---

## GitHub Pages

- **Live URL:** https://gunnchos3k.github.io/anime-aggressors/
- **Workflow:** `.github/workflows/pages.yml` (Deploy GitHub Pages)
- **Source setting:** GitHub Actions (not branch deploy)
- **Verify:** https://gunnchos3k.github.io/anime-aggressors/deploy-info.txt

### Web-only vs full Pages build

| Use case | Command |
|----------|---------|
| Public demo CI / local | `npm run build` |
| Full site with Godot embed | `npm run build:pages` |

Milestone 5 public demo readiness is satisfied by **`npm run build`** web artifact.

---

## Browser caveats

- **Desktop Chrome/Firefox/Safari/Edge:** primary targets
- **Gamepad:** W3C Gamepad API — user gesture may be required before input registers
- **Audio:** Web Audio requires user interaction; first click starts audio context
- **Mobile/touch:** not production-ready — no on-screen controls in M5
- **Private browsing:** localStorage for onboarding/audio may not persist
- **Hardware acceleration:** disable may reduce Three.js frame rate

---

## Environment variables

None required for public demo build. Vite `base` is `/anime-aggressors/` for project-site hosting.

---

## Rollback deploy

Revert merge on `main` and re-run Pages workflow, or redeploy prior `deploy-info.txt` commit SHA.
