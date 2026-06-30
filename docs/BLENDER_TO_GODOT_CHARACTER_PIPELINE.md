# Blender → Godot Character Pipeline

## Overview

1. **Source model** in `game/godot/assets/fighters/source/`
2. **Armature** with named bones matching Godot sockets
3. **Animation clips** (idle, walk, attacks, hitstun, victory)
4. **GLB export** to `game/godot/assets/fighters/glb/`
5. **Godot import** → `AnimationLibrary` / `AnimationTree`
6. **Materials** — toon/cel pass + rim outline
7. **VFX anchors** — aura, hands, feet, weapon sockets

## Optional Blender generation

```bash
blender --background --python tools/blender/generate_fighter_proxy_assets.py
```

If Blender CLI is unavailable, `ProductionFighterFactory.gd` builds equivalent in-engine proxy meshes so the public build does not require Blender.

## Socket naming contract

`aura_socket`, `left_hand_socket`, `right_hand_socket`, `left_foot_socket`, `right_foot_socket`, `weapon_socket`, `hit_center_socket`

Hitboxes and particles must attach to these nodes, not the character root.
