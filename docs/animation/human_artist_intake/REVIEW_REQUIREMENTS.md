# Review requirements

Cameras: `FRONT FRONT_3Q SIDE BACK GAMEPLAY SELECT_PREVIEW HEAD_DETAIL HAND_DETAIL BOOT_DETAIL COSTUME_DETAIL HEAVY_PAIR CLASH_PAIR`

FRONT must face the front marker. A rear-facing “front” is a fail.

Packet: front, 3Q, side/back, gameplay scale, silhouette, attachment stress, contact frames.
Rook/Nix also need impact pair, VFX OFF, contact freeze, hurt before knockback.

Evidence classes:

- Structural visibility (nodes exist, skeleton present)
- Rendered-pixel visibility (only when a real GPU/display path exists)

CI labels the mode. Headless dummy must not call `texture_2d_get`.
