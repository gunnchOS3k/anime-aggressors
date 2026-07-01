# Engine Migration Decision — Anime Aggressors

**Status:** Approved  
**Last updated:** 2026-07-01  
**Effective:** 2026-07-01  
**Related:** [Product runtime pivot](./PRODUCT_RUNTIME_PIVOT.md) · [Console UX spec](./CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md) · [Legacy web status](./LEGACY_WEB_RUNTIME_STATUS.md)

---

## Decision summary

| Role | Technology | Location |
|------|------------|----------|
| **Primary gameplay runtime** | Godot 4 + GDScript | `game-godot/` |
| **Spec, tests, validation, tooling** | TypeScript monorepo | `packages/game-core`, `packages/rollback`, `apps/web` |
| **Temporary web preview / launcher** | Vite + Godot web export embed | `apps/web`, GitHub Pages |
| **Later rollback spike** | C++ GDExtension | TBD under `game-godot/` |
| **Not chosen this phase** | Unity/C#; custom C++ engine | Deferred |

TypeScript + Three.js is **no longer the final gameplay runtime**. It remains the **reference implementation and test oracle** until Godot battle logic reaches documented parity.

---

## Current state of Anime Aggressors

| Layer | Technology | Role after pivot |
|-------|------------|------------------|
| Simulation spec | TypeScript `packages/game-core` | Oracle + unit tests (M1–M4 proven) |
| Rollback harness | TypeScript `packages/rollback` | Design reference; not shipping path |
| Web client | Vite + hash routes | Launcher, legacy preview, docs host |
| Legacy rendering | Three.js procedural | Deprecated gameplay path; labeled in UI |
| **Primary runtime** | Godot 4 GDScript | Menus, battle, assets, controller UX |
| Labs | Edge-IO, derby experiments | Separated from primary flow |

Prior Godot work under `game/godot/` is consolidated into `game-godot/` as the canonical project for this decision.

---

## What TypeScript has proven

- Deterministic 60 Hz fixed-point simulation with extensive unit tests
- Platform-fighter movement feel (M2), combat grammar (M3), seven-fighter roster rules (M4)
- Rollback-friendly state hashing and `InputFrame` contract
- Rapid iteration for rules and data in a monorepo
- Browser-accessible preview without native install

These proofs **inform** Godot implementation. They do not require the web canvas to remain the shipping battle renderer.

---

## What TypeScript should not solve going forward

- Console-grade frame pacing and GPU skinning at production scale
- Native controller latency as the primary feel target
- Authored animation blending, IK, choreography, and cinematic VFX
- Controller-first menu systems with production polish
- Long-term DCC → engine art workflow at AAA indie scale

---

## What must be preserved in migration

1. **`game-core` rules as spec/oracle** — hitboxes, movement constants, combat grammar, roster data
2. **Deterministic simulation contract** — 60 Hz, `InputFrame`, reproducible tests
3. **Rollback design assumptions** — serializable state, frame inputs (for future GDExtension spike)
4. **Existing seven fighters + production stages** as content baseline
5. **Playable web path** until Godot fully replaces legacy battle (Phase 4)

---

## Option comparisons

Evaluation criteria: **performance**, **controller support**, **animation pipeline**, **UI/menu pipeline**, **asset pipeline**, **deterministic simulation**, **rollback/netplay (later)**, **web/mobile constraints**, **team velocity**.

### 1. TypeScript + Three.js (web)

| Criterion | Assessment |
|-----------|------------|
| **Summary** | Browser SPA + Canvas/Three.js; `game-core` sim in TS |
| **Performance** | Medium on desktop; high risk on mobile and with rich VFX |
| **Controller** | Gamepad API works; higher latency than native; not primary target |
| **Animation** | Procedural poses; weak for authored choreography at scale |
| **UI/menu** | DOM + custom screens; hard to match console tile UX natively |
| **Assets** | Code-first; poor fit for Blender rig pipeline |
| **Determinism** | **Strong** — already authoritative oracle |
| **Rollback/netplay** | **Best fit today** — same language as sim |
| **Web/mobile** | Desktop web OK; mobile thermal/battery weak |
| **Team velocity** | Highest for rules/tests; **low** for production fighter polish |
| **Risk** | Low for spec work; **high** if kept as final runtime |
| **Verdict** | **Retain as spec, tests, tooling, legacy preview — not primary runtime** |

