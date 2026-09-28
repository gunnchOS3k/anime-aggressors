# Roster Rendering Language v1

Shared cel language for all seven fighters. Identity lives in body materials first.

## Shared contract
- Cel shader: `game-godot/shaders/fighter_toon.gdshader`
- Three toon bands, shared outline/rim, similar roughness proxy, bounded emission
- Mobile readability: compact silhouette, no photoreal faces
- Same VFX quality tier; particles never hide bodies
- Candidate KayKit geometry is kept; materials are remapped to elemental value groups

## Uniform ranges
| Property | Idle | Charge | Super |
|---|---|---|---|
| toon_bands | 3 | 3 | 3 |
| outline_width | 0.018 | 0.018 | 0.020 |
| rim_strength | 0.32 | 0.40–0.50 | 0.50 |
| aura_emission | 0.12 | up to 0.85 | 0.70–0.85 |

## Source of truth
Select tiles, Showcase preview, Labs review, and in-match spawn all derive from `game-godot/data/runtime/elemental_material_language.json`. Separate material instances are allowed only if they copy that identity.

Layers: A translucent body uniform, B structural detail, C controlled emissive accents, D rim/readability (preview slightly stronger).

## Per-fighter value groups
See `game-godot/data/runtime/elemental_material_language.json`.

| Fighter | Core | Structure | Accent |
|---|---|---|---|
| Ember | charcoal / molten | ember mid | hot yellow |
| Rook | dark iron/stone | muted metal | rust impact |
| Juno | navy/black-violet | charged panels | yellow + cyan |
| Kaia | dark teal | pale air | mint/white |
| Nix | dark cold | pale ice | cyan edge |
| Orion | near-black space | violet structure | starlight |
| Vesper | void core | plum cowl | pale phase |

## Charge is a body change
Charge must change core/structure/accent, not only add an aura overlay.

## VFX-off rule
If a hit only reads with particles on, it is not complete.
