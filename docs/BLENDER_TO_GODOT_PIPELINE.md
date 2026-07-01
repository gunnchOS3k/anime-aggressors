# Blender → Godot Character Pipeline

**Status:** Production pipeline spec  
**Character source of truth:** Blender `.blend` files  
**Runtime import:** Godot 4 — `game-godot/assets/characters/`

---

## Source layout

| Location | Contents |
|----------|----------|
| `tools/blender/` | Export scripts, rig templates |
| `assets/blender/fighters/<fighter-id>/` | Source `.blend` per fighter (create as authored) |
| `game-godot/assets/characters/proxy/` | Proxy `.glb` for pipeline validation |
| `game-godot/assets/characters/authored/` | Production `.glb` when ready |

Export command (example):

```bash
python tools/blender/export_all_fighters.py --fighter ember-vale --out game-godot/assets/characters/proxy/
```

---

## Required skeleton bones (minimum)

- `root` / `pelvis`
- `spine`, `chest`, `neck`, `head`
- `shoulder_l/r`, `arm_l/r`, `hand_l/r`
- `leg_l/r`, `foot_l/r`

Fighter-specific weapon bones optional per design.

---

## Required sockets (Godot `BoneAttachment3D` or named empties)

| Socket | Purpose |
|--------|---------|
| `head` | Camera aim, UI markers |
| `chest` | Hurtbox center, aura attach |
| `left_hand` / `right_hand` | Weapon trails, grab |
| `left_foot` / `right_foot` | Dust VFX, ledge checks |
| `weapon` | Element weapon pivot |
| `aura_center` | Aura charge VFX |
| `hit_center` | Hitbox debug overlay |

---

## Required animation clips

| Clip | Used by |
|------|---------|
| `idle` | Menu preview, battle idle |
| `walk` | Ground locomotion |
| `run` | Run state |
| `dash` | Dash state |
| `jump` | Jump squat / takeoff |
| `fall` | Air fall |
| `land` | Landing lag |
| `jab` | Jab move timeline |
| `heavy` | Heavy / smash attacks |
| `special` | Special moves |
| `shield` | Shield hold |
| `hurt_light` | Light hitstun |
| `hurt_heavy` | Heavy hitstun |
| `launched` | Knockback tumble |
| `aura_charge` | Aura charge state |
| `aura_burst` | Aura super |
| `ko` | Blast zone KO |

Manifest: `game-godot/data/fighters/<id>_animations.json`

---

## Export settings (.glb)

- Format: glTF 2.0 Binary (`.glb`)
- Include: meshes, skeleton, animations
- Scale: 1 Blender unit = 1 Godot meter (document per fighter if scaled)
- Apply modifiers before export
- No copyrighted third-party meshes

---

## Godot import validation

Run as part of `validate:full-scope-production`:

1. Each fighter `modelPath` in JSON resolves or is explicitly `proxy` status
2. Proxy models display **PROXY — NOT FINAL ART** label in debug HUD
3. Animation manifest lists required clip names
4. Sockets documented in fighter JSON or rig scene

---

## Production status labels

| Status | Meaning |
|--------|---------|
| `placeholder` | Data only, no model |
| `proxy` | Pipeline-valid proxy `.glb` |
| `authored` | Art-approved model, animations partial |
| `production` | Signed off for public playtest |

---

## Unreal (R&D only)

Unreal may receive look-dev exports for lighting/VFX reference. **Do not** treat Unreal as the shipping import path for this Godot product.
