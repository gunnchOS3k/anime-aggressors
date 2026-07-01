# Legacy Web Runtime Status

**Status:** Active — secondary / deprecated for gameplay  
**Last updated:** 2026-07-01  
**Primary runtime:** Godot 4, `game-godot/`  
**Related:** [Product runtime pivot](./PRODUCT_RUNTIME_PIVOT.md) · [Engine migration decision](./ENGINE_MIGRATION_DECISION.md)

---

## Summary

The **TypeScript + Vite + Three.js** path in `apps/web` is the **Legacy Web Runtime**. It remains in the repository for tooling, specification tests, GitHub Pages hosting, and temporary preview. It is **not** the authoritative place for gameplay tuning, balance feel, or production UX.

> **Warning:** Changes to `packages/game-core` constants, combat tuning, or match rules in TypeScript **may not be reflected** in the Godot primary runtime until explicitly ported and validated. Treat Godot playtests as the source of player-facing truth.

---

## Runtime labels

The web shell should display which runtime the player is entering:

| Label | Route / entry | Role |
|-------|---------------|------|
| **Godot Runtime** | `#/godot`, default Home CTA | Primary gameplay (embed or link to export) |
| **Legacy Web Runtime** | `#/battle`, `#/play`, legacy Start Match | Deprecated Three.js battle |
| **Experimental / Labs** | Derby, career experiments, debug | Not primary balance |

If no label is visible, assume **Legacy Web Runtime** for any route that runs `apps/web` Canvas battle code.

---

## What the legacy web path still does

### Active capabilities

| Feature | Location | Notes |
|---------|----------|-------|
| **GitHub Pages shell** | `apps/web` | Hosts docs links, Godot embed, hash routing |
| **Match setup UI** | `#/match-setup/*` | Rules, stage, fighters, controls (web-only state) |
| **Three.js battle** | `#/battle`, `#/play` | Procedural rendering; `RollbackSession` + `game-core` |
| **Training (web)** | `#/training` | Legacy training lab |
| **Career / meta** | `#/career/*` | Stats, history, replays (web storage) |
| **Godot embed screen** | `#/godot` | Loads exported Godot web build from `public/godot/` |
| **Input profiles** | `localStorage` | Keyboard/gamepad maps for web battle |
| **Ruleset storage** | `localStorage` | Custom presets for web setup |
| **CI / build** | `npm run build`, `build:pages` | Produces deployable artifact |

### TypeScript packages (not deprecated)

| Package | Status |
|---------|--------|
| `packages/game-core` | **Active** — spec oracle, unit tests |
| `packages/rollback` | **Active** — harness / design reference |
| `packages/edgeio` | **Active** — protocol spec |
| `packages/netplay` | Experimental |

These packages are **not** legacy. Only the **web Canvas gameplay presentation** is legacy.

---

## What is deprecated

| Item | Deprecation | Replacement |
|------|-------------|-------------|
| Three.js battle as primary game | Phase 4 | Godot `game-godot/` battle scene |
| Web match-setup state as source of truth | Immediate | Godot setup scenes + `user://` saves |
| `localStorage` match setup driving Godot | Immediate | Independent Godot setup pipeline |
| Procedural fighter rendering as production art | Phase 3 | Authored `.glb` rigs in Godot |
| “Start Match” without runtime label | Immediate | Labeled Legacy Web Runtime |
| Implicit assumption that green TS tests = shipped feel | Immediate | Godot manual playtest + parity checks |

**Not deprecated:** unit tests, typecheck, web build, Godot export scripts, documentation site, fighter JSON specs in `docs/fighters/`.

---

## localStorage and route ambiguity

### Web-only keys

| Key | Purpose | Godot reads? |
|-----|---------|--------------|
| `anime-aggressors.activeMatchSetup` | Match setup session | **No** |
| Ruleset presets key | Saved rules | **No** |
| Input profile keys | Per-player bindings | **No** |
| Demo onboarding / audio keys | Shell preferences | **No** |

### Route overlap

Multiple hash routes can start a match or present a “play” experience:

- `#/godot` — Godot export (primary)
- `#/match-setup/rules` → … → `#/battle` — legacy web pipeline
- `#/play` — alternate battle entry
- Quick Match shortcuts — may apply web defaults only

**Testing guidance:**

1. For **gameplay feel**, always test **`game-godot/`** locally or `#/godot` embed after export.
2. For **rules regression**, run `npm test` in `packages/game-core`.
3. Do not file gameplay bugs against TS-only unless explicitly testing Legacy Web Runtime.
4. Clear `localStorage` when switching between web setup and Godot to avoid stale setup confusion.

---

## Godot web embed vs native

| Path | Use |
|------|-----|
| **Native Godot** (editor F5, desktop export) | Primary development and playtest |
| **Web embed** (`#/godot`) | Distribution preview on GitHub Pages |
| **Legacy web battle** | Comparison baseline only; labeled deprecated |

Web embed may lag native Godot in performance and input latency. Native builds are preferred for feel validation.

---

## Migration timeline (web deprecation)

| Phase | Web runtime behavior |
|-------|----------------------|
| **Phase 0–1** | Home defaults to Godot; legacy paths labeled |
| **Phase 2** | Legacy battle frozen except critical fixes |
| **Phase 3** | Match-setup redirects documented; TS tuning flagged |
| **Phase 4** | Legacy battle removed from default navigation; optional Labs link only |

See [PRODUCT_RUNTIME_PIVOT.md](./PRODUCT_RUNTIME_PIVOT.md) for full phases.

---

## Developer workflow

### When to edit TypeScript

- Adding or changing **rules** in `game-core` with unit tests
- Data validation scripts and CI
- Web shell routing, labels, Godot embed wiring
- Documentation and tooling

### When to edit Godot

- Anything the **player feels**: movement, knockback, HUD, menus, animation, VFX, audio
- Controller UX and console flow
- Fighter/stage presentation

### Porting discipline

When changing combat constants in `game-core`:

1. Update Godot data or scripts in `game-godot/`
2. Run TS tests
3. Run Godot playtest checklist
4. Note in PR if parity is intentional or deferred

---

## Build commands (legacy path)

```bash
npm run dev          # Web shell + hot reload
npm run build        # Production web artifact
npm run build:pages  # Pages deploy incl. Godot export when CLI available
npm test             # game-core + web tests
npm run typecheck    # Monorepo types
```

Godot primary runtime:

```bash
# Open game-godot/project.godot in Godot 4.3+
# Or see game-godot/README.md for CLI export
```

---

## FAQ

**Q: Is the web app being deleted?**  
No. The shell, tests, and embed remain. Only **gameplay authority** moves to Godot.

**Q: Should I balance fighters in `feel.ts`?**  
Only as spec exploration. Ship tuning in Godot and backport to TS tests when stabilizing rules.

**Q: Why does my fighter pick not appear in Godot?**  
Web `localStorage` does not sync. Select fighters in Godot setup.

**Q: Are green CI tests enough to ship?**  
No. They validate the TS oracle, not full Godot presentation or feel.

---

## Related documentation

- [PRODUCT_RUNTIME_PIVOT.md](./PRODUCT_RUNTIME_PIVOT.md) — pivot rationale and phases
- [CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md](./CONSOLE_PLATFORM_FIGHTER_UX_SPEC.md) — target UX in Godot
- [GODOT_RUNTIME_INTEGRATION.md](./GODOT_RUNTIME_INTEGRATION.md) — embed and export mechanics (may reference `game/godot/` during transition)
- [ARCHITECTURE.md](./ARCHITECTURE.md) — monorepo layout (update track authority as pivot lands)
