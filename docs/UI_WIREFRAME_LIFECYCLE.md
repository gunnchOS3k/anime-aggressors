# UI Wireframe Lifecycle — Anime Aggressors

## Process overview

### 1. Player fantasy statement

> "I am about to play an anime platform fighter — create my fighter, charge my aura, launch my rivals."

Every wireframe decision is checked against this sentence.

### 2. First 5 seconds test

Within five seconds on the home screen, a new player should see:

- Game title
- Animated arena / fighters
- One obvious **Start Match** button
- Hint of elemental energy (aura particles)

They should **not** need to read a paragraph or compare twelve equal buttons.

### 3. Information architecture

| Tier | Items |
|------|--------|
| Primary | Start Match |
| Secondary | Custom Game, Flagline Clash, Impact Dummy Derby, Training Mode, Create Fighter |
| Player / Meta | Career, Controls, Replay Vault, Saved Games |
| Labs / Debug | Controller Test, Rollback Debug, Edge-IO Lab, Prototype Lab, Feedback |

### 4. Low-fidelity wireframe

```
[Title top-left]                    [Player panel right]
[Subtitle]

        [ 3D arena + fighters ]

              [ START MATCH ]

    [ mode carousel: secondary modes ]

[Labs footer — small]              [Build info]
```

### 5. Motion wireframe

- Start Match: subtle pulse
- Focused item: glow ring
- Carousel: horizontal slide on focus change
- Fighters: idle bob / arm sway
- Aura: looping particles
- Stage: slow light sweep
- Route change: fade transition on overlay

### 6. Controller navigation prototype

- Arrow / WASD: move focus between focusable items
- Enter / Space / Gamepad A: confirm
- Escape / Gamepad B: back (when applicable)
- Focus order: Start Match → carousel → player panel → labs

### 7. Visual identity pass

Large display title, elemental glow accents, dark arena backdrop, readable contrast, ROYGBIV particle colors tied to showcased fighters.

### 8. Usability pass

Verify: new player reaches `#/match-setup/rules` in two interactions (focus + confirm or click).

### 9. Accessibility pass

Visible focus ring, keyboard operability, reduced reliance on color alone (labels + icons), no autoplay strobe.

### 10. Build integration

Home screen mounts via `HomeScreen.ts`, scene via `MainMenuSceneRenderer.ts`, routes unchanged hash paths.

### 11. Playtest feedback

Collect: "Does this feel like a game menu?" and "Can you find Training without hunting?"

### 12. Final polish

Tune pulse timing, particle density, footer opacity, mobile stacking.

---

## Anime Aggressors-specific lifecycle

| Phase | Description |
|-------|-------------|
| **Current (before)** | Functional web-app menu — title, sections, many equal buttons |
| **Next (this pass)** | Game-like animated Elemental Arena Hub |
| **Later** | Full cinematic title flow, announcer stinger, mode-specific backdrop swaps |
| **Future** | Online lobby, seasonal events, character showcase rotation |

---

## Wireframe artifacts in repo

- Creative direction: `docs/UI_CREATIVE_DIRECTION_STUDY.md`
- Menu implementation: `apps/web/src/screens/HomeScreen.ts`
- Scene renderer: `apps/web/src/renderer-three/menu/MainMenuSceneRenderer.ts`
- Navigation: `apps/web/src/input/menuNavigation.ts`
- Hierarchy config: `apps/web/src/ui/mainMenuConfig.ts`
