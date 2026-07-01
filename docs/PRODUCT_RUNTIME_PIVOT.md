# Product Runtime Pivot — Godot 4 Primary

**Status:** Approved product direction  
**Last updated:** 2026-07-01  
**Branch:** `product/runtime-pivot-godot-primary`  
**Related:** [Engine migration decision](./ENGINE_MIGRATION_DECISION.md) · [Console UX spec](./CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md) · [Legacy web runtime status](./LEGACY_WEB_RUNTIME_STATUS.md)

---

## Executive summary

Anime Aggressors pivots its **primary gameplay runtime** from TypeScript + Three.js (web) to **Godot 4 + GDScript** under `game-godot/`. The TypeScript monorepo remains valuable as a **spec, test oracle, data validation layer, tooling host, and temporary web preview** — not as the place where final combat feel, menus, or controller-first UX are authored.

This pivot does not delete existing code, tests, or documentation. It establishes a clear authority boundary so production work, playtesting, and tuning happen in Godot while TypeScript preserves deterministic rules and regression coverage until Godot reaches parity.

---

## Problem statement

### The product still feels unfinished

Despite substantial UI and navigation investment in the web shell, playtests consistently report that Anime Aggressors does not yet feel like a finished local platform fighter. Menus look more complete than combat. Movement, knockback, hit feedback, animation, and match flow tuning do not land with the immediacy players expect from a console-style fighter.

### UI changes land; gameplay changes are not felt

The web client (`apps/web`) has received iterative menu polish, hash routing, match-setup guards, and visual direction work. However:

- **Rendering is procedural** — fighters are not driven by authored rigs, choreography, or VFX timelines at production scale.
- **Simulation tuning in TypeScript** does not automatically propagate to what players experience when they launch the Godot export or a different route.
- **Designers and engineers iterate in one runtime** while **testers often play another**, producing false confidence in balance and feel.

Evidence includes split entry points (`#/`, `#/godot`, `#/match-setup/*`, `#/battle`, `#/play`), Godot combat living behind a web embed, and the legacy Three.js battle still reachable from the home screen without always making runtime authority obvious.

### Legacy routes and localStorage ambiguity

Match setup, rulesets, and onboarding state persist in browser `localStorage` keys scoped to the **web shell**, for example:

- `anime-aggressors.activeMatchSetup`
- Ruleset presets and input profiles

These keys were designed for the TypeScript match-setup flow. They do **not** represent Godot scene state. Consequences:

| Symptom | Cause |
|---------|--------|
| Player selects fighters in web setup, launches Godot, sees different defaults | Two independent setup pipelines |
| Refresh restores stale web setup; Godot boot ignores it | Storage is web-only |
| QA reports “fixed in sim tests” but “broken in play” | Tests run against `game-core`; player runs Godot or legacy web battle |
| Home CTA unclear | Multiple “start” paths with overlapping labels |

Until runtime authority is explicit, **gameplay tuning in TypeScript may not reflect the Godot build** and should not be treated as the source of player-facing truth.

### Why TypeScript should become support, not final gameplay runtime

TypeScript + Three.js proved valuable for:

- Deterministic 60 Hz fixed-point simulation (`packages/game-core`)
- Rollback harness design (`packages/rollback`)
- Rapid rules iteration with unit tests
- Browser-accessible previews without native install

It should **not** remain the final runtime because:

- Console-grade frame pacing, GPU skinning, and native controller latency exceed browser + procedural rendering limits.
- Production art pipeline (Blender → rig → animation → VFX) requires an engine built for authored assets, not code-drawn placeholders.
- Menu and battle UX target **controller-first, tile-based console flow** — costly to replicate faithfully in a SPA + Canvas stack.
- Maintaining two full gameplay implementations guarantees drift.

**Decision:** TypeScript becomes **reference, spec, tests, validation, and legacy preview**. Godot becomes **primary gameplay runtime**.

---

## Why Godot 4 is the primary gameplay runtime

