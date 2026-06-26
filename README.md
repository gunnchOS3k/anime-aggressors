# Anime Aggressors

Anime Aggressors is a **2.5D platform fighter** with rollback-first deterministic gameplay and optional Edge-IO wearable input/haptics.

**Branch:** `complete-unshipped-fix-pages-launch-lab`

## Play now

| Mode | Gate |
|------|------|
| **Play Match** | PLAYABLE |
| **Training Mode** | PLAYABLE |
| **Impact Dummy Derby** | PLAYABLE |
| **Controller Test** | PLAYABLE |
| **Rollback Debug** | PLAYABLE |
| **Edge-IO Lab** (simulator + BLE UI) | PLAYABLE |
| **Prototype Lab** | PLAYABLE (secondary) |

Live demo: https://gunnchOS3k.github.io/anime-aggressors/

```bash
npm install
npm run dev
```

Hash routes (GitHub Pages safe): `#/play`, `#/training`, `#/impact-dummy-derby`, etc.

## What ships first

A complete 2-player local platform-fighter match (Three.js) plus **Impact Dummy Derby** — an original damage-build-then-launch side mode with **Kinetic Bat** final hit.

## Ship gates

| System | Gate | Proof |
|--------|------|-------|
| Three.js 2.5D match | PLAYABLE | `#/play` on Pages / `npm run dev` |
| Impact Dummy Derby | PLAYABLE + PROVEN BY TEST | `#/impact-dummy-derby` / game-core tests |
| Deterministic game-core | PROVEN BY TEST | `npm run test -w @anime-aggressors/game-core` |
| Rollback harness | PROVEN BY TEST | `npm run test -w @anime-aggressors/rollback` |
| Local loopback netplay | PROVEN BY TEST | `npm run test -w @anime-aggressors/netplay` |
| WebAudio placeholder SFX | PLAYABLE | in-match hit/KO sounds |
| Edge-IO Lab simulator | PLAYABLE | `#/edgeio-lab` |
| Edge-IO hardware BLE | SHIP BLOCKED | needs verified device |
| GLB assets | SHIP BLOCKED | manifest only; placeholders render |
| Public online | SHIP BLOCKED | relay/lobby not deployed |
| Mobile app | SHIP BLOCKED | scaffold only |
| Desktop app | SHIP BLOCKED | scaffold only |
| Tagged release | UNSHIPPED | run `docs/RELEASE_PROCESS.md` |

## Architecture

```
packages/game-core     — deterministic simulation (authoritative)
packages/rollback      — rollback / replay
packages/netplay       — loopback netplay (PROVEN BY TEST)
apps/web/renderer-three — read-only Three.js presentation
```

Three.js reads `GameState`; it never mutates gameplay truth.

## Quality

```bash
npm ci
npm run release:check   # quality + pages artifact checks
```
