# Use case — current

Actors: local player, CPU opponent, Edmund (owner/QA). Wearable Edge-IO is out of the digital product path.

```mermaid
flowchart LR
  subgraph actors
    P[Local player]
    C[CPU opponent]
    O[Owner / QA]
  end
  subgraph godot [game-godot production]
    UC1[Boot and open main menu]
    UC2[Select mode / fighters / stage]
    UC3[Fight local 1v1]
    UC4[Train with dummy]
    UC5[Pause resume rematch]
    UC6[Use touch or gamepad]
  end
  P --> UC1
  P --> UC2
  P --> UC3
  C --> UC3
  P --> UC4
  P --> UC5
  P --> UC6
  O --> UC1
```

Code: `scripts/core/boot_scene.gd`, `scripts/menus/main_menu_scene.gd`, `scripts/battle/battle_scene.gd`, `scripts/training/training_menu_scene.gd`, `scripts/input/touch_controls_overlay.gd`.
