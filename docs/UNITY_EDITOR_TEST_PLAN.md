# Unity Editor Test Plan — Launch Experience

Test in the **Unity Editor first**. Desktop builds come second, WebGL third,
GitHub Pages last. A human must run this checklist in Play Mode; automated
file checks do not pass this gate.

**Editor:** Unity 6 LTS 6000.0.23f1
**Entry scene:** `Assets/AnimeAggressors/Scenes/BootScene.unity`

---

## Flow test (versus path)

- [ ] Open BootScene, press Play — splash appears, auto-advances to Title
- [ ] Title shows ANIME AGGRESSORS logo text and pulsing PRESS ANY KEY
- [ ] Any key → Main Menu with Versus / Training / Dev / Quit buttons
- [ ] VERSUS → Mode Select shows two mode cards
- [ ] SELECT VERSUS → Character Select shows all 7 roster cards
- [ ] Ember Vale card marked PLAYABLE; other six marked PROXY
- [ ] Clicking a card updates the preview panel (name, element, archetype, style, colors, status)
- [ ] CONFIRM → Stage Select shows 3 stage cards with mini layout previews
- [ ] Clicking a card updates the selected-stage label
- [ ] START BATTLE → Loading screen shows stage name, matchup, tip
- [ ] Battle loads: selected stage layout/colors, P1 in character colors, CPU dummy

## Battle test

- [ ] P1 moves/jumps/attacks with the CombatProof controls
- [ ] Battle HUD shows both damage percentages, updating on hit
- [ ] P1 aura and shield bars track K+L charge and L shield
- [ ] Timer counts down from 99
- [ ] Esc opens pause overlay; Resume, Character Select, Main Menu, Quit work
- [ ] Dealing 150% to the dummy (or knocking it off Skyline Rooftop) triggers K.O.
- [ ] Results screen shows headline, winner, damage stats, match time
- [ ] REMATCH loops back into battle via loading screen
- [ ] CHARACTER SELECT and MAIN MENU buttons return correctly

## Training path test

- [ ] Main Menu → TRAINING → Character Select → Stage Select → START TRAINING
- [ ] TrainingScene spawns fighter + dummy with the debug combat HUD
- [ ] F1/F2/F6 toggles and R reset work
- [ ] Falling off the stage auto-respawns
- [ ] EXIT button returns to Main Menu

## Dev scene test

- [ ] Main Menu → DEV: COMBAT PROOF still loads the original proof scene
- [ ] Opening CombatProof.unity directly still self-builds

## Console

- [ ] No errors in the console across the full flow

## Signoff

| Tester | Date | Unity version | Pass/Fail | Notes |
|--------|------|---------------|-----------|-------|
| | | | | |
