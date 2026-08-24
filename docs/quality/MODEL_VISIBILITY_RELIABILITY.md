# Model Visibility Reliability

**Rule:** `NAMEPLATE_VISIBLE_AND_MODEL_MISSING = failure` (T0).

## What runs without Pixel

| Check | Command / path | Evidence |
|-------|----------------|----------|
| Static contract | `python3 tools/quality/check_model_visibility_reliability.py` | Body hide-when-loaded, NameLabel, harness file present |
| Desktop BattleScene harness | From `game-godot/`: `$GODOT_BIN --headless -s res://tests/quality/TasteGateModelVisibility.gd` | Per-fighter nameplate vs model_loaded |
| Historical desktop E2E | `artifacts/engineering_wave014/BATTLESCENE_VISUAL_E2E.json` | Model loaded assertions (SHA-stale possible) |

## Pixel 6a + BattleScene campaign (required for device claim)

1. Install current APK on Pixel 6a.
2. Launch local versus with Ember (Golden Slice) and each roster fighter.
3. Capture frames where **nameplate and model** are both expected visible.
4. Fail the campaign if nameplate shows and model/proxy is missing.
5. Link screenshots into `artifacts/taste_gate/contact_sheet/manifest.json` with `source_kind: PIXEL6A_BATTLESCENE_MODEL_VIS`.
6. Set `PIXEL_MODEL_VISIBILITY_VALIDATED` only after Edmund accepts the pack.

**This gate PR does not invent that evidence.**
