# Pixel 6a Wave014 Test Runbook

Wave014 validates procedural roster runtime on host CI. Physical Pixel 6a validation is **not** claimed (`PHYSICAL_PIXEL6A_VALIDATED=false`).

## Preconditions

- `make engineering-wave011`
- `make engineering-wave012`
- `make engineering-wave013b`
- Branch from accepted main SHA `2bebf3ce138aaaf6cc8d2b237a3d45aca3d11a80`

## Host harness

```bash
make engineering-wave014
```

## Optional physical device smoke (owner-only)

1. Export debug APK from `game-godot/`.
2. Install on Pixel 6a with USB debugging.
3. Launch TrainingBattleScene and verify procedural models render.
4. Record logcat + screenshots under `artifacts/pixel6a/` (do not commit secrets).

## Truth boundaries

- Models: `PROCEDURAL_PRODUCTION_PROXY`
- Animations: `PROCEDURAL_RUNTIME_ANIMATION`
- Final human art/animation: **false**
- Combat authority: Wave011 physics (`PHYSICS_AUTHORITATIVE`)
