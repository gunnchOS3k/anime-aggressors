# AAA Production Workflow (Adapted for Indie Scope)

Triple-A teams succeed because **roles, gates, and asset contracts** are explicit. Anime Aggressors adopts the same discipline at indie scale.

## Pipeline stages

1. **Design** — Fighter spec, move list, difficulty, fantasy (`docs/fighters/`)
2. **Art** — Blender model + materials + silhouette sign-off
3. **Rigging** — Skeleton, sockets, export validation
4. **Animation** — Locomotion + attacks + hit reactions + victory/defeat
5. **Combat design** — `MoveChoreography` timelines (hitbox, VFX, camera, audio)
6. **Engine import** — Godot `.glb` + `AnimationLibrary`; Unreal R&D reference
7. **Integration** — Sockets drive hitboxes and particles
8. **QA** — Playtest recording + acceptance gate checklist
9. **Release** — Pages deploy + manual playtest on `#/godot`

## Daily cadence (producer)

- One playtest clip or screenshot per active milestone
- Asset tracker: which fighters have **production** vs **DEBUG FALLBACK**
- No "done" without `DEFINITION_OF_DONE.md` checklist

## Role ownership

See `docs/production/` — Lead Game Designer, Engineer, Producer, Art/Animation/VFX/QA directors.

## Tools

| Tool | Purpose |
|------|---------|
| Blender | Source models, rigs, clips |
| Godot | Web runtime, choreography runtime |
| Unreal | High-fidelity R&D reference |
| GitHub Actions | CI + Pages |
| `validate:godot-product` | Blocks debug-as-final |
