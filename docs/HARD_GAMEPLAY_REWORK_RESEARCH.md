# Hard Gameplay Rework — Research & Design Conclusions

## Platform-fighter combat is not hitbox detection alone

A readable hit requires a full consequence chain:

1. Anticipation / windup
2. Active strike
3. Hitstop (hitlag)
4. Hit spark and element VFX
5. Victim recoil
6. Knockback vector
7. Hitstun / tumble / launch
8. Camera impulse
9. Audio event
10. Combo / KO feedback

Without this chain, contact feels like overlapping rectangles — not a fighting game.

## Depth without command strings

Platform fighters (Smash, Rivals, Brawlhalla, Fantasy Strike) keep inputs simple while depth comes from:

- Movement and spacing
- Timing and aerial control
- Launch angle and damage percent
- Recovery and edge guarding
- Stage position
- Character-specific tools and aura/super identity

Anime Aggressors targets: **easy to control, hard to master, visually exciting**.

## Movement must feel genre-appropriate

Slow ground speed and weak air drift make matches feel like a tech demo. Fighters need:

- Fast run and dash
- Responsive jump and fast-fall
- Meaningful air drift
- Size-class identity (small = fastest, large = heavy but playable)

## Aura Charge as a real action

Holding Aura Charge fills the elemental meter. Level 3 unlocks Super Ready. Charge slows movement and can be interrupted by heavy hits. The meter must be **visible in HUD** and **documented in default controls**.

## Mode start discipline

Every mode that uses a fighter must require fighter selection before gameplay:

- Normal Match → rules → stage → fighters → controls → battle
- Impact Dummy Derby → **fighter select (same UI shell as match)** → ready → damage → bat launch → flight → results

Skipping fighter select breaks identity, boot validation, and results integrity.

## Anime Aggressors target for this pass

- Faster movement tuning with named constants and tests
- Fighting move phases tied to animation presentation
- Stronger hit response (hitlag, knockback, VFX, camera)
- Aura Charge on dedicated input (KeyF / Slash) plus Shield+Special combo
- Derby uses main Character Select UI with single-player copy
- Camera zoomed out further (`maxZoom` capped at 1.18)
