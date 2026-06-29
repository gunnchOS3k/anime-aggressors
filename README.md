# Anime Aggressors

> Create your fighter. Pick your element. Launch your rivals.

Anime Aggressors is a 2.5D anime platform fighter where every fighter is built from two choices: **body size** and **element color**. Small fighters are quick but light. Large fighters hit hard but move slower. Medium fighters stay balanced. Your ROYGBIV color gives your combo a unique elemental feel.

[Start Match](https://gunnchos3k.github.io/anime-aggressors/#/match-setup/rules) · [Web Build Home](https://gunnchos3k.github.io/anime-aggressors/) · [PC Playtest Guide](docs/playtest/PC_PLAYTEST_GUIDE.md) · [Give Feedback](docs/playtest/feedback-form.md)

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

- **Start Match** — rules → map → fighters → controls → battle setup flow
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

Hash routes: `#/`, `#/match-setup/rules`, `#/match-setup/stage`, `#/match-setup/fighters`, `#/match-setup/controls`, `#/battle`, `#/play`, `#/create-fighter`, `#/training`, `#/impact-dummy-derby`, `#/career`, `#/career/history`, `#/career/replays`, `#/career/saves`

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
