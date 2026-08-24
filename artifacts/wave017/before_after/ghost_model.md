# Wave017 Before / After — Ghost model / visibility

## Before (owner Pixel / pre-Wave017)

- Risk of nameplate-only or empty SubViewport presentation across KO/respawn/ladder/bg-fg.
- Visibility heal limited to ColorRect fallback; no periodic invariant.

## After (Wave017)

- Runtime invariant: `FIGHTER_LOGIC_ACTIVE && FIGHTER_EXPECTED_VISIBLE -> VISIBLE_RENDERABLE_FIGHTER_BODY_REQUIRED`
- `ensure_visible_presentation()` + `heal_visibility_if_needed()` + 250ms watchdog
- Desktop lifecycle harness: `artifacts/wave017/GHOST_LIFECYCLE_HARNESS.json` → `DESKTOP_GHOST_OCCURRENCES=0` (55 transitions)
- Taste debt `TASTE-T0-MODEL-VISIBILITY-001` CLOSED with harness evidence (owner must still confirm on Pixel)

## Pixel

- Device-dependent campaign: see `artifacts/wave017/PIXEL_CAMPAIGN.json` (may be `BLOCKED_PIXEL6A` if unauthorized).
