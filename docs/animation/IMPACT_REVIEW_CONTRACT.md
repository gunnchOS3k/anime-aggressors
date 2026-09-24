# Impact Review Contract

Review-only staging. **Never** modify gameplay collision or CombatMath.

## Staging

- Deterministic attacker / defender configuration
- Attacker contact socket → defender review anchor
- Frozen contact
- VFX OFF
- Camera shake OFF
- Render contact, hurt, follow-through

## Generic anchors

`HEAD CHEST TORSO_LEFT TORSO_RIGHT PELVIS UPPER_GUARD LOWER_GUARD`

## Rook / Nix golden still

Rook's heavy must look painful in a paused frame, and Nix must visibly look
hurt **before** launch begins.

Tool: `python3 tools/art_pipeline/human_art/impact_review.py`
