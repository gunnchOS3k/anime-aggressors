# Generated Art v6 — Graphic Combat Style Lock

This is the generated-art style for the current release.

Later internal/external artists may replace all visible art while preserving
the runtime contract (skeleton IDs, sockets, action IDs, CombatMath).

Generated production art only. Not human-authored final art.

## Chosen direction

**Graphic faceless combat figures**

stylized low-poly geometry + strong costume silhouettes + hard color blocking
+ cel shading + bold masks/helmets + exaggerated combat posing + element VFX

The lofted v5 body remains the deformation understructure. It is not the
visible hero design.

## Rules

1. **No exposed mannequin body read.**
2. **Every fighter wears a full-body undersuit/base costume.**
3. **Skin-like peach/clay body material is forbidden as the dominant body read.**
4. **Hands are stylized gloves/gauntlets, not attempts at realistic bare hands.**
5. **Feet are integrated boots, not exposed feet.**
6. **Heads are helmets/masks/cowls/facets, not pseudo-human heads.**
7. **Facets are intentional and supported by cel shading.**
8. **Large shape language beats micro-detail.**
9. **Silhouette and palette must identify the fighter before VFX.**
10. **VFX amplifies identity; it does not create identity from nothing.**
11. **Combat posing is exaggerated and graphic.**
12. **Later human art may replace all visible art without changing gameplay contracts.**

## Coverage target

`VISIBLE_UNDERSUIT_OR_COSTUME_COVERAGE >= 90%` for torso/limbs in front/3Q views.

## Glove families

```text
POWER_GAUNTLET   Ember, Rook
SPEED_GLOVE      Juno
AERIAL_GLOVE     Kaia
PRECISION_GLOVE  Nix
GRAVITY_GLOVE    Orion
VOID_GLOVE       Vesper
```

Required form: palm block, thumb wedge, grouped-finger silhouette, knuckle
ridge, cuff. No L-shape. No mitten nub.

## Boot families

Sole + toe wedge + heel + ankle cuff + shin overlap. Plant must be obvious.

## Head families

Faceless combat mask / helmet / cowl. No generic sphere/box/cone as the
dominant read.

## Materials

2–3 discrete cel bands, controlled shadow color, rim, armor vs cloth, bounded
emission, outline/rim support. No photoreal PBR as the hero look.

## Triangle budget

8k–25k triangles per fighter. Up to ~35k if Pixel stays stable.
No return to voxel remesh.

## Human gates

`HUMAN_*`, `MERGE_AUTHORIZED`, and `FINAL_AUTHORED_ANIMATION_PASS` stay false
until a human actually approves.
