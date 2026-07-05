# Directional Throws

Grab hold replaces the single generic throw with four directional throws.

## Throw IDs

- `throw_forward` — edge pressure / positioning
- `throw_back` — reversal / kill option
- `throw_up` — juggle / combo starter
- `throw_down` — setup / bounce / trap

## Direction Priority

During `GRAB_HOLD`, `ThrowResolver.read_throw_direction()` reads input:

1. Up
2. Down
3. Forward or back (relative to fighter facing)
4. Default forward

## Throw Config

Each throw move includes:

```json
"throw": {
  "direction": "forward",
  "hold_frames": 0,
  "release_frame": 0,
  "victim_offset": {"x": 0, "y": 0},
  "damage": 0,
  "angle_deg": 0,
  "base_knockback": 0,
  "knockback_growth": 0,
  "combo_role": ""
}
```

## Runtime Flow

1. Grab connects → `GRAB_HOLD`
2. Player holds direction + Attack/Grab → `execute_throw()`
3. `ThrowResolver.resolve_throw()` selects move by direction
4. `ThrowResolver.apply_victim_offset()` positions victim
5. `HitResolver.resolve()` applies damage and knockback

## Fighter-Specific Throws

Each fighter has unique throw names, angles, knockback, and combo roles defined in move manifests. See `FIGHTER_IDENTITY_MATRIX.md`.

## Training Debug

Debug HUD displays `throw_direction` during grab hold. F12 toggles grab range overlay.