| Factor | Rationale |
|--------|-----------|
| **Native feel** | Lower input latency and stable frame times on desktop; path to console exports later |
| **Asset pipeline** | Existing Blender → `.glb` → Godot workflow, socket maps, choreography timelines |
| **2.5D platform fighter fit** | Side-view stages, camera, particles, and UI nodes match genre needs |
| **Team velocity** | GDScript enables fast iteration on menus, battle, and content without a full engine rewrite |
| **Monorepo continuity** | Web shell can still host Godot web export for distribution; TS packages stay as oracle |
| **Rollback path** | C++ GDExtension spike remains available for deterministic sim hot paths later |
| **Scope honesty** | Unity/C# and custom C++ are deferred until design is proven in Godot |

Godot 4 under `game-godot/` is the **single place** where presentation, battle, menus, controller UX, and shipped assets converge.

---

## What remains in TypeScript

| Area | Location | Role |
|------|----------|------|
| **Simulation spec & oracle** | `packages/game-core` | Authoritative rules reference until Godot parity proven |
| **Unit & integration tests** | `packages/game-core`, `packages/rollback`, `apps/web/test` | Regression for movement, combat grammar, spawn, hash |
| **Data validation** | JSON schemas, catalog validators, CI scripts | Fighters, stages, moves must match across TS and Godot data |
| **Rollback harness** | `packages/rollback` | Design reference for future netplay; not shipping path yet |
| **Edge-IO protocol** | `packages/edgeio` | Input mapping spec for wearable experiments |
| **Web legacy preview** | `apps/web` | Temporary preview, docs hosting, GitHub Pages shell |
| **Tooling & CI** | Root `package.json` scripts, validators | `typecheck`, `test`, `build`, Godot export orchestration |
| **Documentation** | `docs/` | Product, fighter specs, pipelines |

TypeScript is **not deprecated wholesale**. It is **demoted from primary gameplay runtime** while retaining spec and quality responsibilities.

---

## What moves to Godot

| Area | Target | Notes |
|------|--------|-------|
| **Presentation** | `game-godot/scenes/`, `game-godot/assets/` | Authored visuals, lighting, camera |
| **Battle simulation (player-facing)** | `game-godot/scripts/battle/` | Becomes authoritative for feel; TS oracle until parity tests pass |
| **Menus & flow** | `game-godot/scenes/menus/`, `game-godot/scripts/menus/` | See [Console UX spec](./CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md) |
| **Controller-first UX** | Input map, focus navigation, button prompts | Primary input model |
| **Fighter & stage content** | `game-godot/data/` | Ported from existing catalogs and fighter specs |
| **Audio & VFX** | `game-godot/assets/audio/`, VFX scripts | Hitstop, aura, KO feedback |
| **Training mode** | `game-godot/scenes/` | Frame tools, dummy, move testing |
| **Results & rematch loop** | Results scene + state machine | End-to-end local match loop |

Prior experimental Godot work under `game/godot/` is superseded by `game-godot/` as the canonical project root for this pivot.

---

## Migration phases

### Phase 0 — Documentation & authority (current)

- Publish this pivot doc, updated engine decision, console UX spec, legacy web status
- Label web routes: Legacy Runtime vs Godot Runtime vs Labs
- Point default Home CTA to Godot primary entry
- Add warnings where TS tuning ≠ Godot behavior

**Exit criteria:** Docs merged; no ambiguity about which runtime is primary for gameplay work.

### Phase 1 — `game-godot/` skeleton

- Runnable Godot 4 project with boot → main menu → placeholder battle path
- Scene graph: Boot, MainMenu, ModeSelect, Ruleset, FighterSelect, StageSelect, Versus, Battle, Pause, Results, Training, Settings
- Port fighter and stage **data** (all 7 fighters, production stages)
- Keyboard + gamepad input map; controller navigation on menus
- README for local editor and export commands

**Exit criteria:** Full menu route completes without crash; battle scene loads with placeholder or minimal combat.

### Phase 2 — Battle parity (core loop)

- Local 2P (P1+P2 or P1+CPU): move, jump, attack, special, shield, dodge, damage, knockback, stocks, KO, respawn, match end
- HUD, pause, results, rematch
- Cross-check critical constants against `game-core` tests where applicable
- Mark gaps in `PRODUCTION_BLOCKERS.md` (P0/P1)

**Exit criteria:** Playtest checklist for core loop passes on Godot; P0 blockers closed.

### Phase 3 — Content & polish

