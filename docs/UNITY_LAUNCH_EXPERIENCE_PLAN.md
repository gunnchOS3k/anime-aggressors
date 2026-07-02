# Unity Launch Experience Plan

The game must launch like a real video game, not a raw dev scene. This doc
describes the scene flow that now exists in the Unity project and what is
real versus proxy.

**Status: exists locally, ready for Editor Play Mode testing. Not proven,
not complete, not shipped.**

---

## Scene flow

```text
Boot → Title → Main Menu → Mode Select → Character Select → Stage Select
     → Loading → Battle → (Pause) → Results → Rematch / Character Select / Main Menu
```

Training path:

```text
Main Menu → Training → Character Select → Stage Select → Loading → TrainingScene
```

Dev path (kept, not the default):

```text
Main Menu → DEV: COMBAT PROOF → CombatProof.unity
```

## How scenes are built

Scene files are intentionally minimal. `GameBootstrap`
(`Scripts/App/GameBootstrap.cs`) persists across scenes and builds the
correct controller for whichever scene loads, so any scene can be opened
directly in the editor and still function. `CombatProof` keeps its own
`CombatProofBootstrap` and is untouched as the dev proving ground.

| Scene | Controller | Content |
|-------|-----------|---------|
| BootScene | `BootScreenController` | splash, auto-advance |
| TitleScene | `TitleScreenController` | title logo text, press-any-key |
| MainMenuScene | `MainMenuController` | Versus / Training / Dev / Quit |
| ModeSelectScene | `ModeSelectController` | Versus vs Training cards |
| CharacterSelectScene | `CharacterSelectController` | 7 roster cards + preview |
| StageSelectScene | `StageSelectController` | 3 stage cards + preview |
| LoadingScene | `LoadingScreenController` | stage/fighter banner, async load |
| BattleScene | `BattleBootstrap` (versus) | stage + fighters + HUD + pause + results trigger |
| TrainingScene | `BattleBootstrap` (training) | stage + dummy + debug HUD + reset |
| ResultsScene | `ResultsScreenController` | winner, stats, rematch loop |

## Roster (7 fighters)

Only **Ember Vale** is fully playable (the proven CombatProof kit). The
other six are selectable cards clearly marked `PROXY — NOT FULLY PLAYABLE
YET`; picking them plays Ember's kit with their colors until their own kits
are built.

## Stages (3)

**Training Grid** is the playable proof stage. **Prototype Arena** and
**Skyline Rooftop** are proxy maps: they load into BattleScene with their
own layouts, spawns, camera framing, and colors.

## Battle rules (first pass)

- Damage % builds, knockback grows (existing HitResolver).
- KO at 150% damage or falling below the blast zone.
- 99-second timer; lower damage wins on time; equal damage is a draw.
- Esc pauses (versus). Training uses the debug HUD (F1/F2/F6/R).

## Order of proof

1. Unity Editor Play Mode (see `UNITY_EDITOR_TEST_PLAN.md`) — **first**
2. Local desktop build (see `UNITY_BUILD_AND_RUN_PLAN.md`) — second
3. WebGL (see `UNITY_WEBGL_LATER_PLAN.md`) — third, later
4. GitHub Pages — **last**, only after all of the above are proven

No step may claim the next step's result.
