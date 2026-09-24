# Elemental VFX Language v1

Hierarchy (must stay in this order):

`body pose → contact point → defender reaction → primary elemental effect → secondary trail → particles → camera → HUD`

If particles hide bodies, reduce particles. Runtime budgets are in `ElementalVfxFamily`.

## Families
| Fighter | Primary | Secondary | Hit accent | Charge | Clash |
|---|---|---|---|---|---|
| Ember | flame tongues | heat trail / embers | warm edge flash | core brighten | furnace pressure |
| Rook | impact ring | dust burst | compression | mass settle | impact shock |
| Juno | jagged arc | short afterimage | branch snap | current flicker | unstable current |
| Kaia | wind ribbon | crescent stream | pressure curve | lifted scarf | crosswind |
| Nix | crystal lance | frost mist | rigid lock | facet growth | frost lattice |
| Orion | constellation nodes | orbit ring | inward then out | orbit tighten | gravity warp |
| Vesper | void seam | ghost offset | phase smear | partial phase | phase tear |

Hit accents are visual-only unless gameplay already defines a status.

New VFX/audio in this pass is original/procedural. KayKit candidate meshes remain documented CC0; they are not shipping-approved art.
