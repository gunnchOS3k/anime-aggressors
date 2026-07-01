# Roadblock Audit

Honest assessment of why Anime Aggressors still does not feel like a cohesive product.

## Blockers

1. **Engine swaps happened before the art/animation pipeline existed.** Godot loads in the browser, but there is no source-of-truth for models, rigs, or clips.

2. **Godot scene is technically loading but not product-quality.** Boot/cache fixes solved deployment; they did not solve content.

3. **Fighters are procedural placeholders, not production characters.** `ProductionFighterFactory` builds box meshes — useful for sockets and hitboxes, not for shipping art.

4. **Combat is not authored as animation + hitbox + VFX + camera choreography.** Moves exist as dictionaries; they are not tied to authored clips and timelines.

5. **Tests pass, but tests do not judge game feel.** CI validates file presence and export contracts, not silhouette readability or impact.

6. **GitHub Pages deploy is improving, but playtest quality is still low.** Users see a debug-looking scene with placeholder bodies.

7. **Too many feature surfaces, not enough production-quality core.** Menus, modes, and docs outpace fighter/stage asset completion.

8. **No asset acceptance gate.** Nothing blocks merging when fighters are still fallback geometry.

9. **No shippable-build checklist.** "Green CI" ≠ "playable product."

10. **No daily playtest gate with video/screenshots.** Progress is claimed from file diffs, not from recorded play sessions.

## Root cause

The blocker is **not** primarily engine choice. The blocker is the **missing art / animation / VFX / choreography production pipeline** and the **absence of acceptance gates** that enforce it.

## What must change

- Blender becomes editable source; Godot/Unreal import exports.
- Every fighter has a production spec before art is "done."
- Fallback geometry is labeled **DEBUG FALLBACK — NOT PRODUCTION MODEL** and fails content gates when shown as final.
- Milestones (M0–M9) replace one-off complaint patches.

See `PRODUCT_RESCUE_PLAN.md`, `ENGINE_STRATEGY.md`, and `PRODUCTION_ACCEPTANCE_GATES.md`.
