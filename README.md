# Anime Aggressors

Anime Aggressors is a **2.5D platform fighter** with rollback-first deterministic gameplay and optional Edge-IO wearable input/haptics.

**Branch:** `threejs-platform-fighter-pivot`

## Play now

| Mode | Description |
|------|-------------|
| **Play Match** | 2-player local stock battle on Skyline Arena (Three.js renderer) |
| **Training Mode** | Match + debug overlay (F1–F4, hitbox toggles) |
| **Controller Test** | Live keyboard / gamepad input display |
| **Rollback Debug** | Deterministic rollback + replay scenario |
| **Edge-IO Lab** | Gesture → input mapping sandbox |
| **Prototype Lab** | Legacy mini-game experiments (not the main product) |

```bash
npm install
npm run dev
```

Open the URL Vite prints (e.g. `http://localhost:5173/anime-aggressors/`) and click **Play Match**.

## What ships first

The first shippable target is a complete 2-player local platform-fighter match rendered in Three.js with deterministic game-core simulation and rollback-ready architecture.

## Ship gates

| System | Gate | Proof |
|--------|------|-------|
| Three.js 2.5D match renderer | PLAYABLE | GitHub Pages / local `npm run dev` |
| Deterministic game-core | PROVEN BY TEST | `npm run test -w @anime-aggressors/game-core` |
| Rollback harness | PROVEN BY TEST | `npm run test -w @anime-aggressors/rollback` |
| Prototype Lab mini-games | PLAYABLE | Prototype Lab |
| Online multiplayer | UNSHIPPED | — |
| Edge-IO hardware | UNSHIPPED | — |
| Mobile app | UNSHIPPED | — |
| Desktop app | UNSHIPPED | — |

See **[docs/STATUS.md](docs/STATUS.md)** for the full capability matrix.

---

## Architecture

```
packages/game-core     — deterministic combat, movement, hitboxes, stocks
packages/rollback      — input history, snapshots, rollback, replay
apps/web/src/renderer-three — Three.js read-only presentation
apps/web               — menus, match shell, training / debug modes
native/engine          — C++ determinism track (later WASM/native)
```

**Critical rule:** Three.js reads `GameState`; it never mutates authoritative gameplay state.

---

## Controls

| Player | Movement | Jump | Attack | Special | Shield | Dodge | Grab |
|--------|----------|------|--------|---------|--------|-------|------|
| P1 | Arrows | ↑ / Space | Z | X | C | V | B |
| P2 | WASD | W | 1 | 2 | 3 | 4 | 5 |

**Training / debug:** F1 overlay · F2 hitboxes/hurtboxes · F3 pause · F4 step · R reset

Gamepads auto-assign: pad 0 → P1, pad 1 → P2.

---

## Tests and quality

```bash
npm ci
npm run typecheck
npm run test
npm run build
npm run quality
npm run build:pages
```

---

## Repo layout

```
apps/web/              Web app — Play Match, Training, debug shells
apps/web/src/renderer-three/  Three.js renderer (non-authoritative)
packages/game-core/    Deterministic simulation
packages/rollback/     Rollback session harness
packages/edgeio/       Wearable binary protocol
native/engine/         C++ engine skeleton
legacy/web/            Archived React PWA (not in CI)
```

---

## Docs

- [STATUS](docs/STATUS.md) — ship gates and capability matrix
- [RENDERER_THREE_CONTRACT](docs/RENDERER_THREE_CONTRACT.md) — renderer ↔ game-core boundary
- [VISUAL_ACCEPTANCE_CHECKLIST](docs/VISUAL_ACCEPTANCE_CHECKLIST.md) — demo review checklist
- [ROADMAP_FULL_COMPLETION](docs/ROADMAP_FULL_COMPLETION.md)
