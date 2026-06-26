# Anime Aggressors

> A 2.5D anime platform fighter with rollback-first combat, couch multiplayer energy, and optional Edge-IO wearable input/haptics.

[Play the Web Build](https://gunnchOS3k.github.io/anime-aggressors/) · [Gameplay Media](docs/media/README.md) · [Give Feedback](docs/playtest/feedback-form.md)

## Choose Your Fight

Anime Aggressors is built around fast local battles, launch-heavy knockback, expressive movement, and anime-style impact. Pick a fighter, jump into Skyline Arena, and send your opponent flying.

### Current Playable Modes

- **Play Match** — 2-player platform fighter match
- **Training Mode** — practice movement, hitboxes, and attacks
- **Impact Dummy Derby** — build damage on a dummy, then launch it for distance with the Kinetic Bat
- **Controller Test** — check keyboard/gamepad inputs
- **Rollback Debug** — inspect deterministic/rollback state
- **Edge-IO Lab** — simulator and hardware test bench
- **Prototype Lab** — older experiments, no longer the main game

## Controls

| Action | Keyboard P1 | Keyboard P2 | Gamepad |
|---|---|---|---|
| Move | Arrows | WASD | Left stick / D-pad |
| Jump | Space / Up | W | Bottom face button |
| Attack | Z | 1 | Left face button |
| Special | X | 2 | Right face button |
| Shield | C | 3 | Shoulder |
| Dodge | V | 4 | Trigger |
| Grab / Extra | B | 5 | Top face button |

## Playtest With Friends

Want to help test Anime Aggressors?

1. Open the [web build](https://gunnchOS3k.github.io/anime-aggressors/).
2. Try **Play Match** and **Impact Dummy Derby**.
3. Plug in a controller if you have one.
4. Record what felt good, confusing, broken, or hype.
5. Send feedback using the [playtest form](docs/playtest/feedback-form.md).

PC testers: see [PC Playtest Guide](docs/playtest/PC_PLAYTEST_GUIDE.md) for web and Windows download routes.

---

## Build Status / Ship Gates

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
| Windows desktop ZIP | SHIP BLOCKED | see `docs/PC_DISTRIBUTION_PLAN.md` |
| Mobile app | SHIP BLOCKED | scaffold only |
| Tagged release | UNSHIPPED | run `docs/RELEASE_PROCESS.md` |

## Developer Quick Start

```bash
npm ci
npm run dev
```

Hash routes (GitHub Pages safe): `#/play`, `#/training`, `#/impact-dummy-derby`, etc.

```bash
npm run quality      # typecheck + test + build
npm run build:pages  # production Pages artifact checks
```

## Architecture

```
packages/game-core     — deterministic simulation (authoritative)
packages/rollback      — rollback / replay
packages/netplay       — loopback netplay (PROVEN BY TEST)
apps/web/renderer-three — read-only Three.js presentation
```

Three.js reads `GameState`; it never mutates gameplay truth.

## What Is Not Shipped Yet

- Public online multiplayer (relay + lobby)
- Production GLB character/stage assets
- Verified Edge-IO hardware loop
- Windows desktop playtest ZIP (`releases/windows/`)
- itch.io restricted playtest page
- Mobile / console distribution

See `docs/ROADMAP_FULL_COMPLETION.md` for the full program plan and `docs/PC_DISTRIBUTION_PLAN.md` for staged PC testing.
