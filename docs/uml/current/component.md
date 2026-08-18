# Component — current

```mermaid
flowchart TB
  BOOT[BootScene]
  MENU[MainMenu / ModeSelect / Versus]
  BATTLE[BattleScene]
  TRAIN[TrainingBattleScene]
  FIGHTER[AAFighter]
  SM[FighterStateMachine]
  MOVE[MoveRunner]
  HIT[HitResolver]
  AUDIO[AudioDirector]
  TOUCH[TouchInputManager]
  GS[GameState autoload]
  BOOT --> MENU
  MENU --> BATTLE
  MENU --> TRAIN
  BATTLE --> FIGHTER
  TRAIN --> FIGHTER
  FIGHTER --> SM
  FIGHTER --> MOVE
  FIGHTER --> HIT
  BATTLE --> AUDIO
  GS --> MENU
  GS --> BATTLE
  TOUCH --> FIGHTER
```

| Component | Path |
|---|---|
| Autoloads | `game-godot/project.godot` `[autoload]` |
| Scene router | `scripts/core/SceneRouter.gd` |
| Fighter | `scripts/fighters/fighter.gd` |
| Combat math | `scripts/combat/combat_math.gd` |
| Android export | `export_presets.cfg` preset Android, `scripts/export-godot-android.mjs` |
| Web shell (not combat) | `apps/web` |