### 2. Godot 4 + GDScript

| Criterion | Assessment |
|-----------|------------|
| **Summary** | Primary gameplay in Godot; GDScript for menus, battle, content |
| **Performance** | Good for indie 2.5D; native exports beat browser |
| **Controller** | **Strong** — native input, focus navigation, prompts |
| **Animation** | **Strong** with authored rigs and AnimationTree |
| **UI/menu** | **Strong** — Control nodes, themes, transitions, controller focus |
| **Assets** | Blender → `.glb` pipeline documented and in use |
| **Determinism** | Achievable; requires fixed-point discipline when porting sim |
| **Rollback/netplay** | Re-port sim or bind TS/GDExtension later |
| **Web/mobile** | Web export usable for embed; mobile/desktop exports viable |
| **Team velocity** | **High** for gameplay + content iteration |
| **Risk** | Medium — manageable with TS oracle |
| **Verdict** | **Chosen primary runtime** |

### 3. Godot 4 + C#

| Criterion | Assessment |
|-----------|------------|
| **Summary** | Godot presentation with C# for sim-heavy code |
| **Performance** | Better than GDScript for hot sim loops |
| **Controller** | Good on desktop/console exports |
| **Animation** | Same as Godot GDScript path |
| **UI/menu** | Same as Godot; C# does not improve menu UX |
| **Assets** | Same Godot pipeline |
| **Determinism** | Achievable with fixed-point discipline |
| **Rollback/netplay** | Port sim to C# or hybrid bind |
| **Web/mobile** | C# web export limited; complicates Pages embed |
| **Team velocity** | Medium-slow — heavier builds, smaller Godot+C# roster |
| **Risk** | Medium-high |
| **Verdict** | **Not chosen** — GDScript sufficient until profiling says otherwise |

### 4. Godot 4 + C++ GDExtension

| Criterion | Assessment |
|-----------|------------|
| **Summary** | Hot sim in C++; Godot for presentation and menus |
| **Performance** | **High** |
| **Controller** | Native excellent (Godot shell) |
| **Animation** | Godot side unchanged |
| **UI/menu** | Godot side unchanged |
| **Assets** | Godot presentation |
| **Determinism** | **Excellent** in C++ |
| **Rollback/netplay** | **Ideal** if sim lives in C++ |
| **Web/mobile** | Web export still constrained; native-first |
| **Team velocity** | **Slow** — build complexity, FFI boundary |
| **Risk** | High upfront |
| **Verdict** | **Later spike** if GDScript sim blocks rollback/netplay |

### 5. Unity + C#

| Criterion | Assessment |
|-----------|------------|
| **Summary** | Industry-standard 3D/2.5D toolchain |
| **Performance** | Good on target platforms |
| **Controller** | Excellent |
| **Animation** | Best-in-class for indie AAA |
| **UI/menu** | Strong with UI Toolkit / uGUI |
| **Assets** | Strong DCC pipeline |
| **Determinism** | Harder — floating-point defaults |
| **Rollback/netplay** | Custom sim layer required |
| **Web/mobile** | Poor for fighter web preview; license considerations |
| **Team velocity** | Medium — full rewrite cost |
| **Risk** | High for this repo's existing TS/Godot investment |
| **Verdict** | **Not chosen this phase** |

### 6. Custom C++ engine (later)

