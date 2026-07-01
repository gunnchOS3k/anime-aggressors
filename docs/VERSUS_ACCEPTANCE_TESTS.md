# Versus Acceptance Tests

## Path

Main Menu → Start Battle → Mode Select → Ruleset → Fighter Select → Stage Select → Versus → Countdown → Battle → KO → Results → Rematch / Fighter Select / Main Menu

## Controls

See `docs/TRAINING_DEBUG_SUPPORT.md` and in-game Controls menu for P1/P2 bindings.

| Phase | Expected |
|-------|----------|
| Countdown | Fighters cannot attack or move until FIGHT |
| Battle | Damage, stocks, aura HUD update |
| Pause | Esc toggles freeze; fighters stop sim |
| KO | Stock lost, respawn with i-frames if stocks remain |
| Match end | Results screen shows winner |
| Rematch | Battle restarts with same setup |
| Fighter select return | Setup flow restarts cleanly |
| Main menu return | No dead-end |

## Acceptance checklist

- [ ] Full menu path completes without console errors
- [ ] CPU opponent behaves differently at level 1 vs 4 within 30s
- [ ] Match ends when stocks depleted
- [ ] Results → rematch works
- [ ] Results → character select works
- [ ] Results → main menu works
- [ ] Debug shortcuts do not replace production path (F-keys optional)

## Automated gate

`npm run validate:full-scope-production` + `npm test`
