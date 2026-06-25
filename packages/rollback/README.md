# @anime-aggressors/rollback

Local rollback harness for the deterministic `game-core` simulation.

## Capabilities

- Input history with confirmed vs predicted slots
- State snapshot ring buffer
- Rollback to a prior frame on misprediction
- Resimulation forward to current frame
- Rollback count and desync/hash mismatch reporting

## Usage

```ts
import { RollbackSession } from "@anime-aggressors/rollback";
import { createInitialGameState } from "@anime-aggressors/game-core";

const session = new RollbackSession(createInitialGameState(config), {
  snapshotInterval: 1,
  maxRollbackFrames: 60,
  playerCount: 2,
});
```

Online transport (UDP/WebRTC/etc.) can be added later by feeding confirmed remote inputs into `confirmInputs()`.

## Tests

```bash
npm run build
npm test
```
