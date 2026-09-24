# Socket contract

Required empties, named exactly:

| Socket | Parent bone |
|--------|-------------|
| `hand_l` | `Hand_L` |
| `hand_r` | `Hand_R` |
| `foot_l` | `Foot_L` |
| `foot_r` | `Foot_R` |
| `chest` | `Chest` |
| `head` | `Head` |
| `back` | `Chest` |
| `projectile_origin` | `Hand_R` |
| `aura_root` | `Hips` |

These names are gameplay/VFX anchors. Renaming them breaks the resolver.
