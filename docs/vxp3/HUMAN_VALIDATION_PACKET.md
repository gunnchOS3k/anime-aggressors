# VXP-3 Human Validation Packet

Status: **NOT RUN**

Do not mark visual / combat-feel / fun PASS from this PR.

## Required later (owner)

1. Nix jab vs Rook at 0% reads as a light crystalline chip, not a shared flinch.
2. Rook heavy vs Nix at 80%+ has stiffness then a readable launch (Nix) and a body-snap then launch (Rook as victim of impact).
3. Attacker and defender freeze together on contact (hitstop sync).
4. Light hits do not shake the camera; heavy/aura/KO may, unless reduce-motion is on.
5. Training: freeze, step, replay last hit, force tier, set percent, set aura, cycle reaction, toggle cam/VFX/SFX, hide HUD.
6. Hide-HUD clip is watchable enough to consider a later capture pass.
7. Reduce flash / reduce shake still playable.

## Gates that stay false

- `VXP3_HUMAN_VISUAL_VALIDATION_PASS=false`
- `VXP3_HUMAN_COMBAT_FEEL_PASS=false`
- `VXP3_HUMAN_FUN_PASS=false`
- `VXP3_MERGE_AUTHORIZED=false`

## Pixel

Only authentic app-only 60fps captures on an authorized Pixel may set `VXP3_PIXEL_CAPTURE_PASS=true`. Otherwise false.
