# Three.js renderer contract

## Authority

| Layer | Owns |
|-------|------|
| `packages/game-core` | position, velocity, hitboxes, hurtboxes, knockback, stocks, timer, hitstun, KO, match phase |
| `packages/rollback` | input history, snapshots, prediction, rollback, replay, desync detection |
| `apps/web/src/renderer-three` | meshes, materials, camera, VFX, animation poses |

The renderer **reads** `GameState` each frame. It never writes back to simulation state.

## Data flow

```
Input → RollbackSession → simulateFrame → GameState
                                              ↓
                                    ThreeGameRenderer.update()
                                              ↓
                                    WebGL draw (non-authoritative)
```

## Coordinate conversion

- Game-core units: fixed-point integers (`FP_SCALE = 256`)
- Three.js world units: `fpToWorld(n) = n / 256`
- Gameplay plane: X horizontal, Y vertical, Z depth for parallax only

## Player → animation mapping

| `actionState` | Visual |
|---------------|--------|
| `idle` / `running` | upright capsule |
| `jumping` / `falling` | squash/stretch |
| `attacking` / `special` | body tilt |
| `shielding` | bubble |
| `hitstun` | red flash |
| `defeated` | hidden (KO) |

## Hitbox / hurtbox visualization

- Source: `getActiveHitboxesForState`, `getHurtboxes` from game-core
- Hitboxes: warm/red transparent boxes
- Hurtboxes: cool/blue transparent boxes
- Toggle: F2 in match / training mode
- **Never used for collision**

## VFX events (visual only)

| Event | Trigger |
|-------|---------|
| Hit spark | damage increased |
| Shield spark | entered shielding |
| Jump / land dust | ground transition |
| Dodge afterimage | entered dodging |
| KO flash | stock lost |
| Camera shake | hitstop / KO |

## Camera

- `THREE.OrthographicCamera`, side view
- Dynamic zoom from alive player bounds
- Stage-aware clamp via padding
- Smooth interpolation (disable via `smoothCamera: false`)
- Hitstop/KO punch zoom via `CameraDirector`

## Performance expectations

- Target: 60 FPS presentation on mid-range laptop
- One draw call per placeholder character; batch when GLB assets arrive
- Debug boxes recreated each frame when enabled (dev only)

## Asset pipeline

```
Blender → export GLB → public/assets → AssetLoader.loadGlb()
```

Manifest: `AssetLoader.DEFAULT_MANIFEST`. Missing files use placeholders.

## Tests

- Pure mapping: `apps/web/test/renderMapping.test.ts`
- Collision helpers: `packages/game-core/test/collisionHelpers.test.ts`
- No WebGL in CI
