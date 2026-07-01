# Anime Aggressors

> Create your fighter. Pick your element. Launch your rivals.

**Production gameplay runtime:** Godot 4 — [`game-godot/`](game-godot/)  
**TypeScript / web:** launcher, validation oracle, legacy reference preview only

See **[docs/RUNTIME_SOURCE_OF_TRUTH.md](docs/RUNTIME_SOURCE_OF_TRUTH.md)** for where work belongs.

---

## Quick start (production path)

```bash
# Open in Godot 4.2+
# Import game-godot/project.godot → press F5

# Validate data + docs from repo root:
npm run validate:full-scope-production

# Regenerate fighter/move JSON from specs:
npm run generate:godot-full-scope
```

## Web shell (secondary)

```bash
npm run dev          # Home, routing, Godot embed, labeled legacy routes
npm run build        # TypeScript packages + web shell
```

- **[Godot Primary Runtime](https://gunnchos3k.github.io/anime-aggressors/#/godot)** — web embed (may lag editor build)
- **Legacy Web Runtime** — under Labs — reference only, not final gameplay

---

## Architecture

| Layer | Path | Role |
|-------|------|------|
| **Production runtime** | `game-godot/` | Menus, battle, training, combat, assets |
| **Web shell** | `apps/web` | GitHub Pages, routing, embed, legacy preview |
| **Spec oracle** | `packages/game-core` | Tests, rules reference — **not shipping renderer** |
| **Blender** | `tools/blender/`, `assets/blender/` | Character/animation source |
| **Unreal** | R&D / look-dev only | Not required to ship |
| **Deprecated** | `game/godot/` | Pre-consolidation Godot tree |

---

## Full-scope product

Anime Aggressors is a **Godot-first full-scope** local platform fighter:

- 7-fighter roster, move manifests, state machine, training/debug mode
- Console-style menu flow, local 1v1 + CPU, stocks, aura, shields, dodge
- Blender → Godot pipeline (see [BLENDER_TO_GODOT_PIPELINE.md](docs/BLENDER_TO_GODOT_PIPELINE.md))

Roadmap: [FULL_SCOPE_PRODUCTION_PLAN.md](docs/FULL_SCOPE_PRODUCTION_PLAN.md)  
Build targets: [BUILD_TARGETS.md](docs/BUILD_TARGETS.md)  
Blockers: [PRODUCTION_BLOCKERS.md](docs/PRODUCTION_BLOCKERS.md)

**Completion is not claimed** until full-scope gates and signed playtests pass. The project remains in **product-completion mode** — not complete until all 7 fighters, stages, moves, training, and production gates pass.

---

## Quality gates

```bash
npm run typecheck
npm test                    # includes validate:full-scope-production
npm run build
```

---

## Links

[Godot embed](https://gunnchos3k.github.io/anime-aggressors/#/godot) · [Web home](https://gunnchos3k.github.io/anime-aggressors/) · [PC playtest guide](docs/playtest/PC_PLAYTEST_GUIDE.md)

**Do not use** `https://gunnchos3k.github.io/play` — use project site `/anime-aggressors/`.

---

## Controls (legacy web reference)

Production controls are defined in Godot `game-godot/project.godot`. Legacy web bindings:

| Action | P1 Keyboard | Gamepad |
|--------|-------------|---------|
| Move | A / D | Left stick |
| Jump | W | A |
| Attack | J | X |
| Special | K | B |
| Shield | L | Y |
| Dodge | I | — |

### Aura Charge

Aura Charge builds elemental power. At full meter, your fighter becomes **Super Ready** and **Aura Burst** is available (Godot: hold Shield + Special to charge; burst when full).

| Player | Keyboard (legacy web) | Godot P1 |
|--------|----------------------|----------|
| P1 | Hold **F** (or Shield + Special) | Shield + Special hold |
| P2 | Hold **/** (or Shield + Special) | P2 mappings TBD |

Aura Charge slows movement while charging and can be interrupted by heavy hits.

---

## Developer quick start

```bash
npm ci
npm run dev
npm run typecheck
npm test
npm run build
npm run generate:godot-full-scope   # regenerate Godot fighter/move JSON
```

Godot web export (secondary): `npm run godot:export:web` then `npm run build:pages` — see [BUILD_TARGETS.md](docs/BUILD_TARGETS.md).

