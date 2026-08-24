# Before / After — Move clip mapping

## Before
- `forward_tilt` gameplay move played generic `jab_1` / jab fallback because `RuntimeMoveResolver` only recognized a few move_ids and collapsed attack states to jab.
- Aerials similarly collapsed; tilt_* clips existed but were marked DESIGN_ONLY.

## After
- Canonical alias map: `forward_tilt` → `tilt_forward`, aerials → `aerial_*`, jab chain → `jab` / `jab_chain_2` / `jab_chain_3`.
- Golden Slice E2E asserts exact clips for Ember tilts/aerials.

See `content/runtime/move_clip_alias_map.json` and `GOLDEN_SLICE_MOVE_APPLICATION_E2E.json`.
