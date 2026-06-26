# Three.js renderer (`apps/web/src/renderer-three`)

Read-only presentation layer for Anime Aggressors. **Gameplay truth lives in `packages/game-core`.**

## Rules

- `GameState` → Three.js scene (allowed)
- Three.js transforms → gameplay (forbidden)

## Modules

| File | Role |
|------|------|
| `ThreeGameRenderer.ts` | Scene, WebGL renderer, frame loop hook |
| `CameraDirector.ts` | Orthographic side camera, zoom, shake |
| `CharacterView.ts` | Placeholder fighters + GLB hook |
| `StageView.ts` | Skyline Arena geometry + parallax |
| `HitboxDebugView` / `HurtboxDebugView` | Debug overlays from game-core boxes |
| `VfxSystem.ts` | Hit sparks, dust, KO flash (non-authoritative) |
| `RenderTypes.ts` | `RenderableGameState` mapping |
| `AssetLoader.ts` | GLB/glTF pipeline stubs |

## Coordinates

Game-core uses fixed-point (`FP_SCALE = 256`). Renderer converts with `fpToWorld(v) = v / 256`.

Players move on the X/Y plane; camera looks down the +Z axis.

## Asset pipeline (future)

```
Blender → GLB/glTF → GLTFLoader → CharacterView / StageView
```

Missing assets fall back to procedural placeholders — build must not depend on binary assets.

See [docs/RENDERER_THREE_CONTRACT.md](../../../docs/RENDERER_THREE_CONTRACT.md).
