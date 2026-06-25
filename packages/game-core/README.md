# @anime-aggressors/game-core

Deterministic platform-fighter simulation for Anime Aggressors.

## Scope (v0.1)

- Fixed **60 Hz** simulation tick
- **2 players**, **1 stage** (Skyline Arena), **2 original characters** (Ember Vale, Tide Kuro)
- Integer fixed-point physics (`FP_SCALE = 256`)
- Movement, jump, double jump, attack, special, shield, dodge
- Hitbox/hurtbox collision, damage percent, knockback, hitstun
- Blast zones, stocks, match timer, results phase
- Deterministic serialize / hash / replay

## API

```ts
import {
  createInitialGameState,
  simulateFrame,
  hashState,
  replay,
  type InputFrame,
} from "@anime-aggressors/game-core";
```

Rollback and rendering layers consume **only** `InputFrame[]` per tick — never raw DOM, gamepad, or BLE events.

## Tests

```bash
npm run build
npm test
```

## Non-goals (this package)

- DOM / canvas / audio
- Networking
- BLE / Edge-IO
