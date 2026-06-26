# Anime Aggressors

> Create your fighter. Pick your element. Launch your rivals.

Anime Aggressors is a 2.5D anime platform fighter where every fighter is built from two choices: **body size** and **element color**. Small fighters are quick but light. Large fighters hit hard but move slower. Medium fighters stay balanced. Your ROYGBIV color gives your combo a unique elemental feel.

[Play the Web Build](https://gunnchOS3k.github.io/anime-aggressors/) · [PC Playtest Guide](docs/playtest/PC_PLAYTEST_GUIDE.md) · [Give Feedback](docs/playtest/feedback-form.md)

## Create-a-Fighter

Build a fighter in seconds:

| Choice | Options | Effect |
|--------|---------|--------|
| **Size** | Small / Medium / Large | Speed, power, weight, hurtbox |
| **Color** | ROYGBIV | Elemental combo flavor |

### Size classes

- **Small** — faster, lighter, flies farther when hit, weaker attacks
- **Medium** — balanced default
- **Large** — slower, heavier hits, harder to launch

### ROYGBIV elements

| Color | Element | Combo feel |
|-------|---------|------------|
| Red | Flame | Damage-over-time pressure |
| Orange | Impact | Heavier finisher / shield pressure |
| Yellow | Volt | Snappier hit confirm |
| Green | Gale | Pushback / spacing |
| Blue | Frost | Brief slow on hit |
| Indigo | Gravity | Inward pull for combos |
| Violet | Void | Tricky special displacement |

## Playable Modes

- **Play Match** — quick 2-player match (default stock rules)
- **Custom Game** — stock / time / stamina rules, stages, ratios, items config
- **Create Fighter** — size + color builder with stat preview
- **Controls** — per-player input profiles with keyboard/gamepad remapping
- **Training Mode** — practice with hitbox overlay and frame step
- **Impact Dummy Derby** — damage dummy, then Kinetic Bat launch for distance
- **Controller Test** — keyboard + gamepad + mapped action check
- **Rollback Debug** — deterministic state inspector
- **Edge-IO Lab** — wearable simulator
- **Prototype Lab** — older experiments (secondary)

## Custom Game & Rulesets

Save and select rulesets locally (no account required):

- Match type: stock, time, or stamina
- Stocks, timer, stamina HP, stage, hazards, items frequency
- Damage ratio and launch ratio
- Element effects: on, visual only, or off
- Created fighters allowed or defaults only

Friend-test flow: **Create Fighter → Custom Game → Fighters → Controls Check → Start Battle**

## Custom Controls

Anime Aggressors supports per-player input profiles. Keyboard, gamepad, and Edge-IO gestures can be mapped to game actions. Save a profile, assign it to a player, and use it in Play Match, Training Mode, and Impact Dummy Derby.

## Controls (defaults)

| Action | Keyboard P1 | Keyboard P2 | Gamepad |
|---|---|---|---|
| Move | Arrows | WASD | Left stick / D-pad |
| Jump | Space / Up | W | Bottom face button |
| Attack | Z | 1 | Left face button |
| Special | X | 2 | Right face button |
| Shield | C | 3 | Shoulder |
| Dodge | V | 4 | Trigger |
| Grab / Extra | B | 5 | Top face button |

## Playtest With Friends (PC / Web)

1. Open the [web build](https://gunnchOS3k.github.io/anime-aggressors/)
2. Click **Create Fighter** — pick size + ROYGBIV color
3. Click **Custom Game** — set stocks, timer, stage, and ratios
4. Choose fighters and confirm **Controls**
5. **Start Battle** or try **Impact Dummy Derby**
6. Send [feedback](docs/playtest/feedback-form.md)

See [PC Playtest Guide](docs/playtest/PC_PLAYTEST_GUIDE.md) for the full friend-testing path.

---

## Build Status / Ship Gates

| System | Gate |
|--------|------|
| Create Fighter + size/element modifiers | PLAYABLE |
| Play Match with created fighters | PLAYABLE |
| Impact Dummy Derby with created fighter | PLAYABLE |
| Three.js 2.5D match | PLAYABLE |
| Deterministic game-core | PROVEN BY TEST |
| GLB character assets | SHIP BLOCKED |
| Public online relay | SHIP BLOCKED |

## Developer Quick Start

```bash
npm ci
npm run dev
npm run quality
```

Hash routes: `#/`, `#/create-fighter`, `#/play`, `#/training`, `#/impact-dummy-derby`

## Architecture

```
packages/game-core     — deterministic simulation + fighter creation
apps/web               — Create Fighter UI, match, derby, training
apps/web/renderer-three — read-only Three.js presentation
```

Three.js reads `GameState`; it never mutates gameplay truth.
