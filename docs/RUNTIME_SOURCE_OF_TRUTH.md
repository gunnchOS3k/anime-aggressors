# Runtime Source of Truth — Anime Aggressors

**Status:** Policy — authoritative  
**Last updated:** 2026-07-01  
**Audience:** Engineering, art, QA, production

---

## Policy (read this first)

| Path | Role | Production gameplay? |
|------|------|--------------------|
| **`game-godot/`** | **Godot 4 production runtime** — menus, battle, training, combat, assets | **YES — only here** |
| **`apps/web`** | Launcher, docs host, GitHub Pages wrapper, legacy web preview embed | **NO** |
| **`packages/game-core`** | Reference/test oracle — movement math, combat rules, roster specs | **NO** |
| **`packages/rollback`**, **`netplay`**, **`edgeio`** | Design references, harnesses, protocols | **NO** |
| **`game/godot/`** | Deprecated pre-consolidation Godot tree | **NO** (migrate into `game-godot/` or archive) |
| **`tools/blender/`**, **`assets/blender/`** | Character/animation **source of truth** (`.blend`) | Source only |
| **`assets/characters/`** (exported `.glb`) | Imported Godot character assets | Presentation |
| **Unreal** | R&D / look-dev / cinematics reference | **NOT required to ship** |

> **Rule:** If it affects how the game *plays* for a player (movement, hits, stocks, menus, training, CPU), it belongs in **`game-godot/`**.  
> TypeScript may **describe**, **validate**, and **generate** data for Godot — it must not become the shipping gameplay renderer again.

---

## What each layer does

### `game-godot/` (production runtime)

- Controller-first menu flow: Boot → Main Menu → Mode Select → Ruleset → Fighter Select → Stage Select → Versus → Battle → Results
- Full roster (7 fighters), move manifests, state machine, combat resolver
- Training mode with debug instrumentation
- Native desktop playtest target; web export is secondary
- Blender-imported `.glb` rigs when available; labeled proxy placeholders until authored

### `apps/web` (shell only)

- Hash routing, home screen, career metadata (web storage)
- Embeds or links to Godot web export (`#/godot`)
- **Legacy Web Runtime** routes (`#/battle`, `#/training`, etc.) — reference preview only
- Runtime banners label: Godot / Legacy Web / Labs

### `packages/game-core` (oracle)

- Unit tests for movement, combat grammar, roster rules
- Data used to generate/validate Godot JSON — not authoritative at runtime
- **Do not add new production gameplay features here**

### Blender (character pipeline)

- Skeleton, sockets, animation clips exported to `.glb`
- See [BLENDER_TO_GODOT_PIPELINE.md](./BLENDER_TO_GODOT_PIPELINE.md)

### Unreal (R&D only)

- High-fidelity combat feel experiments, VFX reference, cinematics
- Not on the shipping critical path for the current Godot-first product

---

## Deprecated / experimental

| Item | Status |
|------|--------|
| Three.js battle renderer | Legacy Web Runtime — reference only |
| `game/godot/` | Deprecated — use `game-godot/` |
| Unlabeled debug stick figures | Blocked — must show proxy/fallback label |
| `localStorage` match setup as Godot truth | Deprecated — Godot `user://` / session state |

---

## Where to work (quick reference)

| Task | Location |
|------|----------|
| New attack timeline | `game-godot/data/moves/` + `scripts/combat/` |
| Fighter balance | `game-godot/data/balance/` + `data/fighters/` |
| Menu UX | `game-godot/scenes/menus/` |
| Training overlays | `game-godot/scenes/training/` |
| CI data validation | `scripts/validate-full-scope-production.mjs` |
| Generate Godot data from specs | `scripts/generate-godot-full-scope-data.mjs` |
| Web home / routing | `apps/web/` (no new combat logic) |
| Math/regression tests | `packages/game-core/test/` |

---

## Related documents

- [FULL_SCOPE_PRODUCTION_PLAN.md](./FULL_SCOPE_PRODUCTION_PLAN.md)
- [BUILD_TARGETS.md](./BUILD_TARGETS.md)
- [BLENDER_TO_GODOT_PIPELINE.md](./BLENDER_TO_GODOT_PIPELINE.md)
- [LEGACY_WEB_RUNTIME_STATUS.md](./LEGACY_WEB_RUNTIME_STATUS.md)
- [NO_TS_PRODUCTION_GAMEPLAY.md](./NO_TS_PRODUCTION_GAMEPLAY.md)
- [game-godot/README.md](../game-godot/README.md)

---

## Acceptance

Production gameplay work is **misplaced** if it lands only in `apps/web` or `packages/game-core` without a corresponding Godot implementation and validation update.
