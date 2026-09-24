# Character Attachment Contract

Every non-body visible object is exactly one class.

| Class | Allowed use | Parenting / weighting | Validation |
|-------|-------------|-----------------------|------------|
| `SKINNED_COSTUME` | Body clothing, coats, torso shells | Weighted to deform bones. Never parent-only. | Must stay bound through stress actions. |
| `BONE_RIGID` | Helms, plates, gloves, boots, crystals | Parent to one deform bone. No world origin. | Rest-anchor distance ≤ 0.26 m under stress. |
| `SECONDARY_CHAIN` | Hair, cape, scarf, dangles | Root of chain on a deform bone. | Root must not separate. Chain ≤ 0.32 m extra slack. |
| `VFX_ORBIT` | Aura ornaments that orbit | Socket or `aura_root`. | Must be tagged VFX. May hide when VFX OFF. |
| `WORLD_STATIC` | Stage props only | World. | **Forbidden on fighters.** |

## Root attachment expectations

- Costume is never `WORLD_STATIC`.
- Rigid parts name their owning bone.
- Secondary chains name the first bone of the chain.
- Detached armor, unbound costume, floating extras fail the validator.

## Stress actions

`idle walk run dash heavy hurt charge super clash KO`

## Examples

- Rook pauldron → `BONE_RIGID` / `Shoulder_L`
- Kaia coat → `SKINNED_COSTUME` / `Chest`
- Vesper scarf → `SECONDARY_CHAIN` / `Chest`
- Ember aura tongues → `VFX_ORBIT` / `aura_root`
