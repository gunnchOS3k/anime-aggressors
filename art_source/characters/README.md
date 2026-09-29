# Dual-form character presentations (V4)

Layout per fighter:

```
art_source/characters/<fighter>/
  DESIGN_SYNTHESIS.md
  PRESENTATION_MANIFEST.json
  shared/{skeleton,materials,sockets}/
  male/{source,export,portrait,select,battle,victory}/
  female/{source,export,portrait,select,battle,victory}/
```

Animation/action manifests remain canonical under `art_source/animation/fighters/<fighter>/`.
Body variants bind meshes to the shared animation set — do not double animation libraries.
Do not import stale #106 generated-art.
