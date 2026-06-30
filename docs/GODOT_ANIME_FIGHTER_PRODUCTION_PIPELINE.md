# Godot Anime Fighter Production Pipeline

## 1. Why the current Godot prototype failed visually

The earlier Godot web build looked like stick figures because:

- The **rescue runtime** (canvas 2D fallback) activated when the versioned export was slow or cached incorrectly.
- Fighters used **minimal box rigs** without silhouette accents, toon materials, or socket-attached VFX.
- Attacks moved the **root/torso** instead of limbs, so hits did not read as anime fighting-game strikes.

A file existing in the repo is not progress. The vertical slice must be **visible on GitHub Pages** without hard refresh.

## 2. How anime fighting games solve 3D characters

- Stylized **anime proportions** (larger hands/feet/head).
- **Cel/toon materials** with rim light for readability.
- **Element accents** (gauntlets, scarves, mantles) for roster identity.
- Attacks authored on **limb sockets**, not body center.

## 3. How platform fighters prioritize readable silhouettes

- Camera frames **both fighters** and stage context.
- Silhouette beats texture at gameplay distance.
- VFX spawns at **hands/feet/weapons**, not torso center.

## 4–10. Pipelines

| Pipeline | Implementation |
|----------|----------------|
| Model | `ProductionFighterFactory.gd` + optional Blender GLB import |
| Rig | `ProductionFighterRig.gd` with named limb + socket nodes |
| Animation | `FighterAnimationLibrary.gd` + `FighterAnimationDriver.gd` |
| Choreography | `MoveChoreography.gd` + `AttackSocketTimeline.gd` |
| Hitbox/socket | `HitboxSocket.gd`, socket sync in `FighterController.gd` |
| VFX | `ElementalAuraSystem`, `HitSparkFactory`, `AttackTrailFactory` |
| Camera/impact | `PlatformFighterCamera.gd` + `CameraImpactDirector.gd` |

## 11. Anime Aggressors vertical-slice standard

**Route:** `#/godot`  
**Mode:** Normal Battle  
**Stage:** Skyline Arena  
**Fighters:** Ember Vale vs Juno Spark  

Acceptance:

- Normal page load (no Command+Shift+R)
- Build ID badge visible
- Volumetric fighters, not stick figures
- Character select → Ready/Fight → battle → results
- Socket-based hits, aura, sparks, camera punch

See also: `BLENDER_TO_GODOT_CHARACTER_PIPELINE.md`, `GODOT_VERTICAL_SLICE_QA.md`.
