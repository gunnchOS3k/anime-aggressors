# State machine — combat (current)

Subset of `FighterStates` constants used in live battle.

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> walk
  idle --> jump_squat
  idle --> attack_startup
  idle --> special_startup
  idle --> shield_start
  idle --> dodge_start
  idle --> grab_startup
  attack_startup --> attack_active
  attack_active --> attack_recovery
  attack_recovery --> idle
  special_startup --> special_active
  special_active --> special_recovery
  special_recovery --> idle
  attack_active --> hurt_light: hit received
  hurt_light --> hitstun
  hitstun --> launched
  launched --> tumble
  tumble --> idle
  shield_start --> shield_hold
  shield_hold --> idle
  ko --> respawn
  respawn --> idle
```

Code: `scripts/fighters/fighter_states.gd`, transitions in `fighter_state_machine.gd` and `fighter.gd`.
