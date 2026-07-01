# Training & Debug Support

**Mode:** `game-godot/scenes/training/TrainingScene.tscn`  
**Status:** Full-scope required mode (not optional)

---

## Training features

| Feature | Implementation status |
|---------|----------------------|
| Selectable player fighter | Menu picker (scaffold) |
| Selectable dummy fighter | Menu picker (scaffold) |
| Dummy: idle | **Implemented** |
| Dummy: shield | **Implemented** |
| Dummy: jump | **Implemented** |
| Dummy: attack | **Implemented** |
| Dummy: CPU | **Implemented** |
| Hitbox/hurtbox overlay | **Implemented** (toggle) |
| Frame / state display | **Implemented** |
| Damage reset | **Implemented** |
| Position reset | **Implemented** |
| Aura reset/fill | **Implemented** |
| Move list overlay | **Implemented** (from move manifest) |
| Input display | **Implemented** |
| Combo counter | **Implemented** (basic) |
| Hit confirmation log | **Implemented** |

---

## Debug HUD (battle + training)

`scripts/debug/debug_hud.gd` shows:

- Current fighter state (from state machine)
- Damage %, stocks, aura
- Frame counter (battle time)
- PROXY / PLACEHOLDER art warning when applicable

---

## Shortcuts (debug only)

| Key | Action |
|-----|--------|
| F1 | Toggle debug HUD |
| F2 | Toggle hitbox overlay |
| F3 | Reset positions |
| F4 | Reset damage |
| F5 | Fill aura |

Labeled **DEBUG** in training footer — not shown on production versus path without debug flag.

---

## Manual test path

1. Main Menu → Training
2. Configure dummy behavior
3. Start — verify overlays and resets
4. Confirm hit log entries on successful hits
