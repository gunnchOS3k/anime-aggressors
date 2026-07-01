# Godot Editor Playtest Signoff

Complete this checklist in Godot 4.2+ with `game-godot/project.godot`.  
Save a filled copy to `docs/manual-playtests/YYYY-MM-DD-<tester>.md` using `MANUAL_PLAYTEST_SIGNOFF_TEMPLATE.md`.

**Status:** ☐ Unsigned (P1 blocker until completed)

---

## Environment

- [ ] Project opens in Godot 4.2+
- [ ] F5 launches BootScene
- [ ] Main Menu appears
- [ ] No Godot console errors on boot

---

## Training checklist

- [ ] Training menu opens from Main Menu
- [ ] P1 and dummy spawn in Training Battle
- [ ] P1 moves (WASD / mapped keys)
- [ ] P1 jumps
- [ ] Jab hits in range (damage % increases)
- [ ] Jab misses out of range (no damage increase)
- [ ] Heavy launches farther than jab
- [ ] Shield blocks jab
- [ ] Shield stun recovers
- [ ] Hurt light recovers (fighter moves again)
- [ ] Hurt heavy recovers
- [ ] Grab succeeds in range
- [ ] Grab whiffs out of range
- [ ] Throw applies damage and knockback
- [ ] Aura charge fills meter (special + shield)
- [ ] Aura burst consumes meter
- [ ] F2 toggles hitboxes
- [ ] F6 toggles hurtboxes
- [ ] F3 resets position
- [ ] F4 resets damage
- [ ] F5 fills aura
- [ ] F7 clears aura
- [ ] F8 cycles dummy behavior
- [ ] F9 pauses
- [ ] F10 slow motion toggles
- [ ] No Godot console errors during training session

---

## Versus checklist

- [ ] Start Battle works
- [ ] Mode Select works
- [ ] Ruleset works
- [ ] Fighter Select works
- [ ] Stage Select works
- [ ] Versus screen works
- [ ] Countdown locks input
- [ ] Battle starts after FIGHT
- [ ] P1 controls work
- [ ] P2 human controls work (arrows + N/M/,/.)
- [ ] CPU controls work
- [ ] KO decreases stock
- [ ] Respawn grants temporary invulnerability
- [ ] Match ends at zero stocks
- [ ] Results screen shows winner
- [ ] Rematch works
- [ ] Return to Fighter Select works
- [ ] Return to Main Menu works
- [ ] No Godot console errors during versus session

---

## Signoff

| Field | Value |
|-------|-------|
| Tester | |
| Date | |
| Godot version | |
| OS | |
| Commit SHA | |
| Training result | Pass / Fail |
| Versus result | Pass / Fail |
| Evidence attached | Yes / No |
