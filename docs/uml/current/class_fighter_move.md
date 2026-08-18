# Class — fighter / move (current)

```mermaid
classDiagram
  class AAFighter {
    +int slot
    +String fighter_id
    +bool is_cpu
    +float damage_percent
    +int stocks
    +float aura
    +start_attack(cmd)
    +is_aura_input_held()
  }
  class FighterStateMachine {
    +String current_state
    +enter(state)
    +update(delta)
    +can_attack()
  }
  class MoveRunner {
    +bool active
    +String phase
    +start_move(move, fighter)
    +tick_sim_frame()
  }
  class HitResolver {
    +resolve(attacker, defender, move)
  }
  class CpuController {
    +tick(delta)
  }
  AAFighter --> FighterStateMachine
  AAFighter --> MoveRunner
  AAFighter --> HitResolver
  AAFighter --> CpuController
```

Mapped to `scripts/fighters/fighter.gd` (`class_name AAFighter`), `fighter_state_machine.gd`, `scripts/combat/move_runner.gd`, `hit_resolver.gd`, `cpu_controller.gd`. Move JSON lives under `game-godot/data/moves/`.
