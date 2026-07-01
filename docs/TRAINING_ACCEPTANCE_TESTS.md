# Training Acceptance Tests

Run in Godot 4.2+ editor after `F5` from `game-godot/project.godot`.

## Path

Main Menu → Training → configure → Start Training Battle

## Controls (keyboard)

| Input | Action |
|-------|--------|
| Arrow / WASD (P1 bindings) | Move |
| J / mapped jump | Jump |
| K / mapped attack | Attack |
| L / mapped special | Special |
| Shift / mapped shield | Shield |
| Mapped grab | Grab |
| Mapped dodge | Dodge |
| Special + Shield hold | Aura charge |
| Attack at full aura | Aura burst |
| F1 | Toggle debug HUD |
| F2 | Toggle hitboxes |
| F6 | Toggle hurtboxes |
| F3 | Reset positions |
| F4 | Reset damage |
| F5 | Fill aura |
| F7 | Clear aura |
| F8 | Cycle dummy behavior |
| F9 | Pause/resume |
| F10 | Slow motion |
| Esc / B | Return to training menu |

## Acceptance checklist

- [ ] P1 fighter selectable from menu
- [ ] Dummy fighter selectable
- [ ] Stage selectable
- [ ] Dummy behavior: idle, shield, jump, attack, cpu
- [ ] Debug HUD shows live state changes
- [ ] Debug HUD shows move_id, frame, phase, hitbox active
- [ ] 10 in-range jabs register hits in log
- [ ] Out-of-range jabs miss (no damage increase)
- [ ] Shielded jab causes shield stun / block log, not launch
- [ ] Heavy launches farther than jab at same damage %
- [ ] High damage % launches farther than low
- [ ] Lighter dummy launches farther than heavier at same KB input
- [ ] KO when launched beyond blast zone (versus stage)
- [ ] Grab success → grab_hold → throw → damage + knockback
- [ ] Out-of-range grab whiffs (log shows whiff)
- [ ] Aura charge fills meter; burst consumes and hits
- [ ] Reset damage / position / aura tools work
- [ ] Return to training menu and main menu without crash

## Automated gate

`npm run validate:full-scope-production` verifies training scripts expose required controls.
