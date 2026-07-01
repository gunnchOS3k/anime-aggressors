# Anime Aggressors

> Create your fighter. Pick your element. Launch your rivals.

Anime Aggressors is a 2.5D anime platform fighter where every fighter is built from two choices: **body size** and **element color**. Small fighters are quick but light. Large fighters hit hard but move slower. Medium fighters stay balanced. Your ROYGBIV color gives your combo a unique elemental feel.

## Architecture (split runtime)

Anime Aggressors now uses a **split architecture**:

| Layer | Stack | Role |
|-------|-------|------|
| Web shell | TypeScript + Vite | Menus, routing, GitHub Pages, career metadata |
| **Gameplay runtime** | **Godot 4 + GDScript** | Movement, combat, limb animation, camera, Derby |
| Legacy prototype | TypeScript `game-core` + Three.js | Fallback while Godot runtime matures |

- **[Play Godot Combat Prototype](https://gunnchos3k.github.io/anime-aggressors/#/godot)** — primary combat entry (`#/godot`)
- **Start Match (Legacy Web Prototype)** — original browser sim (`#/match-setup/rules`)

See [docs/ENGINE_DECISION_RECORD.md](docs/ENGINE_DECISION_RECORD.md) and [docs/GODOT_RUNTIME_INTEGRATION.md](docs/GODOT_RUNTIME_INTEGRATION.md).

## Production Rescue Strategy

Anime Aggressors is moving from prototype code generation to a **real production workflow**.

**Current architecture:**

| Layer | Role |
|-------|------|
| **TypeScript** | Web launcher / GitHub Pages shell |
| **Godot** | Public web gameplay runtime |
| **Blender** | Source assets, rigs, animations |
| **Unreal** | High-fidelity R&D track for anime combat, VFX, cinematics |

The project **no longer accepts debug placeholder fighters as final product**. Missing production GLB assets show **DEBUG FALLBACK — NOT PRODUCTION MODEL** and fail content gates.

See [docs/PRODUCT_RESCUE_PLAN.md](docs/PRODUCT_RESCUE_PLAN.md), [docs/ROADBLOCK_AUDIT.md](docs/ROADBLOCK_AUDIT.md), [docs/ENGINE_STRATEGY.md](docs/ENGINE_STRATEGY.md).

## Current Roadblock

The blocker is **not** just engine choice. The blocker is the **missing art / animation / VFX / choreography production pipeline** and the lack of acceptance gates that enforce shippable content.

Milestones **M0–M9** are defined in [docs/production/PRODUCT_MILESTONES.md](docs/production/PRODUCT_MILESTONES.md).


[Godot Prototype](https://gunnchos3k.github.io/anime-aggressors/#/godot) · [Legacy Start Match](https://gunnchos3k.github.io/anime-aggressors/#/match-setup/rules) · [Web Build Home](https://gunnchos3k.github.io/anime-aggressors/) · [PC Playtest Guide](docs/playtest/PC_PLAYTEST_GUIDE.md) · [Give Feedback](docs/playtest/feedback-form.md)

**Match setup link:** `https://gunnchos3k.github.io/anime-aggressors/#/match-setup/rules`  
**Quick play hash route:** `https://gunnchos3k.github.io/anime-aggressors/#/play`  
Do not use `https://gunnchos3k.github.io/play` — Anime Aggressors is hosted as a project site under `/anime-aggressors/`. See [docs/ROOT_PLAY_REDIRECT.md](docs/ROOT_PLAY_REDIRECT.md).

If the live site looks stale after a merge, check [deploy-info.txt](https://gunnchos3k.github.io/anime-aggressors/deploy-info.txt) — a failed Pages workflow leaves the previous deployment active until a new one succeeds.

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

## Flagline Clash

Flagline Clash is Anime Aggressors' team-vs-team territory mode. Teams fight over a Flag Core across a five-room battlefield. Win the center, push the frontline toward the enemy base, and capture the final room to win the whole game.

Map flow:

`Lunar Base ← Lunar Outpost ← Center Clash → Solar Outpost → Solar Base`

Solar pushes left. Lunar pushes right. Every room is still a platform-fighter battle — movement, knockback, stocks, elements, and created fighters all matter.

## Playable Modes

- **Play Godot Combat Prototype** — `#/godot` Godot 4 runtime (primary combat)
- **Start Match (Legacy Web Prototype)** — rules → map → fighters → controls → battle (TypeScript/Three.js)
- **Quick Play** — `#/play` legacy quick launch (defaults)
- **Custom Game** — stock / time / stamina rules, stages, ratios, items config
- **Create Fighter** — size + color builder with stat preview
- **Controls** — per-player input profiles with keyboard/gamepad remapping
- **Training Mode** — practice with hitbox overlay and frame step
- **Flagline Clash** — 2v2 team territory war with Flag Core capture
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

Friend-test flow: **Start Match → Rules → Map → Fighters → Controls → Battle** (or **Create Fighter → Custom Game → …**)

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

### Aura Charge

Aura Charge builds your elemental power meter. At Level 3, your fighter becomes **Super Ready**.

| Player | Keyboard | Gamepad |
|---|---|---|
| P1 | Hold **F** (or Shield + Special: C + X) | Hold **Select** (or Shield + Special) |
| P2 | Hold **/** (or Shield + Special: 3 + 2) | Hold **Select** (or Shield + Special) |

Aura Charge slows movement while charging and can be interrupted by heavy hits.

## Playtest With Friends (PC / Web)

1. Open the [web build](https://gunnchos3k.github.io/anime-aggressors/)
2. Click **Start Match** — pick rules, map, and fighters
3. Or click **Create Fighter** — pick size + ROYGBIV color, then **Custom Game**
4. Confirm **Controls** and **Start Battle**
5. Try **Impact Dummy Derby** or **Flagline Clash**
6. Send [feedback](docs/playtest/feedback-form.md)

See [PC Playtest Guide](docs/playtest/PC_PLAYTEST_GUIDE.md) for the full friend-testing path.

---

## Build Status / Ship Gates

| System | Gate |
|--------|------|
| Create Fighter + size/element modifiers | PLAYABLE |
| Start Match with created fighters | PLAYABLE |
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

### Godot Web export (required for Pages deploy)

The Godot combat prototype needs a real Web export — the checked-in placeholder is not playable.

```bash
# Install Godot 4.3+ or set GODOT_BIN=/path/to/godot
npm run godot:export:web
npm run build:pages
```

Export uses **single-threaded** Web mode for GitHub Pages (`variant/thread_support=false`). Threaded exports require COOP/COEP headers that Pages does not provide.

Live Godot URL: `https://gunnchos3k.github.io/anime-aggressors/godot/index.html`

Hash routes: `#/`, `#/godot`, `#/match-setup/rules`, `#/match-setup/stage`, `#/match-setup/fighters`, `#/match-setup/controls`, `#/battle`, `#/play`, `#/create-fighter`, `#/training`, `#/impact-dummy-derby`, `#/career`, `#/career/history`, `#/career/replays`, `#/career/saves`

## Career, Replays, and Saves

Anime Aggressors tracks local career stats for your fighters: playtime, KOs, falls, wins, damage, Flagline captures, and Impact Dummy Derby records. Match History stores recent scoreboards, Replay Vault lets you rewatch deterministic matches, and Saved Games lets you resume or inspect local game snapshots.

All career data is stored locally in your browser for now.

## Architecture

```
packages/game-core     — deterministic simulation + fighter creation
apps/web               — Create Fighter UI, match, derby, training
apps/web/renderer-three — read-only Three.js presentation
```

Three.js reads `GameState`; it never mutates gameplay truth.
