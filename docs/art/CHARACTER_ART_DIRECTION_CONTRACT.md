# Character Art Direction Contract (Wave021)

## Canonical flags

| Flag | Value |
|------|-------|
| `REALISTIC_HUMANOID_FACE_AS_DEFAULT` | **false** |
| `FACELESS_ABSTRACT_HEAD_DIRECTION` | **true** |

Runtime source: `game-godot/scripts/visual/art_direction_contract.gd`

## Head presentation

- **Faceless abstract cap** — smooth geometric or element-mask head volume.
- No photoreal eyes, nose, mouth, or skin pores as default.
- Expression reads through **posture, aura, element accent, silhouette** — not facial realism.
- Stylized fallback proxy may show expression chip only when canonical GLB is unavailable.

## Body presentation

- Readable **stylized humanoid** silhouette at all form tiers.
- Element identity via color, aura shape, material emission — not franchise mimicry.
- Ascended forms must **not** become giant bodies or Super-Saiyan parody silhouettes.

## Roster design language (all 7)

| Fighter | Element | Head read | Body read | Aura shape |
|---------|---------|-----------|-----------|------------|
| Ember Vale | Flame | Ember cap / heat mask | Rushdown striker, forward lean | Tongues |
| Rook Ironside | Iron | Plate helm void | Tank mass, planted stance | Rings |
| Juno Spark | Lightning | Arc crown | Quick electric frame | Arcs |
| Kaia Windrow | Wind | Ribbon veil | Aerial drift silhouette | Ribbons |
| Nix Calder | Frost | Crystal facet | Composed zoning frame | Crystals |
| Orion Vell | Gravity | Orbit halo | Cosmic authority stance | Orbit |
| Vesper Nyx | Shadow | Smoke cowl | Deceptive mix-up frame | Smoke |

## Architecture invariant (preserved from PR95)

```
IMMUTABLE CANONICAL ASSET → CONTEXT-LOCAL INSTANCE → CONTEXT-LOCAL CAMERA/MATERIAL/TRANSFORM
```

Form/ascension presentation changes are **context-local** and must not leak preview scale into battle.

## Owner approval

Human art approval **PENDING**. Engineering implements contract; Edmund/owner ratifies golden references separately.
