# Full-Scope Production Plan — Anime Aggressors

**Status:** Living roadmap  
**Framing:** Phases preserve the **full** platform fighter product — not a vertical slice.  
**Primary runtime:** Godot 4 — `game-godot/`

---

## Product target (full scope)

A complete Godot-first local platform fighter with:

- Full 7-fighter roster
- Full menu → battle → results loop
- Local 1v1 + CPU
- Training mode with debug instrumentation
- Move timelines, aura, shields, dodge, grab/throw architecture
- Blender → Godot character pipeline
- TypeScript validation/oracle support
- Web export as secondary distribution

---

## Phases

### F0 — Runtime consolidation ✅ (in progress)

- `game-godot/` as canonical project
- `RUNTIME_SOURCE_OF_TRUTH.md`, legacy labeling, validation gates
- Deprecate `game/godot/` without deletion

**Exit:** No ambiguity where production gameplay work belongs.

### F1 — Full menu / battle loop

- Boot → Main Menu → **Mode Select** → Ruleset → Fighter → Stage → Versus → Countdown → Battle → Pause → Results
- No skipped menus on production path
- Debug shortcuts labeled

**Exit:** End-to-end navigation without dead ends.

### F2 — Full roster data and move manifests ✅

- Normalized fighter JSON (7/7)
- Move manifest per fighter (**23 moves each**, schema v2)
- Animation manifest stubs → authored clips
- Fighter-unique aura scaling, projectiles, throws, feedback tiers

**Exit:** `validate:full-scope-production` passes roster + move gates.

### F2b — Combat enhancement ✅

- Aura scaler, projectile runtime, directional throws, combat feedback
- Training mode exposes full combat internals
- See `game-godot/docs/COMBAT_ARCHITECTURE.md`

**Exit:** Validation catches missing combat data; each fighter has unique identity.

### F3 — Combat reliability and state machine

- Full fighter state enum (idle → KO → respawn)
- Frame-based move runner
- Hitbox/hurtbox resolver, hitstop, hitstun, launch, tumble
- Shield, dodge i-frames, aura charge/burst scaffold

**Exit:** Reliable P1 vs CPU match with stocks and KO.

### F4 — Training / debug instrumentation

- Dummy behaviors (idle, shield, jump, attack, CPU)
- Overlays: hitboxes, state, frame, input, combo counter, hit log
- Reset damage/position/aura

**Exit:** Training mode usable for combat tuning.

### F5 — Asset pipeline and proxy character pass

- Blender export conventions documented
- Proxy `.glb` per fighter with socket validation
- No unlabeled debug fallback as final art

**Exit:** All fighters load labeled proxy or authored model.

### F6 — Authored animation pass

- Replace manifest-only clips with real animation
- Move timelines bound to clips

**Exit:** Core locomotion + attack clips per production fighter.

### F7 — Stage / VFX / audio pass

- Production stages with ledges, blast zones, stage hazards (as designed)
- Hit/KO/aura VFX and SFX hooks from move timelines

**Exit:** Readable feedback in battle and results.

### F8 — CPU / balance pass

- CPU tiers use behavior tags
- Balance constants driven from `data/balance/`

**Exit:** CPU L1–3 distinct; four production fighters signed off.

### F9 — Native + web export hardening

- Desktop export smoke tests
- Web embed sync with `game-godot/` version
- GitHub Pages wrapper only — not gameplay runtime

**Exit:** Documented build targets all green for supported platforms.

### F10 — Public playtest readiness

- Manual playtest checklists signed
- P0/P1 blockers closed
- No false completion claims

**Exit:** Public playtest with honest scope statement.

---

## Current phase snapshot

| Phase | Status |
|-------|--------|
| F0 | **Active** |
| F1 | Scaffolded (mode select exists; flow wired) |
| F2 | **Data generated** — runtime integration partial |
| F3 | **Scaffolded** — state machine + combat resolver started |
| F4 | **Scaffolded** — training scene + debug HUD started |
| F5–F10 | Planned |

---

## Non-goals (this plan)

- Online ranked / rollback shipping (design reference only in TS)
- Console certification
- Unreal as shipping runtime
- Replacing full roster with subset-only delivery
