# Asset License — Character Meshes

**Project:** Anime Aggressors  
**Scope:** `game-godot` fighter presentation meshes  
**Date:** 2026-07-14

## Ownership

All fighter body, face, hair/headwear, and clothing meshes rendered in battle,
select, and title cameos are **original procedural Godot meshes** authored in
`game-godot/scripts/fighters/stylized_fighter_builder.gd`.

They are built at runtime from engine primitives (`CapsuleMesh`, `SphereMesh`,
`PrismMesh`, `CylinderMesh`) with original color/material assignments. No
Blender exports, marketplace packs, Mixamo characters, or third-party GLB
bodies are used as the visible production presentation.

## Related assets

| Asset | Status | Notes |
| --- | --- | --- |
| Stylized procedural hierarchy | **Production presentation** | Faces, clothing, hair, distinct proportions |
| `assets/characters/proxy/*.glb` | Hidden / parity only | Optional AnimationPlayer source; not shown |
| Silhouette cards / SVG portraits | Original project art | 2D UI only |
| Stage / VFX materials | Project-owned | Separate from fighter body meshes |

## License posture

- Runtime fighter visuals: original work for this project.
- Do not import commercial character kits into the presentation path without a
  new license review and explicit replacement of this procedural system.
- Keep this file updated if any marketplace or commissioned mesh becomes the
  visible body of a roster fighter.
