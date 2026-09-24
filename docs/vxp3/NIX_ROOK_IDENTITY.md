# Nix Calder vs Rook Ironside — Phase 1 Identity

Not franchise copies. Not final art. Godot-authored pose-to-pose.

## Nix Calder (frost / control)

- **Idle:** still chest, almost no foot travel.
- **Walk/run:** precise, short stride.
- **Attack:** crystalline held contact, ice-fragment event on impact frames.
- **Hurt:** brief stiffness (`hurt_freeze_stiffness`) before launch.
- **Launch/tumble:** body stays “frozen” for the first keys, then breaks.
- **SFX:** owned frost palette (high crystalline tones).

## Rook Ironside (impact / armor)

- **Idle/walk:** planted stance, heavy foot keys.
- **Attack:** enormous follow-through; contact pose overshoots.
- **Hurt:** torso whip (`hurt_body_snap`) then launch.
- **Launch:** ground-dust + ring-shockwave events (owned placeholders).
- **SFX:** owned impact palette (low thud).

## Shared stack

Both fighters have the full 12-family hurt library and 6 contact-pose clips. Signatures are hashed and must differ clip-for-clip.
