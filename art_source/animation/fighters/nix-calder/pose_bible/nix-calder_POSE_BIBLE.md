# Pose Bible — Nix Calder

**Status:** TEMPLATE ONLY. Not human-authored. `AUTHORED_POSE_BIBLE_PASS=false`.

- Fighter: `nix-calder`
- Lane: frost / control
- Identity: Still idle. Precise feet. Stiffness before launch.
- Rest: A-pose on canonical deform skeleton
- No franchise reproduction

## Slots

| Slot | Status | Frame / still | Notes |
|------|--------|---------------|-------|
| `neutral_idle` | WIP template | — | Human animator must block this pose |
| `combat_ready` | WIP template | — | Human animator must block this pose |
| `walk_contact_l` | WIP template | — | Human animator must block this pose |
| `walk_contact_r` | WIP template | — | Human animator must block this pose |
| `run_extreme` | WIP template | — | Human animator must block this pose |
| `dash_commit` | WIP template | — | Human animator must block this pose |
| `jump_squat` | WIP template | — | Human animator must block this pose |
| `jump_apex` | WIP template | — | Human animator must block this pose |
| `light_anticipation` | WIP template | — | Human animator must block this pose |
| `light_contact` | WIP template | — | Human animator must block this pose |
| `medium_contact` | WIP template | — | Human animator must block this pose |
| `heavy_anticipation` | WIP template | — | Human animator must block this pose |
| `heavy_contact` | WIP template | — | Human animator must block this pose |
| `heavy_follow` | WIP template | — | Human animator must block this pose |
| `aura_commit` | WIP template | — | Human animator must block this pose |
| `super_release` | WIP template | — | Human animator must block this pose |
| `charge_0` | WIP template | — | Human animator must block this pose |
| `charge_50` | WIP template | — | Human animator must block this pose |
| `charge_100` | WIP template | — | Human animator must block this pose |
| `hurt_heavy` | WIP template | — | Human animator must block this pose |
| `launch` | WIP template | — | Human animator must block this pose |
| `ko` | WIP template | — | Human animator must block this pose |
| `shield` | WIP template | — | Human animator must block this pose |
| `signature_silhouette` | WIP template | — | Human animator must block this pose |

## Silhouette rules

- Readable at 128px on Pixel 6a.
- Charge 0 / 50 / 100 must change volume, not just VFX.
- Hurt must read without HUD.
- Heavy / aura / super must not share the same contact silhouette.

## How to fill

1. Open `source/nix-calder_control_rig.blend` (when LFS source is present).
2. Pose deform or FK controls. Screenshot orthographic front + side.
3. Drop stills in this folder as `nix-calder_<slot>_front.png`.
4. Keep provenance `AUTHORED_WIP` until a human director signs the sheet.
