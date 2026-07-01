# Unity Spike Acceptance Checklist

**Scene:** `unity/AnimeAggressorsUnity/Assets/AnimeAggressors/Scenes/CombatProof.unity`  
**Human signoff required** — automated repo checks do not pass this gate.

---

## Play Mode setup

- [ ] Unity 6 LTS project opens without compile errors
- [ ] Press Play — platform, P1, dummy, HUD appear
- [ ] No console errors on start

---

## Movement

- [ ] P1 moves (A/D)
- [ ] P1 jumps (W)
- [ ] P1 lands on platform

---

## Combat

- [ ] Jab hitbox appears only during active frames (F2)
- [ ] Jab hits dummy in range — dummy damage % increases
- [ ] Jab misses out of range — no damage increase
- [ ] Dummy enters hitstun on hit
- [ ] Heavy (H) launches farther than jab
- [ ] Debug HUD shows state, move, frame, phase, last hit

---

## Shield

- [ ] Shield hold (L) blocks jab — SHIELD result / no launch
- [ ] Shield health decreases
- [ ] Shield stun recovers

---

## Grab / throw

- [ ] Grab (U) succeeds in range — GRAB in HUD
- [ ] Grab whiffs out of range
- [ ] Throw damages and launches dummy

---

## Aura

- [ ] K+L charges meter — HUD aura increases
- [ ] Aura ready at 100%
- [ ] J at full aura — burst consumes meter, affects dummy

---

## Tools

- [ ] R reset works
- [ ] F2 / F6 toggle hitbox/hurtbox visuals

---

## Signoff

| Tester | Date | Unity version | Pass/Fail | Notes |
|--------|------|---------------|-----------|-------|
| | | | | |

**Proof gate passed:** only when all combat rows checked Pass.
