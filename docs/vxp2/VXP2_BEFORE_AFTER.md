# VXP-2 Before / After

## Base

- Branch base: `origin/main` @ see gates JSON
- Text baselines: `artifacts/vxp2/before/`
- After captures: `artifacts/vxp2/after/` + `manifests/VXP2_SCREENSHOT_MANIFEST.json`

## Qualitative delta

| Area | Before | After |
|---|---|---|
| Main menu | Engineer 2-col button grid | Hero seal/wordmark + FIGHT primary |
| Theme | `placeholder/aa_theme.tres` | `ui/themes/aa_vxp2_theme.tres` (legacy kept) |
| Stage copy | artStatus / PROCEDURAL_FINAL leakage | Destination name + layout |
| Labs | Equal grid tile | Demoted "(dev)" row |
| Glyphs | Text-only footers | Confirm/Back/Fight glyph strip |

## Capture class

Desktop/headless fixture only. `VXP2_PIXEL_PHYSICAL_CAPTURE_PASS=false`.
