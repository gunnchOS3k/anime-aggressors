# Fighter Model, Rig, and Animation Pipeline Study

## What anime / superhero fighters do (and stick figures do not)

Fighting games and anime arena fighters rely on:

- Authored character silhouettes
- Skeletal rigs / bone hierarchies
- Animation state machines
- Blend trees / blend spaces
- Move choreography with frame data
- Attack sockets on hands, feet, and weapons
- Hurtboxes attached to body regions
- VFX sockets at fists, feet, weapon tips, chest, and aura points
- Anticipation / active / impact / recovery poses
- Hitstop, camera impulse, screen shake, hit sparks, trails, and particle bursts

Stick figures and center-point tilts are placeholder diagnostics only.

## Anime Aggressors target

2.5D anime platform fighter:

- 3D stylized low-poly / chibi-proportioned fighters (`FighterRig3D` + `MeshInstance3D` parts)
- Readable silhouettes with oversized hands, boots, and element accents
- `AnimationPlayer` + `FighterAnimationTreeDriver` state travel
- Hitboxes attached to limb sockets (`HitboxSocket`, `FighterMoveChoreography`)
- Particles attached to VFX sockets (`ElementalVfxFactory`, `VfxSocket`)

## Web reference

The TypeScript/Three.js `LowPolyHumanoid` pipeline in `apps/web/src/renderer-three/fighters/` informed Godot proportions:

- Larger readable bodies
- Character-specific silhouette parts
- Element aura colors
- Limb-based strike anchors

Godot fighters should be **at least as readable** as the web build.

## Godot implementation map

| Concern | Files |
|---------|-------|
| Volumetric rig | `FighterRig3D.gd`, `FighterRigFactory.gd`, `scenes/fighters/FighterRig3D.tscn` |
| Seven fighters | `FighterRigFactory.gd` profiles + `FighterAppearance.gd` palettes |
| Animation states | `FighterAnimationStates.gd`, `FighterAnimationTreeDriver.gd` |
| Move choreography | `MoveChoreography.gd`, `MoveFrameData.gd`, `FighterMoveChoreography.gd` |
| Hit / VFX sockets | `HitboxSocket.gd`, `VfxSocket.gd`, `ElementalVfxFactory.gd` |
| Rescue fallback | `rescue-runtime.js` — labeled **NOT FINAL GODOT BUILD** |

## Validation

```bash
node scripts/validate-godot-fighter-quality.mjs
```
