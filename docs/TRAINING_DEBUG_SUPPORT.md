# Training & Debug Support

**Mode:** `game-godot/scenes/training/`  
**Status:** Implemented — reachable from Main Menu → Training

---

## Training features

| Feature | Implementation status |
|---------|----------------------|
| Selectable player fighter | **Implemented** — menu picker |
| Selectable dummy fighter | **Implemented** — menu picker |
| Stage select | **Implemented** — menu picker |
| CPU level (dummy=cpu) | **Implemented** — levels 1–4 |
| Dummy: idle | **Implemented** |
| Dummy: shield | **Implemented** |
| Dummy: jump | **Implemented** |
| Dummy: attack | **Implemented** |
| Dummy: CPU | **Implemented** — tiered `CpuController` |
| Hitbox/hurtbox overlay | **Implemented** — F2 / F6 |
| State / move / frame display | **Implemented** — debug HUD |
| Damage reset | **Implemented** — F4 |
| Position reset | **Implemented** — F3 |
| Aura fill/clear | **Implemented** — F5 / F7 |
| Input display | **Implemented** |
| Combo counter | **Implemented** |
| Hit confirmation log | **Implemented** |
| Pause / slow-mo | **Implemented** — F9 / F10 |

---

## Debug HUD (battle + training)

`scripts/debug/debug_hud.gd` shows:

- Current fighter state
- Move id, frame, phase, hitbox active, cancel window
- Damage %, stocks, aura
- Input display
- Hit log
- `PROXY — NOT FINAL ART` label for proxy fighters

---

## Shortcuts

| Key | Action |
|-----|--------|
| F1 | Toggle debug HUD |
| F2 | Toggle hitbox overlay |
| F6 | Toggle hurtbox overlay |
| F3 | Reset positions |
| F4 | Reset damage |
| F5 | Fill aura |
| F7 | Clear aura |
| F8 | Cycle dummy behavior |
| F9 | Pause/resume |
| F10 | Slow motion |

On-screen help shown in training battle HUD label.

---

## Manual test path

See `docs/TRAINING_ACCEPTANCE_TESTS.md`.
