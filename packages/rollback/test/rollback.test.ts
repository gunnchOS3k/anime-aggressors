import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  replay,
  hashState,
  type GameConfig,
  type InputFrame,
} from "@anime-aggressors/game-core";
import { RollbackSession } from "../src/index.js";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 99,
};

function input(frame: number, playerId: number, partial: Partial<InputFrame> = {}): InputFrame {
  return {
    frame,
    playerId,
    left: false,
    right: false,
    up: false,
    down: false,
    jump: false,
    attack: false,
    special: false,
    shield: false,
    dodge: false,
    grab: false,
    ...partial,
  };
}

describe("RollbackSession", () => {
  it("predicted input wrong triggers rollback and final hash matches authoritative replay", () => {
    const initial = createInitialGameState(config);
    const session = new RollbackSession(initial, {
      snapshotInterval: 1,
      maxRollbackFrames: 30,
      playerCount: 2,
    });

    const inputLog: InputFrame[][] = [];

    for (let f = 0; f < 20; f++) {
      const p0Attack = f === 10;
      const frameInputs = [
        input(f, 0, { attack: p0Attack }),
        input(f, 1, {}),
      ];
      inputLog.push(frameInputs);

      if (f === 10) {
        session.advanceFrame(
          [input(f, 0, { attack: false }), input(f, 1, {})],
          [false, true],
        );
        session.confirmInputs(f, frameInputs);
      } else {
        session.advanceFrame(frameInputs, [true, true]);
      }
    }

    assert.ok(session.getRollbackCount() >= 1);

    const replayResult = replay(initial, inputLog);
    const verified = session.verifyAgainstReplay(initial, inputLog);
    assert.equal(replayResult.finalHash, session.getStats().actualHash);
    assert.equal(verified, true);
  });

  it("exposes rollback count", () => {
    const initial = createInitialGameState(config);
    const session = new RollbackSession(initial, {
      snapshotInterval: 1,
      maxRollbackFrames: 10,
      playerCount: 2,
    });

    session.advanceFrame([input(0, 0), input(0, 1)], [true, true]);
    assert.equal(typeof session.getRollbackCount(), "number");
  });

  it("tracks desync when state diverges", () => {
    const initial = createInitialGameState(config);
    const session = new RollbackSession(initial, {
      snapshotInterval: 1,
      maxRollbackFrames: 5,
      playerCount: 2,
    });

    for (let f = 0; f < 5; f++) {
      session.advanceFrame([input(f, 0, { right: true }), input(f, 1, {})], [true, true]);
    }

    const wrongLog: InputFrame[][] = [[input(0, 0, { attack: true }), input(0, 1, {})]];
    const ok = session.verifyAgainstReplay(initial, wrongLog);
    assert.equal(ok, false);
    assert.equal(session.getStats().desyncDetected, true);
  });
});