- Authored fighter rigs, animations, stage art per production specs
- CPU difficulty, training tools, ruleset persistence in Godot
- Console-style UI polish per UX spec (transitions, focus, prompts)
- Data validation CI: Godot catalogs ↔ TS catalogs

**Exit criteria:** All 7 fighters playable with distinct identity; production stages selectable; training mode functional.

### Phase 4 — Deprecate web gameplay runtime

- Web shell becomes launcher/docs/embed only
- Legacy Three.js battle behind explicit “Legacy Web Runtime” label
- Remove duplicate match-setup paths or redirect to Godot
- TS `game-core` retained as oracle until optional GDExtension sim port

**Exit criteria:** No default path launches TS battle; Godot is the only supported gameplay runtime for playtests and releases.

---

## Acceptance criteria

| ID | Criterion |
|----|-----------|
| RT-01 | `game-godot/` opens in Godot 4.3+ and runs boot → main menu without errors |
| RT-02 | Start Battle flow: Ruleset → Fighter Select → Stage Select → Versus → Battle → Results → Rematch |
| RT-03 | Training and Settings reachable from main menu with working back navigation |
| RT-04 | P1 movement, jump, attack, special, shield, dodge functional in battle |
| RT-05 | Damage percent, knockback, stocks, KO, respawn, match end functional |
| RT-06 | Controller-first menu navigation with visible button prompts |
| RT-07 | All 7 fighters and production stages present in Godot data |
| RT-08 | Web home clearly identifies Legacy vs Godot vs Labs runtime |
| RT-09 | `npm run typecheck`, `npm test`, `npm run build` remain green (TS layer) |
| RT-10 | No Nintendo / Super Smash Bros. assets, logos, or trade dress in repo |

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Dual-runtime drift (TS vs Godot) | High | High | TS oracle tests; shared JSON catalogs; labeled routes |
| GDScript performance at scale | Medium | Medium | Profile early; GDExtension spike for sim hot paths |
| Determinism regression | Medium | High | Keep fixed-point spec in TS; parity tests before netplay |
| Web export size/latency | Medium | Low | Godot web for preview only until native builds mature |
| Team split across stacks | Medium | Medium | Godot owns gameplay PRs; TS owns spec/tests/tooling |
| Incomplete migration perceived as “done” | High | High | P0/P1 blockers doc; honest playtest checklists |
| IP/trade dress leakage | Low | Critical | Original AA branding only; UX principles not assets |

---

## Definition of done (pivot foundation)

The runtime pivot **foundation** is done when:

1. **Documentation** — This doc, engine decision, UX spec, and legacy status are published and linked from README.
2. **Godot project** — `game-godot/` runs the full menu → battle → results loop locally.
3. **Combat foundation** — P1 (+ P2 or CPU) can complete a stock match with KO and rematch.
4. **Data parity** — All fighters and production stages exist in Godot data with validation.
5. **Authority clarity** — Web shell defaults to Godot; legacy TS battle is explicitly labeled.
6. **Quality gates** — TS CI green; Godot manual playtest checklist recorded (unchecked items honest).
7. **Blockers tracked** — All P0/P1 gaps listed in `PRODUCTION_BLOCKERS.md` with owners and fix plans.

The **full game** is not done until fighter movesets, animation, CPU, training depth, and content polish meet production acceptance gates — tracked separately from this pivot foundation.

---

## Intellectual property

Anime Aggressors is **original IP**. Console platform-fighter **interaction principles** (mode order, select grids, ready confirmation, versus splash) inform UX only.

**Do not use:**

- Nintendo, Super Smash Bros., or related logos, UI art, fonts, sounds, character art, stage art, or trade dress
- Ripped or third-party copyrighted assets

**Do use:**

- Original Anime Aggressors fighters, stages, elemental identity, ROYGBIV roster branding, and authored assets from `docs/fighters/` and production pipelines

See [Console platform fighter UX spec](./CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md) for flow reference without asset copying.

---

## Decision record

| Field | Value |
|-------|-------|
| **Primary gameplay runtime** | Godot 4 + GDScript, `game-godot/` |
| **TS/web role** | Spec, tests, validation, tooling, legacy preview |
| **C++ GDExtension** | Later spike for rollback-critical sim |
| **Unity / custom C++** | Not this phase |
| **Effective** | 2026-07-01 |
| **Revisit** | After Phase 2 battle parity playtest |