| Criterion | Assessment |
|-----------|------------|
| **Summary** | Own runtime after product and design proof |
| **Performance** | Highest |
| **Controller** | Full control |
| **Animation** | Build or license |
| **UI/menu** | Build from scratch |
| **Assets** | Custom tooling |
| **Determinism** | Native design |
| **Rollback/netplay** | Native design |
| **Web/mobile** | Requires WASM or separate clients |
| **Team velocity** | **Very slow** |
| **Risk** | Very high early |
| **Verdict** | **Not until design proven in Godot** |

---

## Comparison matrix (at a glance)

| Option | Perf | Controller | Animation | UI/menus | Assets | Determinism | Rollback later | Web/mobile | Velocity |
|--------|------|------------|-----------|----------|--------|-------------|----------------|------------|----------|
| TS + Three.js | ◐ | ◐ | ○ | ◐ | ○ | ● | ● | ● web / ○ mobile | ● rules / ○ polish |
| **Godot GDScript** | ● | ● | ● | ● | ● | ◐ | ◐ | ◐ | ● |
| Godot C# | ● | ● | ● | ● | ● | ◐ | ◐ | ○ web | ◐ |
| Godot C++ ext | ●● | ● | ● | ● | ● | ● | ● | ○ web | ○ |
| Unity C# | ● | ● | ●● | ● | ●● | ○ | ◐ | ○ | ◐ |
| Custom C++ | ●● | ●● | ◐ | ○ | ○ | ● | ● | ○ | ○ |

Legend: ● strong · ◐ adequate · ○ weak for this product stage

---

## Target architecture

```
┌──────────────────────────────────────────────┐
│  Godot 4 — menus, battle, HUD, results       │  ← primary runtime (GDScript)
├──────────────────────────────────────────────┤
│  Godot data — fighters, stages, moves        │  ← shared catalogs w/ validation
├──────────────────────────────────────────────┤
│  Optional: C++ GDExtension sim (later spike) │
├──────────────────────────────────────────────┤
│  TypeScript game-core — spec + unit oracle   │  ← retained until parity proven
├──────────────────────────────────────────────┤
│  Web shell — embed, docs, legacy preview     │
└──────────────────────────────────────────────┘
```

Hybrid interim acceptable: **TS `game-core` tests gate Godot constants**; Godot owns all player-facing behavior.

---

## Minimum proof for battle parity (Phase 2)

1. One production fighter (Ember Vale) + Skyline Arena fully playable in Godot
2. Movement + attack + shield + KO + rematch
3. Gamepad feel comparison vs legacy web build (documented, not blocking)
4. Frame time budget on target hardware
5. Determinism spot-check: same inputs → same KO outcome where sim is ported

---

## Recommendation

**Adopt Godot 4 + GDScript in `game-godot/` as the primary gameplay runtime immediately.**

- Implement console-style local platform fighter flow per [CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md](./CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md).
- Keep TypeScript `game-core` as the **rules oracle and test suite**; do not delete web app or CI.
- Run a **C++ GDExtension spike** only after Godot battle loop is stable and profiling shows GDScript sim is a netplay blocker.
- Do **not** start Unity or custom C++ engine work this phase.
- Deprecate Three.js **gameplay** path in Phase 4; until then, label it **Legacy Web Runtime**.

---

## Decision record

| Field | Value |
|-------|-------|
| **Primary runtime** | Godot 4 GDScript, `game-godot/` |
| **TypeScript/web** | Reference, spec, tooling, temporary preview |
| **C++ GDExtension** | Later spike for rollback |
| **Unity/C#** | Not chosen |
| **Custom C++** | Not until design proven |
| **Approved by** | Product/engineering pivot (branch `product/runtime-pivot-godot-primary`) |
| **Effective** | 2026-07-01 |
| **Next action** | Phase 1 skeleton + Phase 2 battle parity playtest |

---

## Revisit date

**2026-09-01** — Re-evaluate after:

- Godot Phase 2 battle parity playtest
- GDExtension spike results (if started)
- Data validation CI between TS and Godot catalogs
- Legacy web route traffic and confusion reports
